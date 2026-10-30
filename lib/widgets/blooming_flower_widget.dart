import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'glass_container.dart';

class BloomingFlowerWidget extends StatelessWidget {
  final int streakDays;

  const BloomingFlowerWidget({
    super.key,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Growth stage (0: seed, 1: tiny sprout, 2: growing stem & bud, 3: blooming, 4: majestic full bloom)
    final int stage = streakDays == 0
        ? 0
        : streakDays <= 2
            ? 1
            : streakDays <= 4
                ? 2
                : streakDays <= 6
                    ? 3
                    : 4;

    final String stageTelugu = streakDays == 0
        ? 'Molakaththe Samayam 🌱'
        : streakDays <= 2
            ? 'Chiguristunna Mokka 🌿'
            : streakDays <= 4
                ? 'Mogga Thoduguthondi 🌷'
                : streakDays <= 6
                    ? 'Vikasistunna Puvvu 🌸'
                    : 'Poorthiga Vikasincha Prema Puvvu! 🌺✨';

    final String stageEnglish = streakDays == 0
        ? 'A new seed planted with love'
        : streakDays <= 2
            ? 'Tender little sprout growing'
            : streakDays <= 4
                ? 'Lovely bud ready to bloom'
                : streakDays <= 6
                    ? 'Blossoming petals of care'
                    : 'Radiant full blooming love!';

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          // Blooming Plant Canvas
          SizedBox(
            width: 80,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (stage == 4)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.softPeach.withOpacity(0.6),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                CustomPaint(
                  size: const Size(80, 90),
                  painter: _PlantPainter(stage: stage),
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: Offset(stage == 4 ? 1.08 : 1.03, stage == 4 ? 1.08 : 1.03),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),

          const SizedBox(width: 14),

          // Streak Info & Loving encouragement
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.mintSuccess.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.mintSuccess.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Color(0xFFFF6B6B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$streakDays Days Streak',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.deepPlum,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  stageEnglish,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                  ),
                ),
                Text(
                  'Daily care for you and our baby ❤️',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? AppColors.lavender : const Color(0xFF6E5D80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final int stage;

  _PlantPainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Soil Pot base
    final potPaint = Paint()
      ..color = const Color(0xFFC78263)
      ..style = PaintingStyle.fill;

    final potPath = Path()
      ..moveTo(w * 0.28, h * 0.78)
      ..lineTo(w * 0.72, h * 0.78)
      ..lineTo(w * 0.65, h * 0.96)
      ..lineTo(w * 0.35, h * 0.96)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Pot rim
    final rimPaint = Paint()
      ..color = const Color(0xFFB06F52)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.74, w * 0.52, h * 0.06),
        const Radius.circular(4),
      ),
      rimPaint,
    );

    // Stage 0: Little seed
    if (stage == 0) {
      final seedPaint = Paint()..color = const Color(0xFF6B4226);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: 10, height: 6),
        seedPaint,
      );
      return;
    }

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF7CB342)
      ..strokeWidth = stage >= 3 ? 4 : 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemTopY = stage == 1
        ? h * 0.55
        : stage == 2
            ? h * 0.40
            : h * 0.32;

    final stemPath = Path()
      ..moveTo(w * 0.5, h * 0.74)
      ..quadraticBezierTo(w * 0.48, (h * 0.74 + stemTopY) / 2, w * 0.5, stemTopY);
    canvas.drawPath(stemPath, stemPaint);

    // Leaves
    final leafPaint = Paint()
      ..color = const Color(0xFF8BC34A)
      ..style = PaintingStyle.fill;

    if (stage >= 1) {
      // Left leaf
      final leftLeaf = Path()
        ..moveTo(w * 0.49, h * 0.62)
        ..quadraticBezierTo(w * 0.32, h * 0.62, w * 0.30, h * 0.54)
        ..quadraticBezierTo(w * 0.44, h * 0.50, w * 0.49, h * 0.62);
      canvas.drawPath(leftLeaf, leafPaint);

      // Right leaf
      final rightLeaf = Path()
        ..moveTo(w * 0.51, h * 0.58)
        ..quadraticBezierTo(w * 0.68, h * 0.58, w * 0.70, h * 0.50)
        ..quadraticBezierTo(w * 0.56, h * 0.46, w * 0.51, h * 0.58);
      canvas.drawPath(rightLeaf, leafPaint);
    }

    if (stage >= 2) {
      // Second set of higher leaves
      final higherLeaf = Path()
        ..moveTo(w * 0.49, h * 0.45)
        ..quadraticBezierTo(w * 0.35, h * 0.44, w * 0.34, h * 0.38)
        ..quadraticBezierTo(w * 0.45, h * 0.34, w * 0.49, h * 0.45);
      canvas.drawPath(higherLeaf, leafPaint);
    }

    // Flower bud (stage 2)
    if (stage == 2) {
      final budPaint = Paint()..color = const Color(0xFFE85A88);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, stemTopY - 4), width: 14, height: 18),
        budPaint,
      );
    }

    // Blossoming Flower (stage 3 and 4)
    if (stage >= 3) {
      final flowerCenter = Offset(w * 0.5, stemTopY);
      final petalPaint = Paint()
        ..color = stage == 4 ? const Color(0xFFFF5288) : const Color(0xFFF8A5C2)
        ..style = PaintingStyle.fill;

      final int petalCount = stage == 4 ? 8 : 5;
      final double petalRadius = stage == 4 ? 16 : 12;

      for (int i = 0; i < petalCount; i++) {
        final angle = (2 * pi / petalCount) * i;
        final px = flowerCenter.dx + cos(angle) * (petalRadius * 0.7);
        final py = flowerCenter.dy + sin(angle) * (petalRadius * 0.7);
        canvas.drawCircle(Offset(px, py), petalRadius * 0.6, petalPaint);
      }

      // Center golden core
      final corePaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(flowerCenter, petalRadius * 0.45, corePaint);

      // Sparkles for stage 4
      if (stage == 4) {
        final sparklePaint = Paint()..color = const Color(0xFFFFE082);
        canvas.drawCircle(Offset(w * 0.22, h * 0.22), 2.5, sparklePaint);
        canvas.drawCircle(Offset(w * 0.78, h * 0.20), 3.0, sparklePaint);
        canvas.drawCircle(Offset(w * 0.50, h * 0.10), 3.5, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) {
    return oldDelegate.stage != stage;
  }
}
