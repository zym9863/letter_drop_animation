import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class ParticleExplosion extends Component with HasGameRef {
  final Vector2 position;
  final Color baseColor;
  final List<ExplosionParticle> particles = [];
  double timeAlive = 0;
  final double maxLifetime = 2.0;
  
  ParticleExplosion({
    required this.position,
    required this.baseColor,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _createParticles();
  }

  void _createParticles() {
    final random = math.Random();
    const particleCount = 15;
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final speed = 50 + random.nextDouble() * 100;
      final velocity = Vector2(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );
      
      particles.add(ExplosionParticle(
        position: Vector2.copy(position),
        velocity: velocity,
        color: _getVariationColor(),
        size: random.nextDouble() * 3 + 1,
        lifetime: random.nextDouble() * 1.5 + 0.5,
      ));
    }
  }

  Color _getVariationColor() {
    final random = math.Random();
    final variations = [
      baseColor,
      baseColor.withOpacity(0.8),
      Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor,
      Color.lerp(baseColor, Colors.yellow, 0.2) ?? baseColor,
    ];
    return variations[random.nextInt(variations.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeAlive += dt;
    
    // 更新粒子
    particles.removeWhere((particle) {
      particle.update(dt);
      return particle.isDead;
    });
    
    // 如果时间超过最大生命周期或没有粒子了，移除此组件
    if (timeAlive > maxLifetime || particles.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final particle in particles) {
      particle.render(canvas);
    }
  }
}

class ExplosionParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double lifetime;
  double timeAlive = 0;
  bool get isDead => timeAlive >= lifetime;
  
  ExplosionParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  });

  void update(double dt) {
    timeAlive += dt;
    
    // 更新位置
    position += velocity * dt;
    
    // 重力影响
    velocity.y += 150 * dt;
    
    // 空气阻力
    velocity *= 0.98;
    
    // 随时间减小尺寸
    size *= 0.995;
  }

  void render(Canvas canvas) {
    if (isDead) return;
    
    final opacity = math.max(0.0, 1.0 - (timeAlive / lifetime));
    final currentColor = color.withOpacity(opacity);
    
    final paint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.fill;
    
    // 发光效果
    final glowPaint = Paint()
      ..color = currentColor.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    canvas.drawCircle(Offset(position.x, position.y), size * 2, glowPaint);
    canvas.drawCircle(Offset(position.x, position.y), size, paint);
  }
}

class TrailEffect extends Component with HasGameRef {
  final List<TrailPoint> trailPoints = [];
  final int maxTrailLength = 10;
  final Color color;
  Vector2 _lastPosition;
  
  TrailEffect({
    required Vector2 initialPosition,
    required this.color,
  }) : _lastPosition = Vector2.copy(initialPosition);

  void updatePosition(Vector2 newPosition) {
    // 如果位置变化足够大，添加新的轨迹点
    if (_lastPosition.distanceTo(newPosition) > 2.0) {
      trailPoints.add(TrailPoint(
        position: Vector2.copy(newPosition),
        timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
      ));
      
      // 限制轨迹长度
      while (trailPoints.length > maxTrailLength) {
        trailPoints.removeAt(0);
      }
      
      _lastPosition = Vector2.copy(newPosition);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    
    // 移除过旧的轨迹点
    trailPoints.removeWhere((point) => 
      currentTime - point.timestamp > 500); // 0.5秒后淡出
  }

  @override
  void render(Canvas canvas) {
    if (trailPoints.length < 2) return;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    
    for (int i = 0; i < trailPoints.length - 1; i++) {
      final point1 = trailPoints[i];
      final point2 = trailPoints[i + 1];
      
      // 计算透明度基于时间
      final age1 = currentTime - point1.timestamp;
      final age2 = currentTime - point2.timestamp;
      final opacity1 = math.max(0.0, 1.0 - age1 / 500);
      final opacity2 = math.max(0.0, 1.0 - age2 / 500);
      
      // 计算线条宽度
      final width1 = 3.0 * opacity1;
      final width2 = 3.0 * opacity2;
      
      if (opacity1 > 0 && opacity2 > 0) {
        final paint = Paint()
          ..color = color.withOpacity((opacity1 + opacity2) / 2)
          ..strokeWidth = (width1 + width2) / 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        
        canvas.drawLine(
          Offset(point1.position.x, point1.position.y),
          Offset(point2.position.x, point2.position.y),
          paint,
        );
      }
    }
  }
}

class TrailPoint {
  final Vector2 position;
  final double timestamp;
  
  TrailPoint({
    required this.position,
    required this.timestamp,
  });
}

class ShockWave extends Component with HasGameRef {
  final Vector2 center;
  final Color color;
  double radius = 0;
  double maxRadius = 100;
  double timeAlive = 0;
  final double maxLifetime = 0.8;
  
  ShockWave({
    required this.center,
    required this.color,
  });

  @override
  void update(double dt) {
    super.update(dt);
    timeAlive += dt;
    
    // 扩展冲击波
    radius = (timeAlive / maxLifetime) * maxRadius;
    
    if (timeAlive >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = timeAlive / maxLifetime;
    final opacity = math.max(0.0, 1.0 - progress);
    
    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      paint,
    );
  }
}

class RippleEffect extends Component with HasGameRef {
  final Vector2 center;
  final Color color;
  double timeAlive = 0;
  final double maxLifetime = 1.5;
  final List<RippleRing> rings = [];
  
  RippleEffect({
    required this.center,
    required this.color,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 创建多个涟漪环
    for (int i = 0; i < 3; i++) {
      rings.add(RippleRing(
        delay: i * 0.2,
        maxRadius: 80.0 + i * 20,
        color: color,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeAlive += dt;
    
    for (final ring in rings) {
      ring.update(dt);
    }
    
    if (timeAlive >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final ring in rings) {
      ring.render(canvas, center);
    }
  }
}

class RippleRing {
  final double delay;
  final double maxRadius;
  final Color color;
  double timeAlive = 0;
  final double lifetime = 1.2;
  
  RippleRing({
    required this.delay,
    required this.maxRadius,
    required this.color,
  });

  void update(double dt) {
    if (timeAlive >= delay) {
      timeAlive += dt;
    } else {
      timeAlive += dt;
    }
  }

  void render(Canvas canvas, Vector2 center) {
    if (timeAlive < delay) return;
    
    final adjustedTime = timeAlive - delay;
    if (adjustedTime >= lifetime) return;
    
    final progress = adjustedTime / lifetime;
    final radius = progress * maxRadius;
    final opacity = math.max(0.0, 1.0 - progress);
    
    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * (1.0 - progress * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      paint,
    );
  }
}