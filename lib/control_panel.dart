import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlPanel extends StatefulWidget {
  final VoidCallback? onPlayPause;
  final VoidCallback? onSettings;
  final VoidCallback? onClear;
  final bool isPlaying;
  
  const ControlPanel({
    super.key,
    this.onPlayPause,
    this.onSettings,
    this.onClear,
    this.isPlaying = true,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A12).withOpacity(0.9),
            const Color(0xFF1A1A2E).withOpacity(0.95),
          ],
        ),
        border: const Border(
          top: BorderSide(
            color: Color(0xFF00F3FF),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F3FF).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
                label: widget.isPlaying ? '暂停' : '播放',
                onPressed: widget.onPlayPause,
                isPrimary: true,
              ),
              _buildControlButton(
                icon: Icons.clear_all,
                label: '清除',
                onPressed: widget.onClear,
              ),
              _buildControlButton(
                icon: Icons.settings,
                label: '设置',
                onPressed: widget.onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 70,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPrimary
                    ? [
                        const Color(0xFF00F3FF).withOpacity(0.2),
                        const Color(0xFF00F3FF).withOpacity(0.1),
                      ]
                    : [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF2A2A3E),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPrimary
                    ? const Color(0xFF00F3FF)
                    : const Color(0xFF00F3FF).withOpacity(0.3),
                width: isPrimary ? 2.0 : 1.0,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00F3FF).withOpacity(0.4),
                        blurRadius: 10 * _pulseAnimation.value,
                        spreadRadius: 2 * (_pulseAnimation.value - 0.8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF00F3FF).withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary
                      ? const Color(0xFF00F3FF)
                      : const Color(0xFF00F3FF).withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: isPrimary
                        ? const Color(0xFF00F3FF)
                        : const Color(0xFF00F3FF).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsDialog extends StatefulWidget {
  final double currentSpeed;
  final bool soundEnabled;
  final Function(double) onSpeedChanged;
  final Function(bool) onSoundToggled;
  
  const SettingsDialog({
    super.key,
    required this.currentSpeed,
    required this.soundEnabled,
    required this.onSpeedChanged,
    required this.onSoundToggled,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late double _tempSpeed;
  late bool _tempSound;

  @override
  void initState() {
    super.initState();
    
    _tempSpeed = widget.currentSpeed;
    _tempSound = widget.soundEnabled;
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SlideTransition(
        position: _slideAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF0A0A12),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(
                color: const Color(0xFF00F3FF),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F3FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '设置',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 18,
                            color: const Color(0xFF00F3FF),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            color: const Color(0xFF00F3FF),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // 掉落速度设置
                    Text(
                      '掉落速度',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 12,
                        color: const Color(0xFF00F3FF).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF00F3FF),
                        inactiveTrackColor: const Color(0xFF00F3FF).withOpacity(0.3),
                        thumbColor: const Color(0xFF00F3FF),
                        overlayColor: const Color(0xFF00F3FF).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _tempSpeed,
                        min: 0.2,
                        max: 2.0,
                        divisions: 18,
                        label: '${(_tempSpeed * 100).round()}%',
                        onChanged: (value) {
                          setState(() {
                            _tempSpeed = value;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 音效开关
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '音效',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 12,
                            color: const Color(0xFF00F3FF).withOpacity(0.8),
                          ),
                        ),
                        Switch(
                          value: _tempSound,
                          activeColor: const Color(0xFF00F3FF),
                          inactiveThumbColor: const Color(0xFF666666),
                          inactiveTrackColor: const Color(0xFF333333),
                          onChanged: (value) {
                            setState(() {
                              _tempSound = value;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // 确认按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F3FF),
                          foregroundColor: const Color(0xFF0A0A12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          widget.onSpeedChanged(_tempSpeed);
                          widget.onSoundToggled(_tempSound);
                          Navigator.pop(context);
                        },
                        child: Text(
                          '确认',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}