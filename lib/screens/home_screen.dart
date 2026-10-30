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
import '../widgets/dial_clock_widget.dart';
import '../widgets/blooming_flower_widget.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  late TeluguQuote _currentQuote;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentQuote = QuoteService().getRandomQuote();
    _storage.addListener(_onStorageChange);

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
  }

  @override
  void dispose() {
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

          const SizedBox(height: 16),

          // Random Telugu Quote Card with photo preview & refresh
          _buildQuoteCard(isDark),

          const SizedBox(height: 20),

          // Big Glowing Moon-and-Sun Dial
          DialClockWidget(
            nextMedicine: nextSlot?.medicine,
            nextTime: nextSlot?.time,
            onTap: () {
              if (nextSlot != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlarmScreen(
                      medicineId: nextSlot!.medicine.id,
                      medicineName: nextSlot.medicine.name,
                      dose: nextSlot.medicine.dose,
                      doseUnit: nextSlot.medicine.doseUnit,
                      note: nextSlot.medicine.note,
                      quoteTelugu: _currentQuote.telugu,
                      scheduledTime: nextSlot.scheduledDateTime,
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // Blooming Flower Streak Widget
          BloomingFlowerWidget(streakDays: streak),

          const SizedBox(height: 24),

          // Today's Medicines Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Medicines',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.deepPlum,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${todaySlots.where((s) => s.log?.isTaken ?? false).length}/${todaySlots.length} Taken',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.deepPlum,
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

