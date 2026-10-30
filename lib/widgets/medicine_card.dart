import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import 'glass_container.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final TimeOfDay scheduledTime;
  final MedicineLog? log;
  final VoidCallback onTaken;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.scheduledTime,
    this.log,
    required this.onTaken,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTaken = log?.isTaken ?? false;
    final bool isMissed = log?.isMissed ?? false;
    final bool isSnoozed = log?.isSnoozed ?? false;

    final cardAccentColor = Color(medicine.colorValue);

    return GlassContainer(
      borderRadius: 28.0,
      padding: const EdgeInsets.all(18.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Time, Bouncing Pill Icon, Status Badge & Popup Menu
          Row(
            children: [
              // Bouncing Pill / Capsule Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardAccentColor.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cardAccentColor.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.crimsonLove,
                    size: 24,
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .moveY(
                        begin: 0,
                        end: -4,
                        duration: 1.2.seconds,
                        curve: Curves.easeInOut,
                      ),
                ),
              ),

              const SizedBox(width: 12),

              // Time Display & Status Chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppDateUtils.formatTimeOfDay(scheduledTime),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.deepPlum,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        if (isTaken)
                          _buildStatusBadge('Taken ✅', AppColors.mintSuccess, Colors.white)
                        else if (isMissed)
                          _buildStatusBadge('Missed ⚠️', AppColors.statusMissed, Colors.white)
                        else if (isSnoozed)
                          _buildStatusBadge('Snoozed ⏳', AppColors.statusSnoozed, Colors.white)
                        else
                          _buildStatusBadge('Pending 💕', cardAccentColor, AppColors.deepPlum),
                      ],
                    ),
                    Text(
                      '${medicine.dose} ${medicine.doseUnit}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                      ),
                    ),
                  ],
                ),
              ),

              // More Options menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white70 : AppColors.deepPlum.withOpacity(0.6),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reminder Name
          Text(
            medicine.name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.deepPlum,
            ),
          ),

          // Optional Loving Note
          if (medicine.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.favorite_outline_rounded,
                  size: 15,
                  color: AppColors.roseGold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    medicine.note,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.softPeach
                          : const Color(0xFF6B4E71),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Heart-shaped "Taken" Action Button
          Align(
            alignment: Alignment.centerRight,
            child: isTaken
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mintSuccess.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.mintSuccess),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.statusTaken, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Taken ✓',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.deepPlum,
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      onTaken();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.heartButtonGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7E9E).withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 20)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.25, 1.25),
                                duration: 800.ms,
                              ),
                          const SizedBox(width: 8),
                          Text(
                            'Taken ❤️',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

