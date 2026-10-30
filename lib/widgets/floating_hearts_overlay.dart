import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class FloatingHeartsOverlay {
  static void show(BuildContext context, {String? customTitle, String? customMessage}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CelebrationWidget(
        customTitle: customTitle,
        customMessage: customMessage,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _CelebrationWidget extends StatefulWidget {
  final String? customTitle;
  final String? customMessage;
  final VoidCallback onDismiss;

  const _CelebrationWidget({
    this.customTitle,
    this.customMessage,
    required this.onDismiss,
  });

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HeartParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Generate 25 floating hearts with various pastel colors, sizes and speeds
    for (int i = 0; i < 25; i++) {
      _particles.add(_HeartParticle(
        x: _random.nextDouble(),
        y: 0.8 + _random.nextDouble() * 0.3,
        size: 16.0 + _random.nextDouble() * 26.0,
        speed: 0.5 + _random.nextDouble() * 0.8,
        sway: (_random.nextDouble() - 0.5) * 0.25,
        color: [
          AppColors.blushPink,
          AppColors.lavender,
          const Color(0xFFFF85A1),
          const Color(0xFFFFAAA6),
          AppColors.mintSuccess,
          Colors.white,
        ][_random.nextInt(6)],
      ));
    }

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.black.withOpacity(0.35),
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Stack(
          children: [
            // Floating Hearts Particles
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: _particles.map((p) {
                    final progress = _controller.value * p.speed;
                    final currentY = (p.y - progress * 1.1) * size.height;
                    final currentX =
                        (p.x + sin(_controller.value * 6 * pi + p.x * 10) * p.sway) *
                            size.width;
                    final opacity = (1.0 - _controller.value).clamp(0.0, 1.0);

                    return Positioned(
                      left: currentX,
                      top: currentY,
                      child: Opacity(
                        opacity: opacity,
                        child: Icon(
                          Icons.favorite,
                          size: p.size,
                          color: p.color,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Center Teddy / Baby-Bump Celebration Card
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF6EC),
                      Color(0xFFFFEEF2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.roseGold.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.blushPink,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cute Baby Bump / Teddy Avatar with glowing heart
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.blushPink.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🧸🍼',
                          style: TextStyle(fontSize: 44),
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .then()
                        .shake(duration: 400.ms),

                    const SizedBox(height: 16),

                    // Loving Title
                    Text(
                      widget.customTitle ?? 'Thank you, Bujji! ❤️',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepPlum,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 8),

                    // Sweet Subtitle
                    Text(
                      widget.customMessage ??
                          'Tablet taken, our baby is safe and loved 💕\nLove from Babu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF6E5675),
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double sway;
  final Color color;

  _HeartParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.sway,
    required this.color,
  });
}

