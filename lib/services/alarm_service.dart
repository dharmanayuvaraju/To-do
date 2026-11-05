import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();

  /// Initialize and reschedule all upcoming recurring alarms for active medicines
  Future<void> syncAndRescheduleAll() async {
    await _notificationService.cancelAll();

    // Check for any past doses today that were never taken (exceeded 60 mins) and mark them missed
    await _checkAndRecordMissedDoses();

    // Schedule permanent repeating alarms directly in Android AlarmManager
    final medicines = _storage.medicines.where((m) => m.isActive).toList();
    for (final med in medicines) {
      await _notificationService.scheduleRecurringMedicineAlarm(medicine: med);
    }
  }

  /// Check if earlier doses today were neither taken nor snoozed within 60 minutes
  Future<void> _checkAndRecordMissedDoses() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeMeds = _storage.medicines.where((m) => m.isActive).toList();

    for (final med in activeMeds) {
      if (med.isScheduledForDate(today)) {
        for (final time in med.times) {
          final scheduledDt = DateTime(today.year, today.month, today.day, time.hour, time.minute);
          // If scheduled time was more than 65 minutes ago
          if (now.difference(scheduledDt).inMinutes > 65) {
            final hasTaken = _storage.logs.any((l) =>
                l.medicineId == med.id &&
                l.status == 'taken' &&
                l.scheduledTime.year == today.year &&
                l.scheduledTime.month == today.month &&
                l.scheduledTime.day == today.day &&
                l.scheduledTime.hour == time.hour &&
                l.scheduledTime.minute == time.minute);

            final hasMissed = _storage.logs.any((l) =>
                l.medicineId == med.id &&
                l.status == 'missed' &&
                l.scheduledTime.year == today.year &&
                l.scheduledTime.month == today.month &&
                l.scheduledTime.day == today.day &&
                l.scheduledTime.hour == time.hour &&
                l.scheduledTime.minute == time.minute);

            if (!hasTaken && !hasMissed) {
              await _storage.markAsMissed(
                medicineId: med.id,
                medicineName: med.name,
                scheduledTime: scheduledDt,
              );
            }
          }
        }
      }
    }
  }
}
