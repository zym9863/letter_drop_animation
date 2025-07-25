import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'particle_effects.dart';

class LetterBody extends BodyComponent {
  final String letter;
  final Color color;
  final Vector2 initialPosition;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  static const List<Color> cyberpunkColors = [
    Color(0xFF00F3FF), // 量子蓝
    Color(0xFFFF00FF), // 故障紫
    Color(0xFF00FF47), // 信号绿
    Color(0xFFFFFF00), // 电流黄
    Color(0xFFFF0080), // 霓虹粉
    Color(0xFF80FF00), // 毒液绿
    Color(0xFF0080FF), // 深海蓝
    Color(0xFFFF8000), // 核能橙
    Color(0xFF8000FF), // 等离子紫
    Color(0xFF00FFFF), // 冰晶蓝
  ];
  
  double _glitchOffset = 0.0;
  double _opacity = 0.3;
  late TrailEffect _trailEffect;
  bool _hasCollided = false;
  
  LetterBody({
    required this.letter,
    required this.color,
    required this.initialPosition,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 初始化轨迹效果
    _trailEffect = TrailEffect(
      initialPosition: initialPosition,
      color: color,
    );
    game.add(_trailEffect);
  }

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(
        1.0, // 字母宽度的一半
        1.0, // 字母高度的一半
        Vector2.zero(), // 中心位置
        0.0, // 旋转角度
      );

    // 为元音字母增加质量，特殊字母有不同属性
    final bool isVowel = 'AEIOU'.contains(letter);
    final bool isSpecial = 'XYZ'.contains(letter);
    
    final double density = isVowel ? 1.2 : (isSpecial ? 0.8 : 1.0);
    final double airResistance = 0.8 + math.Random().nextDouble() * 0.4;
    
    final fixtureDef = FixtureDef(
      shape,
      density: density,
      friction: airResistance,
      restitution: isSpecial ? 0.9 : 0.6, // 特殊字母更有弹性
    );

    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      userData: this,
    );

    final bodyInstance = world.createBody(bodyDef)..createFixture(fixtureDef);
    
    return bodyInstance;
  }

  void _createCollisionEffects() {
    // 创建粒子爆炸
    final explosion = ParticleExplosion(
      position: body.position,
      baseColor: color,
    );
    game.add(explosion);
    
    // 创建冲击波
    final shockWave = ShockWave(
      center: body.position,
      color: color,
    );
    game.add(shockWave);
    
    _playCollisionSound();
    
    // 重置碰撞标志，允许多次碰撞效果
    Future.delayed(const Duration(milliseconds: 500), () {
      _hasCollided = false;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 更新轨迹效果
    _trailEffect.updatePosition(body.position);
    
    if (body.position.y > game.size.y + 5.0) {
      // 清理轨迹效果
      _trailEffect.removeFromParent();
      // 移除字母
      world.remove(this);
      _playCollisionSound();
    }
    
    // 更新故障效果
    _glitchOffset = math.sin(game.currentTime() * 10) * 2.0;
    _opacity = math.min(1.0, _opacity + dt);
  }
  
  void _playCollisionSound() {
    // 移除未使用的频率计算
    _audioPlayer.play(AssetSource('collision.wav'));
  }

  @override
  void render(Canvas canvas) {
    final position = body.position;
    final angle = body.angle;
    final velocity = body.linearVelocity;
    final speed = velocity.length;

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(angle);

    // 根据速度调整大小和发光强度
    final speedFactor = math.min(speed / 50, 2.0);
    final fontSize = 24 + speedFactor * 4;
    final glowIntensity = 0.7 + speedFactor * 0.3;

    // 主要文本样式
    final mainTextStyle = GoogleFonts.pressStart2p(
      color: color.withOpacity(_opacity),
      fontSize: fontSize,
      shadows: [
        Shadow(
          color: color.withOpacity(glowIntensity),
          blurRadius: 12 + speedFactor * 5,
        ),
        Shadow(
          color: color.withOpacity(0.5),
          blurRadius: 20 + speedFactor * 8,
        ),
      ],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: letter, style: mainTextStyle),
      textDirection: TextDirection.ltr,
    );
    
    // 故障效果层（多层不同颜色）
    if (_glitchOffset.abs() > 1.0) {
      final glitchColors = [
        const Color(0xFFFF00FF),
        const Color(0xFF00FF47),
        const Color(0xFFFFFF00),
      ];
      
      for (int i = 0; i < 3; i++) {
        final glitchOffset = _glitchOffset * (i + 1) * 0.5;
        final glitchTextPainter = TextPainter(
          text: TextSpan(
            text: letter,
            style: GoogleFonts.pressStart2p(
              color: glitchColors[i % glitchColors.length].withOpacity(0.4),
              fontSize: fontSize,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        
        glitchTextPainter.layout();
        glitchTextPainter.paint(
          canvas,
          Offset(
            -glitchTextPainter.width / 2 + glitchOffset,
            -glitchTextPainter.height / 2,
          ),
        );
      }
    }

    textPainter.layout();
    
    // 为特殊字母添加额外发光效果
    if ('XYZ'.contains(letter)) {
      final extraGlowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 25);
      
      final extraGlowTextPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: GoogleFonts.pressStart2p(
            fontSize: fontSize,
            foreground: extraGlowPaint,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      extraGlowTextPainter.layout();
      extraGlowTextPainter.paint(
        canvas,
        Offset(-extraGlowTextPainter.width / 2, -extraGlowTextPainter.height / 2),
      );
    }
    
    // 绘制主要文本
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }
}

class LetterGenerator {
  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static final _random = math.Random();

  static Color _randomColor() {
    return LetterBody.cyberpunkColors[_random.nextInt(LetterBody.cyberpunkColors.length)];
  }

  static String _randomLetter() {
    return _letters[_random.nextInt(_letters.length)];
  }

  static Vector2 _randomPosition(double width) {
    return Vector2(
      _random.nextDouble() * width,
      -1.0, // 从屏幕顶部稍微上方开始
    );
  }

  static LetterBody generateLetter(double width) {
    return LetterBody(
      letter: _randomLetter(),
      color: _randomColor(),
      initialPosition: _randomPosition(width),
    );
  }
}