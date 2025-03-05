import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class LetterBody extends BodyComponent {
  final String letter;
  final Color color;
  final Vector2 initialPosition;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  static const List<Color> cyberpunkColors = [
    Color(0xFF00F3FF), // 量子蓝
    Color(0xFFFF00FF), // 故障紫
    Color(0xFF00FF47), // 信号绿
  ];
  
  double _glitchOffset = 0.0;
  double _opacity = 0.3;
  
  LetterBody({
    required this.letter,
    required this.color,
    required this.initialPosition,
  });

// 移除未使用的 _isOffScreen 字段

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(
        1.0, // 字母宽度的一半
        1.0, // 字母高度的一半
        Vector2.zero(), // 中心位置
        0.0, // 旋转角度
      );

    // 为元音字母增加质量
    final bool isVowel = 'AEIOU'.contains(letter);
    final double density = isVowel ? 1.2 : 1.0;
    final double airResistance = 0.8 + math.Random().nextDouble() * 0.4;
    
    final fixtureDef = FixtureDef(
      shape,
      density: density,
      friction: airResistance,
      restitution: 0.6,
    );

    final bodyDef = BodyDef(
      position: initialPosition,
      type: BodyType.dynamic,
      userData: this,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (body.position.y > game.size.y + 5.0) {
      // 移除对未定义变量的引用，因为我们只需要移除物体
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

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(angle);

    // 主要文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: GoogleFonts.pressStart2p(
          color: color.withOpacity(_opacity),
          fontSize: 24,
          shadows: [
            Shadow(
              color: color.withOpacity(0.7),
              blurRadius: 12,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    // 故障效果
    final glitchTextPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: GoogleFonts.pressStart2p(
          color: cyberpunkColors[math.Random().nextInt(cyberpunkColors.length)].withOpacity(0.5),
          fontSize: 24,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    // 绘制故障效果
    glitchTextPainter.layout();
    glitchTextPainter.paint(
      canvas,
      Offset(-glitchTextPainter.width / 2 + _glitchOffset, -glitchTextPainter.height / 2),
    );
    
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