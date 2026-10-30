import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/medicine_log.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/glass_container.dart';

class HistoryCalendarScreen extends StatefulWidget {
  const HistoryCalendarScreen({super.key});

  @override
  State<HistoryCalendarScreen> createState() => _HistoryCalendarScreenState();
}

class _HistoryCalendarScreenState extends State<HistoryCalendarScreen> {
  final StorageService _storage = StorageService();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Summary calculations
    final allLogs = _storage.logs;
    final totalTaken = allLogs.where((l) => l.isTaken).length;
    final totalMissed = allLogs.where((l) => l.isMissed).length;
    final totalScheduled = totalTaken + totalMissed;
    final adherenceRate = totalScheduled > 0
        ? ((totalTaken / totalScheduled) * 100).round()
        : 100;
    final streak = _storage.calculateStreak();

    // Logs for selected date
    final selectedLogs = allLogs.where((l) =>
        l.scheduledTime.year == _selectedDate.year &&
        l.scheduledTime.month == _selectedDate.month &&
        l.scheduledTime.day == _selectedDate.day).toList();

    selectedLogs.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'History & Streak',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.deepPlum,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // Stat Cards Row
          Row(
            children: [
              // Streak Stat
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department, color: Color(0xFFFF6B6B), size: 28),
                      const SizedBox(height: 6),
                      Text(
                        '$streak Days',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.deepPlum,
                        ),
                      ),
                      Text(
                        'Loving Streak',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Adherence Stat
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.statusTaken, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        '$adherenceRate%',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.deepPlum,
                        ),
                      ),
                      Text(
                        'Adherence',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Total Taken Stat
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.crimsonLove, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        '$totalTaken',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.deepPlum,
                        ),
                      ),
                      Text(
                        'Total Taken',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Weekly Calendar Strip (Last 14 Days)
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Past 14 Days History',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepPlum,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLegendDot(AppColors.statusTaken, 'Taken'),
                        const SizedBox(width: 8),
                        _buildLegendDot(AppColors.statusMissed, 'Missed'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Horizontal scrollable days
                SizedBox(
                  height: 84,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Show recent days on start
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      final dayDate = now.subtract(Duration(days: index));
                      final normalized = DateTime(dayDate.year, dayDate.month, dayDate.day);
                      final isSelected = normalized == _selectedDate;

                      // Check day status
                      final dayLogs = allLogs.where((l) =>
                          l.scheduledTime.year == normalized.year &&
                          l.scheduledTime.month == normalized.month &&
                          l.scheduledTime.day == normalized.day).toList();

                      Color statusDotColor = Colors.transparent;
                      if (dayLogs.isNotEmpty) {
                        if (dayLogs.any((l) => l.isMissed)) {
                          statusDotColor = AppColors.statusMissed;
                        } else if (dayLogs.every((l) => l.isTaken)) {
                          statusDotColor = AppColors.statusTaken;
                        } else {
                          statusDotColor = AppColors.statusSnoozed;
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = normalized;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.heartButtonGradient : null,
                            color: isSelected
                                ? null
                                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(normalized),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : AppColors.deepPlum),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${normalized.day}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : AppColors.deepPlum),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusDotColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Selected Day Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('d MMMM yyyy').format(_selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.deepPlum,
                ),
              ),
              Text(
                '${selectedLogs.length} records',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Log timeline for selected date
          if (selectedLogs.isEmpty) ...[
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.event_note_rounded, color: AppColors.lavender, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'No Reminders Logged',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepPlum,
                      ),
                    ),
                    Text(
                      'No reminder activity logged for this date.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...selectedLogs.map((log) {
              final isTaken = log.isTaken;
              final isMissed = log.isMissed;

              return GlassContainer(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (isTaken
                                ? AppColors.statusTaken
                                : isMissed
                                    ? AppColors.statusMissed
                                    : AppColors.statusSnoozed)
                            .withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isTaken
                              ? Icons.check_circle_rounded
                              : isMissed
                                  ? Icons.cancel_rounded
                                  : Icons.snooze_rounded,
                          color: isTaken
                              ? AppColors.statusTaken
                              : isMissed
                                  ? AppColors.statusMissed
                                  : AppColors.statusSnoozed,
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Log Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.medicineName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.deepPlum,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Scheduled: ${DateFormat('hh:mm a').format(log.scheduledTime)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF6E5675),
                            ),
                          ),
                          if (log.actionTime != null)
                            Text(
                              'Taken at: ${DateFormat('hh:mm a').format(log.actionTime!)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.statusTaken,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Status Text Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isTaken
                                ? AppColors.statusTaken
                                : isMissed
                                    ? AppColors.statusMissed
                                    : AppColors.statusSnoozed)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isTaken
                            ? 'Taken ✅'
                            : isMissed
                                ? 'Missed ⚠️'
                                : 'Snoozed ⏳',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isTaken
                              ? AppColors.statusTaken
                              : isMissed
                                  ? AppColors.statusMissed
                                  : AppColors.statusSnoozed,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

