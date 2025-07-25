import 'dart:async' as async_dart;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'letter_physics.dart';
import 'background_effects.dart';
import 'animated_app_bar.dart';
import 'control_panel.dart';
import 'particle_effects.dart';
import 'performance_manager.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Letter Drop Animation',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A12),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A12),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF00F3FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Color(0xFF00F3FF), blurRadius: 10)],
          ),
        ),
      ),
      home: const LetterDropPage(),
    );
  }
}

class LetterDropPage extends StatefulWidget {
  const LetterDropPage({super.key});

  @override
  State<LetterDropPage> createState() => _LetterDropPageState();
}

class _LetterDropPageState extends State<LetterDropPage> {
  late GameWorld _gameWorld;
  bool _isPlaying = true;
  double _dropSpeed = 1.0;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _gameWorld = GameWorld();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _gameWorld.resumeEngine();
      } else {
        _gameWorld.pauseEngine();
      }
    });
  }

  void _clearLetters() {
    _gameWorld.clearAllLetters();
  }

  void _showSettings() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SettingsDialog(
        currentSpeed: _dropSpeed,
        soundEnabled: _soundEnabled,
        onSpeedChanged: (speed) {
          setState(() {
            _dropSpeed = speed;
            _gameWorld.setDropSpeed(speed);
          });
        },
        onSoundToggled: (enabled) {
          setState(() {
            _soundEnabled = enabled;
            _gameWorld.setSoundEnabled(enabled);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AnimatedAppBar(title: 'Letter Drop Animation'),
      body: Column(
        children: [
          Expanded(
            child: LetterDropWorld(
              gameWorld: _gameWorld,
              dropSpeed: _dropSpeed,
              soundEnabled: _soundEnabled,
            ),
          ),
          ControlPanel(
            isPlaying: _isPlaying,
            onPlayPause: _togglePlayPause,
            onClear: _clearLetters,
            onSettings: _showSettings,
          ),
        ],
      ),
    );
  }
}

class LetterDropWorld extends StatefulWidget {
  final GameWorld gameWorld;
  final double dropSpeed;
  final bool soundEnabled;
  
  const LetterDropWorld({
    super.key,
    required this.gameWorld,
    required this.dropSpeed,
    required this.soundEnabled,
  });

  @override
  State<LetterDropWorld> createState() => _LetterDropWorldState();
}

class _LetterDropWorldState extends State<LetterDropWorld> {
  async_dart.Timer? _letterGenerationTimer;

  @override
  void initState() {
    super.initState();
    _startLetterGeneration();
  }

  @override
  void dispose() {
    _letterGenerationTimer?.cancel();
    super.dispose();
  }

  void _startLetterGeneration() {
    _letterGenerationTimer = async_dart.Timer.periodic(
      Duration(milliseconds: (500 / widget.dropSpeed).round()),
      (timer) {
        if (mounted && widget.gameWorld.isEngineRunning) {
          final letter = LetterGenerator.generateLetter(widget.gameWorld.size.x);
          widget.gameWorld.add(letter);
        }
      },
    );
  }

  @override
  void didUpdateWidget(LetterDropWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dropSpeed != widget.dropSpeed) {
      _letterGenerationTimer?.cancel();
      _startLetterGeneration();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A12),
      child: GestureDetector(
        onTapDown: (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          widget.gameWorld.handleTap(Vector2(localPosition.dx, localPosition.dy));
        },
        child: GameWidget(game: widget.gameWorld),
      ),
    );
  }
}

class GameWorld extends Forge2DGame {
  static const double worldScale = 10.0;
  late BackgroundEffect backgroundEffect;
  bool isEngineRunning = true;
  double dropSpeed = 1.0;
  bool soundEnabled = true;
  late PerformanceManager _performanceManager;

  GameWorld() : super(gravity: Vector2(0, 98.1), zoom: worldScale);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 初始化性能管理器
    _performanceManager = PerformanceManager.instance;
    _performanceManager.initialize();
    
