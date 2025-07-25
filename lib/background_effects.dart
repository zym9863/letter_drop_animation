import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class BackgroundEffect extends Component with HasGameRef {
  final List<Particle> particles = [];
  final List<GridLine> gridLines = [];
  late double time;
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    time = 0;
    _initializeParticles();
    _initializeGrid();
  }

  void _initializeParticles() {
    final random = math.Random();
    // 创建50个背景粒子
    for (int i = 0; i < 50; i++) {
      particles.add(Particle(
        position: Vector2(
          random.nextDouble() * gameRef.size.x,
          random.nextDouble() * gameRef.size.y,
        ),
        velocity: Vector2(
          (random.nextDouble() - 0.5) * 20,
          (random.nextDouble() - 0.5) * 20,
        ),
        color: _getRandomCyberpunkColor(),
        size: random.nextDouble() * 3 + 1,
      ));
    }
  }

  void _initializeGrid() {
    final spacing = 40.0;
    
    // 垂直网格线
    for (double x = 0; x <= gameRef.size.x; x += spacing) {
      gridLines.add(GridLine(
        start: Vector2(x, 0),
        end: Vector2(x, gameRef.size.y),
        isVertical: true,
      ));
    }
    
    // 水平网格线
    for (double y = 0; y <= gameRef.size.y; y += spacing) {
      gridLines.add(GridLine(
        start: Vector2(0, y),
        end: Vector2(gameRef.size.x, y),
        isVertical: false,
      ));
    }
  }

  Color _getRandomCyberpunkColor() {
    const colors = [
      Color(0xFF00F3FF), // 量子蓝
      Color(0xFFFF00FF), // 故障紫
      Color(0xFF00FF47), // 信号绿
      Color(0xFFFFFF00), // 电流黄
      Color(0xFFFF0080), // 霓虹粉
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    
    // 更新粒子
    for (final particle in particles) {
      particle.update(dt, gameRef.size);
    }
    
    // 更新网格线动画
    for (final line in gridLines) {
      line.update(dt, time);
    }
  }

  @override
  void render(Canvas canvas) {
    // 绘制网格
    for (final line in gridLines) {
      line.render(canvas);
    }
    
    // 绘制粒子
    for (final particle in particles) {
      particle.render(canvas);
    }
  }
}

class Particle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double opacity = 1.0;
  double flickerSpeed;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  }) : flickerSpeed = math.Random().nextDouble() * 5 + 2;

  void update(double dt, Vector2 screenSize) {
    // 更新位置
    position += velocity * dt;
    
    // 边界检查，粒子移出屏幕后从对面重新进入
    if (position.x < 0) position.x = screenSize.x;
    if (position.x > screenSize.x) position.x = 0;
    if (position.y < 0) position.y = screenSize.y;
    if (position.y > screenSize.y) position.y = 0;
    
    // 闪烁效果
    opacity = (math.sin(DateTime.now().millisecondsSinceEpoch / 1000.0 * flickerSpeed) + 1) / 2;
    opacity = math.max(0.1, opacity * 0.6);
  }

  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    // 绘制发光效果
    final glowPaint = Paint()
      ..color = color.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(Offset(position.x, position.y), size * 3, glowPaint);
    canvas.drawCircle(Offset(position.x, position.y), size, paint);
  }
}

class GridLine {
  Vector2 start;
  Vector2 end;
  bool isVertical;
  double animationOffset = 0;
  double pulseIntensity = 0;
  
  GridLine({
    required this.start,
    required this.end,
    required this.isVertical,
  });

  void update(double dt, double time) {
    // 扫描线动画
    animationOffset = (time * 50) % (isVertical ? end.y : end.x);
    
    // 脉冲效果
    pulseIntensity = (math.sin(time * 2) + 1) / 2 * 0.3 + 0.1;
  }

  void render(Canvas canvas) {
    final basePaint = Paint()
      ..color = const Color(0xFF00F3FF).withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final glowPaint = Paint()
      ..color = const Color(0xFF00F3FF).withOpacity(pulseIntensity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    // 绘制基础网格线
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      basePaint,
    );
    
    // 绘制发光的扫描线段
    if (isVertical) {
      final scanStart = math.max(0, animationOffset - 20);
      final scanEnd = math.min(end.y, animationOffset + 20);
      if (scanStart < scanEnd) {
        canvas.drawLine(
          Offset(start.x, scanStart.toDouble()),
          Offset(end.x, scanEnd.toDouble()),
          glowPaint,
        );
      }
    } else {
      final scanStart = math.max(0, animationOffset - 20);
      final scanEnd = math.min(end.x, animationOffset + 20);
      if (scanStart < scanEnd) {
        canvas.drawLine(
          Offset(scanStart.toDouble(), start.y),
          Offset(scanEnd.toDouble(), end.y),
          glowPaint,
        );
      }
    }
  }
}