import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';

class DialClockWidget extends StatelessWidget {
  final Medicine? nextMedicine;
  final TimeOfDay? nextTime;
  final VoidCallback? onTap;

  const DialClockWidget({
    super.key,
    this.nextMedicine,
    this.nextTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    DateTime? targetDateTime;
    int remainingMinutes = 0;
    double progress = 1.0;

    if (nextMedicine != null && nextTime != null) {
      targetDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        nextTime!.hour,
        nextTime!.minute,
      );

      // If already passed today, assume next occurrence is tomorrow
      if (targetDateTime.isBefore(now)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }

      remainingMinutes = targetDateTime.difference(now).inMinutes;
      // Progress over a 12 hour span (720 min)
      progress = (remainingMinutes / 720.0).clamp(0.05, 1.0);
    }

    final bool isNight = nextTime != null
        ? (nextTime!.hour < 6 || nextTime!.hour >= 18)
        : (now.hour < 6 || now.hour >= 18);

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Soft Ambient Glow
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isNight
                          ? AppColors.lavender.withOpacity(0.35)
                          : AppColors.softPeach.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // Animated Circular Countdown Arc
              CustomPaint(
                size: const Size(230, 230),
                painter: _DialProgressPainter(
                  progress: 1.0 - progress,
                  isNight: isNight,
                  isDark: isDark,
                ),
              ),

              // Inner Frosted Core
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isNight
                        ? [
                            const Color(0xFF2E2042).withOpacity(0.95),
                            const Color(0xFF1B1528).withOpacity(0.95),
                          ]
                        : [
                            Colors.white.withOpacity(0.95),
                            const Color(0xFFFFF0F5).withOpacity(0.9),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isNight
                        ? AppColors.lavender.withOpacity(0.4)
                        : AppColors.blushPink.withOpacity(0.6),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sun or Moon celestial icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            color: isNight
                                ? AppColors.pastelYellow
                                : const Color(0xFFFFB03B),
                            size: 26,
                          )
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.15, 1.15),
                                duration: 2.seconds,
                              ),
                          const SizedBox(width: 6),
                          Text(
                            isNight ? 'Night' : 'Day',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isNight
                                  ? AppColors.lavender
                                  : AppColors.deepPlum.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Next Medicine Name or All Done
                      if (nextMedicine != null && nextTime != null) ...[
                        Text(
                          nextMedicine!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isNight ? Colors.white : AppColors.deepPlum,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppDateUtils.formatTimeOfDay(nextTime!),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isNight
                                ? AppColors.blushPink
                                : const Color(0xFFD64070),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainingMinutes <= 0
                              ? 'Due Now!'
                              : remainingMinutes < 60
                                  ? 'Due in ${remainingMinutes}m'
                                  : 'Due in ${(remainingMinutes / 60).toStringAsFixed(1)}h',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusTaken,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.roseGold,
                          size: 32,
                        )
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.2, 1.2),
                              duration: 1.5.seconds,
                            ),
                        const SizedBox(height: 6),
                        Text(
                          'All Taken Today!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isNight ? Colors.white : AppColors.deepPlum,
                          ),
                        ),
                        Text(
                          'Love from Babu ❤️',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isNight ? AppColors.lavender : AppColors.deepPlum,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialProgressPainter extends CustomPainter {
  final double progress;
  final bool isNight;
  final bool isDark;

  _DialProgressPainter({
    required this.progress,
    required this.isNight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background track ring
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.08)
          : AppColors.lavender.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(center, radius, bgPaint);

    // Glowing active progress arc
    final gradient = isNight
        ? const SweepGradient(
            colors: [
              AppColors.lavender,
              AppColors.blushPink,
              AppColors.pastelYellow,
              AppColors.lavender,
            ],
            startAngle: -pi / 2,
            endAngle: 3 * pi / 2,
          )
        : const SweepGradient(
            colors: [
              AppColors.blushPink,
              Color(0xFFFFB03B),
              Color(0xFFE85A88),
              AppColors.blushPink,
            ],
            startAngle: -pi / 2,
            endAngle: 3 * pi / 2,
          );

    final sweepAngle = 2 * pi * progress.clamp(0.02, 1.0);

    final activePaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isNight != isNight ||
        oldDelegate.isDark != isDark;
  }
}
