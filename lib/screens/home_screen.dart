import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../models/telugu_quote.dart';
import '../services/storage_service.dart';
import '../services/quote_service.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import '../utils/battery_optimizer_helper.dart';
import '../utils/date_utils.dart';
import '../widgets/medicine_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/floating_hearts_overlay.dart';
import 'add_edit_medicine_screen.dart';
import 'alarm_screen.dart';
import 'history_calendar_screen.dart';
import 'message_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final StorageService _storage = StorageService();
  late TeluguQuote _currentQuote;
  int _currentIndex = 0;

  bool _hasCheckedPermissions = false;
  bool _isNotificationGranted = true;
  bool _isExactAlarmGranted = true;
  bool _isBatteryIgnored = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentQuote = QuoteService().getRandomQuote();
    _storage.addListener(_onStorageChange);

    // Initial check of permissions and schedule refresh
    _checkPermissions();

    // Listen for notification opens to show AlarmScreen if needed
    NotificationService().onNotificationOpened = (data) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlarmScreen(
              medicineId: data['medicineId'] ?? '',
              medicineName: data['medicineName'] ?? 'Medicine',
              dose: data['dose'] ?? '1',
              doseUnit: data['doseUnit'] ?? 'Tablet',
              note: data['note'] ?? '',
              quoteTelugu: data['quoteTelugu'] ?? _currentQuote.telugu,
              scheduledTime: data['scheduledTime'] != null
                  ? DateTime.tryParse(data['scheduledTime']) ?? DateTime.now()
                  : DateTime.now(),
            ),
          ),
        );
      }
    };

    // Listen for notification Snooze tap to show the required popup immediately
    NotificationService().onSnoozeOpened = (data) {
      if (mounted) {
        _showSnoozeAlertPopup(
          medicineId: data['medicineId'] ?? '',
          medicineName: data['medicineName'] ?? 'Medicine',
          scheduledTime: data['scheduledTime'] != null
              ? DateTime.tryParse(data['scheduledTime']) ?? DateTime.now()
              : DateTime.now(),
        );
      }
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _storage.reloadFromDisk();
      if (mounted) setState(() {});
      _checkPermissions();
      AlarmService().syncAndRescheduleAll();
    }
  }

  Future<void> _checkPermissions() async {
    final notif = await BatteryOptimizerHelper.isNotificationGranted();
    final alarm = await BatteryOptimizerHelper.isExactAlarmGranted();
    final battery = await BatteryOptimizerHelper.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _isNotificationGranted = notif;
        _isExactAlarmGranted = alarm;
        _isBatteryIgnored = battery;
        _hasCheckedPermissions = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _storage.removeListener(_onStorageChange);
    super.dispose();
  }

  void _onStorageChange() {
    if (mounted) setState(() {});
  }

  void _refreshQuote() {
    setState(() {
      _currentQuote = QuoteService().getRandomQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _buildHomeContent(isDark),
      const HistoryCalendarScreen(),
      const MessageScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.nightSkyGradient
              : AppColors.creamLavenderGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
                );
                if (result == true) {
                  await AlarmService().syncAndRescheduleAll();
                }
              },
              backgroundColor: isDark ? AppColors.lavender : AppColors.blushPink,
              elevation: 4,
              icon: Icon(
                Icons.add_rounded,
                color: isDark ? AppColors.nightIndigo : AppColors.deepPlum,
                size: 24,
              ),
              label: Text(
                'Add Reminder',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.nightIndigo : AppColors.deepPlum,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHomeContent(bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeMeds = _storage.medicines.where((m) => m.isActive).toList();

    // Today's scheduled medicines paired with scheduled time
    final List<_ScheduledSlot> todaySlots = [];
    for (final med in activeMeds) {
      if (med.isScheduledForDate(today)) {
        for (final time in med.times) {
          final slotDt = DateTime(today.year, today.month, today.day, time.hour, time.minute);
          final log = _storage.logs.firstWhere(
            (l) =>
                l.medicineId == med.id &&
                l.scheduledTime.year == today.year &&
                l.scheduledTime.month == today.month &&
                l.scheduledTime.day == today.day &&
                l.scheduledTime.hour == time.hour &&
                l.scheduledTime.minute == time.minute,
            orElse: () => MedicineLog(
              id: '',
              medicineId: med.id,
              medicineName: med.name,
              scheduledTime: slotDt,
              status: 'pending',
            ),
          );

          todaySlots.add(_ScheduledSlot(
            medicine: med,
            time: time,
            scheduledDateTime: slotDt,
            log: log.id.isNotEmpty ? log : null,
          ));
        }
      }
    }

    // Sort slots by time
    todaySlots.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));

    // Find next pending slot
    _ScheduledSlot? nextSlot;
    for (final slot in todaySlots) {
      if (slot.log == null || (!slot.log!.isTaken && !slot.log!.isMissed)) {
        if (slot.scheduledDateTime.isAfter(now.subtract(const Duration(minutes: 30)))) {
          nextSlot = slot;
          break;
        }
      }
    }
    // If none found for today, check first slot tomorrow
    if (nextSlot == null && todaySlots.isNotEmpty) {
      final pendingToday = todaySlots.where((s) => s.log == null || !s.log!.isTaken).toList();
      if (pendingToday.isNotEmpty) {
        nextSlot = pendingToday.first;
      }
    }

    final streak = _storage.calculateStreak();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with circular avatar of [MY NAME]
          _buildHeader(isDark),

          const SizedBox(height: 14),

          // Setup Banner if any permission or battery optimization needs fixing
          _buildSetupBanner(isDark),

          // Random Telugu Quote Card with photo preview & refresh
          _buildQuoteCard(isDark),

          const SizedBox(height: 16),

          // Senior Product UI: Sleek Daily Progress Hero Capsule
          _buildDailyHeroCapsule(isDark, todaySlots, nextSlot, streak),

          const SizedBox(height: 20),

          // Today's Reminders Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Today\'s Schedule',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.deepPlum,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${todaySlots.where((s) => s.log?.isTaken ?? false).length}/${todaySlots.length} Done',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditMedicineScreen(),
                    ),
                  );
                  if (result == true) {
                    await AlarmService().syncAndRescheduleAll();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.heartButtonGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5277).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // List of Medicine Cards
          if (todaySlots.isEmpty) ...[
            GlassContainer(
              padding: const EdgeInsets.all(28.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.favorite_outline_rounded,
                        color: AppColors.roseGold, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No medicines scheduled for today',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rest well and stay hydrated 💕',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...todaySlots.map((slot) {
              return MedicineCard(
                medicine: slot.medicine,
                scheduledTime: slot.time,
                log: slot.log,
                onTaken: () async {
                  await _storage.markAsTaken(
                    medicineId: slot.medicine.id,
                    medicineName: slot.medicine.name,
                    scheduledTime: slot.scheduledDateTime,
                  );
                  await AlarmService().syncAndRescheduleAll();
                  if (context.mounted) {
                    FloatingHeartsOverlay.show(
                      context,
                      customTitle: 'Thank You ${_storage.herName}! ❤️',
                      customMessage:
                          '${slot.medicine.name} taken!\nLove from Babu 💕',
                    );
                  }
                },
                onEdit: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditMedicineScreen(medicine: slot.medicine),
                    ),
                  );
                  if (result == true) {
                    await AlarmService().syncAndRescheduleAll();
                  }
                },
                onDelete: () async {
                  await _storage.deleteMedicine(slot.medicine.id);
                  await NotificationService().cancelMedicineReminders(slot.medicine.id);
                  await AlarmService().syncAndRescheduleAll();
                },
              );
            }),
          ],

          const SizedBox(height: 80), // bottom padding for fab
        ],
      ),
    );
  }

  Widget _buildDailyHeroCapsule(bool isDark, List<_ScheduledSlot> todaySlots, _ScheduledSlot? nextSlot, int streak) {
    final takenCount = todaySlots.where((s) => s.log?.isTaken ?? false).length;
    final totalCount = todaySlots.length;
    final double percent = totalCount == 0 ? 1.0 : (takenCount / totalCount).clamp(0.0, 1.0);
    final bool allDone = totalCount > 0 && takenCount == totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1728).withOpacity(0.92) : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF3B2A4D) : const Color(0xFFF0E5DE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : const Color(0xFFE8D7D0).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Sleek Circular Progress Ring
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 7,
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF3E8FF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        allDone ? const Color(0xFF10B981) : const Color(0xFFFF5277),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$takenCount/$totalCount',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.deepPlum,
                          ),
                        ),
                        Text(
                          '${(percent * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: allDone ? const Color(0xFF10B981) : const Color(0xFFFF5277),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // Right Info: Next reminder & streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          allDone ? 'ALL COMPLETED! 🎉' : 'NEXT REMINDER',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: allDone ? const Color(0xFF10B981) : const Color(0xFFFF5277),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3B0).withOpacity(isDark ? 0.2 : 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 3),
                              Text(
                                '$streak Days',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFFF3B0) : const Color(0xFF8C5800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    if (nextSlot != null) ...[
                      Text(
                        AppDateUtils.formatTimeOfDay(nextSlot.time),
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.deepPlum,
                        ),
                      ),
                      Text(
                        nextSlot.medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.lavender : const Color(0xFF6B5F79),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Rest well Papa 💕',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.deepPlum,
                        ),
                      ),
                      Text(
                        'All medicines taken today. Babu loves you!',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? AppColors.lavender : const Color(0xFF6B5F79),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (nextSlot != null) ...[
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlarmScreen(
                      medicineId: nextSlot.medicine.id,
                      medicineName: nextSlot.medicine.name,
                      dose: nextSlot.medicine.dose,
                      doseUnit: nextSlot.medicine.doseUnit,
                      note: nextSlot.medicine.note,
                      quoteTelugu: _currentQuote.telugu,
                      scheduledTime: nextSlot.scheduledDateTime,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF9F5F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFFFF5277)),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to preview lock-screen alert',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.deepPlum,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Hero Star Avatar of [MY NAME] with Glowing Ring
        GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 2; // Jump to Message Screen
            });
          },
          child: Stack(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.blushPink,
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.roseGold.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _storage.photoStyle == 'nature'
                      ? Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFA8E6CF), Color(0xFFCDB4F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.spa_rounded, color: Colors.white, size: 34),
                          ),
                        )
                      : Image.asset(
                          'assets/images/hero_star.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset('assets/images/me.jpg', fit: BoxFit.cover),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    gradient: AppColors.heartButtonGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // Greeting and Her Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Love from Babu ❤️',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.blushPink : AppColors.deepPlum,
                ),
              ),
              Text(
                'Hi ${_storage.herName} 👋',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                ),
              ),
            ],
          ),
        ),

        // Quick test alarm button
        IconButton(
          tooltip: 'Test Alarm Sound & Notification',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lavender.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: isDark ? AppColors.blushPink : AppColors.deepPlum,
              size: 20,
            ),
          ),
          onPressed: () async {
            await NotificationService().triggerTestAlarm();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.deepPlum,
                  content: Text(
                    'Test alarm will ring in 4 seconds! 🔔',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuoteCard(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blushPink.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: AppColors.crimsonLove,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentQuote.telugu,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: isDark ? Colors.white : AppColors.deepPlum,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentQuote.english,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.lavender : const Color(0xFF7A6A8D),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: isDark ? AppColors.lavender : AppColors.deepPlum.withOpacity(0.6),
            onPressed: _refreshQuote,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupBanner(bool isDark) {
    final allGood = _isNotificationGranted && _isExactAlarmGranted && _isBatteryIgnored;
    if (allGood && _hasCheckedPermissions) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF33202C) : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.blushPink.withOpacity(0.5) : const Color(0xFFFFC107),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Alarm Setup Needed',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF856404),
                  ),
                ),
                Text(
                  'Fix permissions so daily reminders ring on time without fail.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : const Color(0xFF856404),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blushPink,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            onPressed: () => _showSetupDialog(context),
            child: Text(
              'Fix ⚙️',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.deepPlum,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String title,
    required bool isGranted,
    required VoidCallback onFix,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        if (isGranted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.mintSuccess.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Allowed ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mintSuccess)),
          )
        else
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: AppColors.blushPink.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onFix,
            child: const Text('Enable ⚠️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deepPlum)),
          ),
      ],
    );
  }

  void _showSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: isDark ? AppColors.nightIndigo : AppColors.cream,
            title: Row(
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Alarm Setup Guide',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.deepPlum,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'To ensure daily alarms ring without fail on her phone even in deep sleep or after restart, please check these 3 items:',
                    style: GoogleFonts.poppins(fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 12),

                  // 1. Notification Permission Status
                  _buildStatusRow(
                    title: '1. Notifications',
                    isGranted: _isNotificationGranted,
                    onFix: () async {
                      await BatteryOptimizerHelper.requestNotificationPermissions();
                      await _checkPermissions();
                      setDialogState(() {});
                    },
                  ),

                  const SizedBox(height: 8),

                  // 2. Exact Alarm Permission Status
                  _buildStatusRow(
                    title: '2. Exact Alarms',
                    isGranted: _isExactAlarmGranted,
                    onFix: () async {
                      await BatteryOptimizerHelper.requestExactAlarmPermission();
                      await _checkPermissions();
                      setDialogState(() {});
                    },
                  ),

                  const SizedBox(height: 8),

                  // 3. Battery Optimization Status
                  _buildStatusRow(
                    title: '3. Battery Optimization',
                    isGranted: _isBatteryIgnored,
                    onFix: () async {
                      await BatteryOptimizerHelper.requestIgnoreBatteryOptimizations();
                      await _checkPermissions();
                      setDialogState(() {});
                    },
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),

                  // Phone-Specific Brand Instructions
                  Text(
                    'Her Phone Settings (Click to expand):',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ...BatteryOptimizerHelper.brandGuides.entries.map((entry) {
                    final isHighlight = entry.key.contains('Vivo') || entry.key.contains('Samsung');
                    return ExpansionTile(
                      initiallyExpanded: isHighlight,
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isHighlight ? const Color(0xFFE85A88) : null,
                        ),
                      ),
                      children: entry.value
                          .map((step) => Padding(
                                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
                                child: Text(step, style: const TextStyle(fontSize: 11)),
                              ))
                          .toList(),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await BatteryOptimizerHelper.openAppSystemSettings();
                },
                child: const Text('Open App Info'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blushPink),
                icon: const Icon(Icons.alarm_on_rounded, size: 16, color: AppColors.deepPlum),
                label: Text(
                  'Test (5s)',
                  style: GoogleFonts.poppins(color: AppColors.deepPlum, fontWeight: FontWeight.bold, fontSize: 11),
                ),
                onPressed: () async {
                  await NotificationService().triggerTestAlarm();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test alarm will ring in 4 seconds! Lock screen now to test! 🔒🔔'),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnoozeAlertPopup({
    required String medicineId,
    required String medicineName,
    required DateTime scheduledTime,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1E1728),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😠', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(
              'musukoni mundu vesuko!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFFFF7E9E),
              ),
            ),
            const SizedBox(width: 8),
            const Text('❤️', style: TextStyle(fontSize: 22)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'mundu medicine vesuko tharuvtha work chesko!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Chalu inka snooze chesindi bangaram! Ippude $medicineName vesukunte Babu chala happy ga feel avthadu ❤️',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final now = DateTime.now();
              final todaySlot = DateTime(
                now.year,
                now.month,
                now.day,
                scheduledTime.hour,
                scheduledTime.minute,
              );
              await _storage.markAsSnoozed(
                medicineId: medicineId,
                medicineName: medicineName,
                scheduledTime: todaySlot,
              );
              await NotificationService().cancelTodayCascades(medicineId, todaySlot);
              await NotificationService().scheduleSnoozeNotification(
                medicineId: medicineId,
                medicineName: medicineName,
                scheduledTime: todaySlot,
                snoozeMinutes: _storage.snoozeDurationMinutes,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF2A1D36),
                    content: Text(
                      'musukoni mundu vesuko! (${_storage.snoozeDurationMinutes}m tharvatha malli alert avthundi ⏳)',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Snooze ${_storage.snoozeDurationMinutes}m ⏳',
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5277),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final now = DateTime.now();
              final todaySlot = DateTime(
                now.year,
                now.month,
                now.day,
                scheduledTime.hour,
                scheduledTime.minute,
              );
              await _storage.markAsTaken(
                medicineId: medicineId,
                medicineName: medicineName,
                scheduledTime: todaySlot,
              );
              await NotificationService().cancelMedicineReminders(medicineId);
              await AlarmService().syncAndRescheduleAll();
              if (mounted) {
                FloatingHeartsOverlay.show(
                  context,
                  customTitle: 'Very good Papa! ❤️',
                  customMessage: '$medicineName vesukunnav 💕\nLove from Babu!',
                );
              }
            },
            child: Text(
              'Ippude Vesukunta! ❤️',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightPlum : Colors.white.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: isDark ? AppColors.blushPink : const Color(0xFFE85A88),
        unselectedItemColor: isDark ? Colors.white54 : const Color(0xFF9E8FB2),
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Love Note',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _ScheduledSlot {
  final Medicine medicine;
  final TimeOfDay time;
  final DateTime scheduledDateTime;
  final MedicineLog? log;

  _ScheduledSlot({
    required this.medicine,
    required this.time,
    required this.scheduledDateTime,
    this.log,
  });
}

