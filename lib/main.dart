import 'dart:async' as async_dart;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/game.dart';
import 'letter_physics.dart';

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

class LetterDropPage extends StatelessWidget {
  const LetterDropPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Letter Drop Animation'),
        centerTitle: true,
      ),
      body: const LetterDropWorld(),
    );
  }
}

class LetterDropWorld extends StatefulWidget {
  const LetterDropWorld({super.key});

  @override
  State<LetterDropWorld> createState() => _LetterDropWorldState();
}

class _LetterDropWorldState extends State<LetterDropWorld> {
  late final GameWorld _gameWorld;
  async_dart.Timer? _letterGenerationTimer;

  @override
  void initState() {
    super.initState();
    _gameWorld = GameWorld();
    _startLetterGeneration();
  }

  @override
  void dispose() {
    _letterGenerationTimer?.cancel();
    super.dispose();
  }

  void _startLetterGeneration() {
    _letterGenerationTimer = async_dart.Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (mounted) {
          final letter = LetterGenerator.generateLetter(_gameWorld.size.x);
          _gameWorld.add(letter);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A12),
      child: GameWidget(game: _gameWorld),
    );
  }
}

class GameWorld extends Forge2DGame {
  static const double worldScale = 10.0;

  GameWorld() : super(gravity: Vector2(0, 98.1), zoom: worldScale);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _addBoundaries();
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
