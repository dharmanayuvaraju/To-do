import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/medicine.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'quote_service.dart';

// Top-level background notification response handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Notification background tap action: ${notificationResponse.actionId}');
  _handleNotificationAction(notificationResponse);
}

void _handleNotificationAction(NotificationResponse response) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final String medicineId = data['medicineId'] ?? '';
    final String medicineName = data['medicineName'] ?? '';
    final String scheduledIso = data['scheduledTime'] ?? '';
    final DateTime scheduledTime = scheduledIso.isNotEmpty
        ? DateTime.parse(scheduledIso)
        : DateTime.now();

    final storage = StorageService();
    await storage.init();

    if (response.actionId == AppConstants.actionTaken) {
      await storage.markAsTaken(
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
      );
      // Cancel remaining repeat cascade notifications for this dose today
      final notifPlugin = FlutterLocalNotificationsPlugin();
      for (int repeat = 1; repeat <= 6; repeat++) {
        final repeatOffset = repeat * 10;
        final weekdayId = NotificationService.getNotificationId(
          medicineId,
          scheduledTime.weekday,
          scheduledTime.hour,
          scheduledTime.minute,
          repeatOffset,
        );
        final everydayId = NotificationService.getNotificationId(
          medicineId,
          0,
          scheduledTime.hour,
          scheduledTime.minute,
          repeatOffset,
        );
        await notifPlugin.cancel(weekdayId);
        await notifPlugin.cancel(everydayId);
      }
    } else if (response.actionId == AppConstants.actionSnooze) {
      await storage.markAsSnoozed(
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
      );
      // Schedule immediate snooze for 10 minutes later
      final notifService = NotificationService();
      await notifService.scheduleSnoozeNotification(
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        snoozeMinutes: storage.snoozeDurationMinutes,
      );
    }
  } catch (e) {
    debugPrint('Error handling notification action: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Callback when user taps notification or action to open UI
  Function(Map<String, dynamic>)? onNotificationOpened;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Timezone database
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Safe fallback
    }

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    // iOS/macOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationAction(response);
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);
            onNotificationOpened?.call(data);
          } catch (_) {}
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create High-Priority Notification Channel for Android
    await _createNotificationChannel();

    _isInitialized = true;
  }

  Future<void> _createNotificationChannel() async {
    final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);

    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_chime'),
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Deterministic, 100% collision-free notification ID generator
  static int getNotificationId(String medicineId, int dayOfWeek, int hour, int minute, [int repeatOffsetMinutes = 0]) {
    int hash = medicineId.hashCode & 0x0FFFFFFF;
    hash = (hash * 31 + (dayOfWeek * 1440 + hour * 60 + minute + repeatOffsetMinutes)) & 0x7FFFFFFF;
    return hash % 100000000;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int weekday, TimeOfDay time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule permanent daily or weekly repeating alarms directly with Android OS
  Future<void> scheduleRecurringMedicineAlarm({
    required Medicine medicine,
  }) async {
    if (!medicine.isActive) return;

    final isEveryday = medicine.daysOfWeek.isEmpty || medicine.daysOfWeek.length == 7;

    for (final time in medicine.times) {
      if (isEveryday) {
        // Everyday repeating alarm (matchDateTimeComponents: DateTimeComponents.time)
        final tz.TZDateTime nextTime = _nextInstanceOfTime(time);
        final int primaryId = getNotificationId(medicine.id, 0, time.hour, time.minute, 0);

        await _scheduleSingleZoned(
          id: primaryId,
          title: '❤️ Reminder Time Bangaram! ❤️',
          body: '${medicine.name} (${medicine.dose} ${medicine.doseUnit})',
          scheduledDate: nextTime,
          matchDateTimeComponents: DateTimeComponents.time,
          medicine: medicine,
          scheduledTime: nextTime,
        );

        // 6 repeat reminders (every 10 minutes) with unique IDs
        for (int repeat = 1; repeat <= 6; repeat++) {
          final tz.TZDateTime repeatTime = nextTime.add(Duration(minutes: 10 * repeat));
          final int repeatId = getNotificationId(medicine.id, 0, time.hour, time.minute, repeat * 10);
          final isFinalRepeat = repeat == 6;
          final repeatTitle = isFinalRepeat
              ? '⚠️ Please Bangaram... Time for your reminder ❤️'
              : '🔔 Reminder #$repeat: Reminder time bangaram! ❤️';

          await _scheduleSingleZoned(
            id: repeatId,
            title: repeatTitle,
            body: '${medicine.name} (${medicine.dose} ${medicine.doseUnit})\nPlease do not miss this!',
            scheduledDate: repeatTime,
            matchDateTimeComponents: null,
            medicine: medicine,
            scheduledTime: nextTime,
          );
        }
      } else {
        // Specific days of week repeating alarm (matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime)
        for (final dayOfWeek in medicine.daysOfWeek) {
          final tz.TZDateTime nextDayTime = _nextInstanceOfDayAndTime(dayOfWeek, time);
          final int primaryId = getNotificationId(medicine.id, dayOfWeek, time.hour, time.minute, 0);

          await _scheduleSingleZoned(
            id: primaryId,
            title: '❤️ Reminder Time Bangaram! ❤️',
            body: '${medicine.name} (${medicine.dose} ${medicine.doseUnit})',
            scheduledDate: nextDayTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            medicine: medicine,
            scheduledTime: nextDayTime,
          );

          // 6 repeat reminders on that day
          for (int repeat = 1; repeat <= 6; repeat++) {
            final tz.TZDateTime repeatTime = nextDayTime.add(Duration(minutes: 10 * repeat));
            final int repeatId = getNotificationId(medicine.id, dayOfWeek, time.hour, time.minute, repeat * 10);
            final isFinalRepeat = repeat == 6;
            final repeatTitle = isFinalRepeat
                ? '⚠️ Please Bangaram... Time for your reminder ❤️'
                : '🔔 Reminder #$repeat: Reminder time bangaram! ❤️';

            await _scheduleSingleZoned(
              id: repeatId,
              title: repeatTitle,
              body: '${medicine.name} (${medicine.dose} ${medicine.doseUnit})\nPlease do not miss this!',
              scheduledDate: repeatTime,
              matchDateTimeComponents: null,
              medicine: medicine,
              scheduledTime: nextDayTime,
            );
          }
        }
      }
    }
  }

  /// Internal zoned scheduler with automatic exact-to-inexact fallback
  Future<void> _scheduleSingleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    required Medicine medicine,
    required DateTime scheduledTime,
  }) async {
    final quote = QuoteService().getRandomQuote();
    final payload = jsonEncode({
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'dose': medicine.dose,
      'doseUnit': medicine.doseUnit,
      'note': medicine.note,
      'quoteTelugu': quote.telugu,
      'quoteEnglish': quote.english,
      'scheduledTime': scheduledTime.toIso8601String(),
    });

    final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const RawResourceAndroidNotificationSound('alarm_chime'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      color: const Color(0xFFE85A88),
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification'),
      styleInformation: BigTextStyleInformation(
        '${quote.telugu}\n\n$body\n${medicine.note}',
        contentTitle: title,
        summaryText: 'Do It Now Care',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          AppConstants.actionTaken,
          'Taken ✅',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          AppConstants.actionSnooze,
          'Snooze 10m ⏳',
          showsUserInterface: false,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Exact alarm failed for ID $id ($e). Retrying with inexactAllowWhileIdle fallback.');
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } catch (e2) {
        debugPrint('Fallback alarm also failed for ID $id: $e2');
      }
    }
  }

  /// Backward-compatible single schedule method
  Future<void> scheduleMedicineAlarm({
    required Medicine medicine,
    required TimeOfDay time,
    required DateTime targetDate,
  }) async {
    await scheduleRecurringMedicineAlarm(medicine: medicine);
  }

  /// Schedule immediate snooze notification (e.g. 10 minutes from now)
  Future<void> scheduleSnoozeNotification({
    required String medicineId,
    required String medicineName,
    required DateTime scheduledTime,
    int snoozeMinutes = 10,
  }) async {
    final quote = QuoteService().getRandomQuote();
    final snoozeId = (medicineId.hashCode + 999).abs() % 100000000;
    final snoozeTarget = tz.TZDateTime.now(tz.local).add(Duration(minutes: snoozeMinutes));

    final payload = jsonEncode({
      'medicineId': medicineId,
      'medicineName': medicineName,
      'scheduledTime': scheduledTime.toIso8601String(),
    });

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const RawResourceAndroidNotificationSound('alarm_chime'),
      playSound: true,
      enableVibration: true,
      color: const Color(0xFFF3A638),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          AppConstants.actionTaken,
          'Taken ✅',
          showsUserInterface: true,
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      snoozeId,
      '😠❤️ musukoni mundu vesuko!',
      'Chalu inka snooze chesindi! Ippude $medicineName vesuko bangaram ❤️',
      snoozeTarget,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel all notifications for a specific medicine
  Future<void> cancelMedicineReminders(String medicineId) async {
    final baseId = medicineId.hashCode;
    for (int i = 0; i <= 7; i++) {
      await _notificationsPlugin.cancel((baseId + i).abs() % 100000000);
    }
    await _notificationsPlugin.cancel((baseId + 999).abs() % 100000000);
  }

  /// Cancel all scheduled notifications across entire app
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Instant test alarm trigger (for verifying sound, vibration & UI in 5 seconds)
  Future<void> triggerTestAlarm() async {
    final quote = QuoteService().getRandomQuote();
    final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 4));

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const RawResourceAndroidNotificationSound('alarm_chime'),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        '${quote.telugu}\n\nTest reminder! Notification, sound, and vibration are active ❤️',
        contentTitle: '❤️ Test Reminder',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          AppConstants.actionTaken,
          'Taken ✅',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          AppConstants.actionSnooze,
          'Snooze 10m ⏳',
          showsUserInterface: false,
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      999999,
      '❤️ Test Reminder',
      quote.telugu,
      testTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'medicineId': 'test_med',
        'medicineName': 'Test Reminder',
        'dose': '1',
        'doseUnit': 'Dose',
        'note': 'Test alarm ringing on schedule!',
        'quoteTelugu': quote.telugu,
        'quoteEnglish': quote.english,
        'scheduledTime': DateTime.now().toIso8601String(),
      }),
    );
  }
}
