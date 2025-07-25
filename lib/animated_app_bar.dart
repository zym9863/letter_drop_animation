import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  
  const AnimatedAppBar({
    super.key,
    required this.title,
  });

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}

class _AnimatedAppBarState extends State<AnimatedAppBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glitchAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    
    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 故障效果控制器
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _glitchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_glitchController);

    // 扫描线控制器
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scanController);

    // 随机触发故障效果
    _startRandomGlitch();
  }

  void _startRandomGlitch() {
    Future.delayed(Duration(milliseconds: 2000 + math.Random().nextInt(3000)), () {
      if (mounted) {
        _glitchController.forward().then((_) {
          _glitchController.reverse();
          _startRandomGlitch();
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glitchController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.preferredSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A12),
            const Color(0xFF1A1A2E),
            const Color(0xFF0A0A12),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF00F3FF),
            width: 2.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F3FF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 背景网格图案
          CustomPaint(
            painter: GridPatternPainter(),
            size: Size.infinite,
          ),
          
          // 扫描线效果
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ScanLinePainter(_scanAnimation.value),
                size: Size.infinite,
              );
            },
          ),
          
          // 标题内容
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _glitchAnimation]),
                builder: (context, child) {
                  return Stack(
                    children: [
                      // 故障效果层
                      if (_glitchAnimation.value > 0)
                        ..._buildGlitchLayers(),
                      
                      // 主标题
                      _buildMainTitle(),
                      
                      // 发光效果
                      _buildGlowEffect(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGlitchLayers() {
    final random = math.Random(42); // 固定种子，保证一致的故障效果
    return List.generate(3, (index) {
      final offset = random.nextDouble() * 4 - 2;
      final colors = [
        const Color(0xFFFF00FF),
        const Color(0xFF00FF47),
        const Color(0xFFFFFF00),
      ];
      
      return Transform.translate(
        offset: Offset(offset * _glitchAnimation.value, 0),
        child: Opacity(
          opacity: _glitchAnimation.value * 0.7,
          child: Text(
            widget.title,
            style: GoogleFonts.pressStart2p(
              fontSize: 20,
              color: colors[index],
              shadows: [
                Shadow(
                  color: colors[index],
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMainTitle() {
    return Text(
      widget.title,
      style: GoogleFonts.pressStart2p(
        fontSize: 20,
        color: const Color(0xFF00F3FF),
        shadows: [
          Shadow(
            color: const Color(0xFF00F3FF),
            blurRadius: 15 + _pulseAnimation.value * 10,
          ),
          const Shadow(
            color: Colors.black,
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Opacity(
      opacity: _pulseAnimation.value * 0.5,
      child: Text(
        widget.title,
        style: GoogleFonts.pressStart2p(
          fontSize: 20,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFF00F3FF).withOpacity(0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 20),
        ),
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F3FF).withOpacity(0.05)
      ..strokeWidth = 1.0;

    const spacing = 20.0;
    
    // 绘制垂直线
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // 绘制水平线
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanLinePainter extends CustomPainter {
  final double progress;
  
  ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F3FF).withOpacity(0.6)
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final y = size.height * progress;
    
    // 绘制扫描线
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
    
    // 绘制扫描线发光效果
    final glowPaint = Paint()
      ..color = const Color(0xFF00F3FF).withOpacity(0.3)
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is ScanLinePainter && oldDelegate.progress != progress;
  }
}