    // 添加背景效果
    backgroundEffect = BackgroundEffect();
    add(backgroundEffect);
    
    _addBoundaries();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _performanceManager.updateStats(dt);
    
    // 定期清理屏幕外的对象
    _cleanupOffScreenObjects();
  }

  void _cleanupOffScreenObjects() {
    final componentsToRemove = <BodyComponent>[];
    
    for (final component in children) {
      if (component is LetterBody) {
        if (component.body.position.y > size.y + 10) {
          componentsToRemove.add(component);
        }
      } else if (component is ParticleExplosion) {
        if (component.timeAlive > component.maxLifetime) {
          componentsToRemove.add(component as BodyComponent);
        }
      }
    }
    
    for (final component in componentsToRemove) {
      remove(component);
      if (component is LetterBody) {
        _performanceManager.releaseLetter(component);
      }
    }
  }

  void handleTap(Vector2 position) {
    final worldPosition = screenToWorld(position);
    _handleTap(worldPosition);
  }

  void _handleTap(Vector2 position) {
    // 寻找点击位置附近的字母
    final tappedLetter = _findLetterAt(position);
    
    if (tappedLetter != null) {
      // 字母被点击，创建特殊效果
      _createTapEffect(tappedLetter);
    } else {
      // 空白区域被点击，创建涟漪效果
      _createRippleEffect(position);
    }
  }

  LetterBody? _findLetterAt(Vector2 position) {
    const tapRadius = 3.0;
    
    for (final component in children) {
      if (component is LetterBody) {
        final distance = component.body.position.distanceTo(position);
        if (distance <= tapRadius) {
          return component;
        }
      }
    }
    return null;
  }

  void _createTapEffect(LetterBody letter) {
    // 给字母施加向上的冲击力
    final impulse = Vector2(0, -50);
    letter.body.applyLinearImpulse(impulse);
    
    // 创建点击爆炸效果
    final tapExplosion = ParticleExplosion(
      position: letter.body.position,
      baseColor: letter.color,
    );
    add(tapExplosion);
    
    // 创建冲击波
    final shockWave = ShockWave(
      center: letter.body.position,
      color: letter.color,
    );
    add(shockWave);
  }

  void _createRippleEffect(Vector2 position) {
    // 创建涟漪效果
    final ripple = RippleEffect(
      center: position,
      color: const Color(0xFF00F3FF),
    );
    add(ripple);
  }

  void clearAllLetters() {
    // 移除所有字母组件
    children.whereType<LetterBody>().toList().forEach((letter) {
      remove(letter);
    });
  }

  void setDropSpeed(double speed) {
    dropSpeed = speed;
  }

  void setSoundEnabled(bool enabled) {
    soundEnabled = enabled;
  }

  void _addBoundaries() {
    final ground = BodyDef()
      ..position = Vector2(0.0, size.y - 1.0)
      ..type = BodyType.static;

    final groundBody = world.createBody(ground);
    final groundShape = EdgeShape()
      ..set(Vector2(-size.x, 0.0), Vector2(size.x * 2, 0.0));

    groundBody.createFixture(
      FixtureDef(groundShape)
        ..friction = 0.3
        ..restitution = 0.5,
    );

    final leftWall = BodyDef()
      ..position = Vector2(0.0, 0.0)
      ..type = BodyType.static;

    final leftWallBody = world.createBody(leftWall);
    final leftWallShape = EdgeShape()
      ..set(Vector2(0.0, -size.y), Vector2(0.0, size.y));

    leftWallBody.createFixture(
      FixtureDef(leftWallShape)
        ..friction = 0.3
        ..restitution = 0.5,
    );

    final rightWall = BodyDef()
      ..position = Vector2(size.x, 0.0)
      ..type = BodyType.static;

    final rightWallBody = world.createBody(rightWall);
    final rightWallShape = EdgeShape()
      ..set(Vector2(0.0, -size.y), Vector2(0.0, size.y));

    rightWallBody.createFixture(
      FixtureDef(rightWallShape)
        ..friction = 0.3
        ..restitution = 0.5,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
