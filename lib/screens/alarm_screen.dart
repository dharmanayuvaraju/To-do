import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../utils/app_colors.dart';
import '../utils/date_utils.dart';
import '../widgets/slide_to_confirm.dart';
import '../widgets/floating_hearts_overlay.dart';

class AlarmScreen extends StatefulWidget {
  final String medicineId;
  final String medicineName;
  final String dose;
  final String doseUnit;
  final String note;
  final String quoteTelugu;
  final DateTime scheduledTime;

  const AlarmScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
    required this.dose,
    required this.doseUnit,
    required this.note,
    required this.quoteTelugu,
    required this.scheduledTime,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final StorageService _storage = StorageService();
  bool _isActionTaken = false;

  @override
  void initState() {
    super.initState();
    _startAlertEffects();
  }

  void _startAlertEffects() async {
    // Gentle vibration pattern if enabled
    if (_storage.isVibrationEnabled) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(
          pattern: [500, 1000, 500, 1000, 500, 1000],
          intensities: [128, 255, 128, 255, 128, 255],
        );
      }
    }
  }

  void _stopAlertEffects() {
    Vibration.cancel();
  }

  @override
  void dispose() {
    _stopAlertEffects();
    super.dispose();
  }

  void _onTaken() async {
    if (_isActionTaken) return;
    _isActionTaken = true;
    _stopAlertEffects();

    await _storage.markAsTaken(
      medicineId: widget.medicineId,
      medicineName: widget.medicineName,
      scheduledTime: widget.scheduledTime,
    );

    // Cancel repeating notification cascade
    await NotificationService().cancelMedicineReminders(widget.medicineId);
    await AlarmService().syncAndRescheduleAll();

    if (mounted) {
      FloatingHeartsOverlay.show(
        context,
        customTitle: '${_storage.herName} బంగారం... ఐ లవ్ యు! ❤️',
        customMessage: '${widget.medicineName.split('/')[0]} వేసుకున్నావ్ 💕\nచాలా మంచి పని చేసావు!',
      );

      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) Navigator.pop(context);
    }
  }

  void _onSnooze() async {
    if (_isActionTaken) return;
    _isActionTaken = true;
    _stopAlertEffects();

    await _storage.markAsSnoozed(
      medicineId: widget.medicineId,
      medicineName: widget.medicineName,
      scheduledTime: widget.scheduledTime,
    );

    await NotificationService().scheduleSnoozeNotification(
      medicineId: widget.medicineId,
      medicineName: widget.medicineName,
      scheduledTime: widget.scheduledTime,
      snoozeMinutes: _storage.snoozeDurationMinutes,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.deepPlum,
          content: Text(
            '${_storage.snoozeDurationMinutes} నిమిషాల తర్వాత మళ్లీ గుర్తుచేస్తాను బంగారం! ⏳',
            style: GoogleFonts.notoSansTelugu(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final useNature = _storage.photoStyle == 'nature' || _storage.lockScreenPrivacy;

    return Scaffold(
      body: Stack(
        children: [
          // Background (Discreet Serene Nature OR Couple Photo based on Privacy setting)
          Positioned.fill(
            child: useNature
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1E293B),
                          Color(0xFF334155),
                          Color(0xFF0F172A),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: 0.12,
                        child: const Icon(
                          Icons.spa_rounded,
                          size: 320,
                          color: AppColors.mintSuccess,
                        ),
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/hero_star.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/together.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/me.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),

          // Soft Romantic Gradient Overlay (Deep Plum & Blush Pink)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xCC3B2A4D),
                    const Color(0xEE1B1528),
                    AppColors.nightIndigo.withOpacity(0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section: Time & Pulse Alarm Bell
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.alarm_on_rounded, color: AppColors.blushPink, size: 18)
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .rotate(begin: -0.05, end: 0.05, duration: 200.ms),
                                const SizedBox(width: 8),
                                Text(
                                  AppDateUtils.formatTimeOfDay(
                                    TimeOfDay.fromDateTime(widget.scheduledTime),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Circular Photo Avatar (Nature or Couple)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: useNature ? AppColors.mintSuccess : AppColors.blushPink,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (useNature ? AppColors.mintSuccess : AppColors.roseGold).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: useNature
                              ? Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFA8E6CF), Color(0xFFCDB4F6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.spa_rounded, color: Colors.white, size: 50),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/hero_star.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset('assets/images/me.jpg', fit: BoxFit.cover),
                                ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1.5.seconds),
                      if (useNature) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.spa_rounded, size: 12, color: AppColors.mintSuccess),
                              const SizedBox(width: 4),
                              Text(
                                'Serene Nature Mode (Private)',
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Middle Section: Telugu Quote in Large Text + Medicine Info
                  Column(
                    children: [
                      // Large Telugu Quote
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.format_quote_rounded, color: AppColors.blushPink, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              widget.quoteTelugu,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansTelugu(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(),

                      const SizedBox(height: 24),

                      // Medicine Details Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.nightPlum.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lavender.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.medicineName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansTelugu(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blushPink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dose: ${widget.dose} ${widget.doseUnit}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            if (widget.note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.note,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.notoSansTelugu(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.softPeach,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Section: Slide-to-Take + Snooze Action + Message Babu
                  Column(
                    children: [
                      // Swipe right to confirm slider
                      SlideToConfirm(
                        onConfirmed: _onTaken,
                        text: 'Slide to take ❤️',
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // Snooze button
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _onSnooze,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.white.withOpacity(0.12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.snooze_rounded, color: AppColors.pastelYellow, size: 18),
                              label: Text(
                                'Snooze ${_storage.snoozeDurationMinutes}m ⏳',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Message Babu on WhatsApp
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                final phone = _storage.babuPhone;
                                final text = Uri.encodeComponent(
                                  "Hey Babu, I'm taking my medicine (${widget.medicineName}) right now! ❤️",
                                );
                                final url = phone.isNotEmpty
                                    ? "https://wa.me/$phone?text=$text"
                                    : "https://wa.me/?text=$text";
                                // Launch or share
                                Share.share(
                                  "Hey Babu, I got the reminder for ${widget.medicineName}! ❤️",
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: const Color(0xFF25D366).withOpacity(0.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 18),
                              label: Text(
                                'Tell Babu 💬',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

