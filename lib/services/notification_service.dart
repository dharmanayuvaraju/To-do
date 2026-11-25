import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'quote_service.dart';
import 'partner_service.dart';

// Top-level background notification response handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  tz.initializeTimeZones();
  await handleNotificationAction(notificationResponse, isBackgroundIsolate: true);
}

Future<void> handleNotificationAction(
  NotificationResponse response, {
  bool isBackgroundIsolate = false,
}) async {
  final actionId = response.actionId;

  // Notification body tapped -> open app / alarm screen
  if (actionId == null || actionId.isEmpty) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = jsonDecode(response.payload!);
        NotificationService().onNotificationOpened?.call(data);
      } catch (_) {}
    }
    return;
  }

  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final String medicineId = data['medicineId'] ?? '';
    final String medicineName = data['medicineName'] ?? 'Tablet';
    final int baseId = data['baseId'] ?? (response.id != null ? (response.id! ~/ 10) * 10 : 0);
    final String scheduledIso = data['scheduledTime'] ?? '';
    final DateTime rawScheduled = scheduledIso.isNotEmpty
        ? (DateTime.tryParse(scheduledIso) ?? DateTime.now())
        : DateTime.now();

    final now = DateTime.now();
    final DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      rawScheduled.hour,
      rawScheduled.minute,
    );

    final storage = StorageService();
    await storage.init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final notifPlugin = NotificationService.plugin;

    if (actionId == 'taken' || actionId == AppConstants.actionTaken) {
      // 1. Mark as taken in storage
      await storage.markAsTaken(
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
      );

      // 2. Dismiss the notification that was tapped
      if (response.id != null) {
        await notifPlugin.cancel(response.id!);
      }

      // 3. Cancel deterministic baseId and all 6 repeats + snooze (baseId..baseId + 9)
      if (baseId > 0) {
        for (int i = 0; i <= 9; i++) {
          await notifPlugin.cancel(baseId + i);
        }
      }
      await NotificationService().cancelTodayCascades(medicineId, scheduledTime);

      // 4. Partner Alert: Send push to his phone
      if (isBackgroundIsolate) {
        await PartnerService.sendEvent(
          'taken',
          med: medicineName,
          medId: medicineId,
          scheduledTime: scheduledTime,
        ).timeout(const Duration(seconds: 6), onTimeout: () {});
      } else {
        unawaited(PartnerService.sendEvent(
          'taken',
          med: medicineName,
          medId: medicineId,
          scheduledTime: scheduledTime,
        ));
      }
    } else if (actionId == 'snooze' || actionId == AppConstants.actionSnooze) {
      // 1. Dismiss the current ringing notification
      if (response.id != null) {
        await notifPlugin.cancel(response.id!);
      }

      // 2. Mark as snoozed in storage
      await storage.markAsSnoozed(
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
      );

      // 3. Cancel today's remaining cascade nag alarms so they don't ring at the same time as snooze
      await NotificationService().cancelTodayCascades(medicineId, scheduledTime);

      // 4. Schedule one new snooze notification 10 minutes from now
      await NotificationService().scheduleSnoozeNotification(
        medicineId: medicineId,
        medicineName: medicineName,
        scheduledTime: scheduledTime,
        snoozeMinutes: storage.snoozeDurationMinutes,
      );

      // 5. Partner Alert: send snooze event
      if (isBackgroundIsolate) {
        await PartnerService.sendEvent(
          'snooze',
          med: medicineName,
          medId: medicineId,
          scheduledTime: scheduledTime,
        ).timeout(const Duration(seconds: 6), onTimeout: () {});
      } else {
        unawaited(PartnerService.sendEvent(
          'snooze',
          med: medicineName,
          medId: medicineId,
          scheduledTime: scheduledTime,
        ));
      }
    }
  } catch (e) {
    debugPrint('Error handling notification action: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// ONE singleton FlutterLocalNotificationsPlugin instance, used everywhere
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Callback when user taps notification body to open UI
  Function(Map<String, dynamic>)? onNotificationOpened;

  // Callback when user taps snooze action
  Function(Map<String, dynamic>)? onSnoozeOpened;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

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

    await plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await handleNotificationAction(response, isBackgroundIsolate: false);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createNotificationChannels();

    _isInitialized = true;
  }

  Future<void> _createNotificationChannels() async {
    // Primary Alarm Channel
    const androidAlarmChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_chime'),
      enableVibration: true,
      showBadge: true,
    );

    // Partner Alert Push Channel (for His phone)
    const partnerAlertChannel = AndroidNotificationChannel(
      'partner_alerts',
      'Partner alerts',
      description: 'Alerts when partner takes or snoozes medicine',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidAlarmChannel);
      await androidPlugin.createNotificationChannel(partnerAlertChannel);
    }
  }

  /// Deterministic ID generator: base = medicineId * 1000 + dayIndex * 100 + slot
  static int getBaseId(String medicineId, int dayIndex, int hour, int minute) {
    int hash = medicineId.hashCode.abs() % 10000;
    return (hash * 1000 + (dayIndex % 10) * 100 + ((hour * 60 + minute) % 100) * 10) % 100000000;
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

  /// Schedule recurring medicine alarms with deterministic IDs
  Future<void> scheduleRecurringMedicineAlarm({
    required Medicine medicine,
  }) async {
    if (!medicine.isActive) return;

    final isEveryday = medicine.daysOfWeek.isEmpty || medicine.daysOfWeek.length == 7;

    for (final time in medicine.times) {
      if (isEveryday) {
        final tz.TZDateTime nextTime = _nextInstanceOfTime(time);
        final int baseId = getBaseId(medicine.id, 0, time.hour, time.minute);

        await _scheduleSingleZoned(
          id: baseId,
          baseId: baseId,
          title: '❤️ Reminder Time Bangaram! ❤️',
          body: '${medicine.name} (${medicine.dose} ${medicine.doseUnit})',
          scheduledDate: nextTime,
          matchDateTimeComponents: DateTimeComponents.time,
          medicine: medicine,
          scheduledTime: nextTime,
        );

        // 6 repeat reminders (every 10 minutes) with deterministic IDs: baseId + 1..6
        for (int repeat = 1; repeat <= 6; repeat++) {
          final tz.TZDateTime repeatTime = nextTime.add(Duration(minutes: 10 * repeat));
          final int repeatId = baseId + repeat;
          final isFinalRepeat = repeat == 6;
          final repeatTitle = isFinalRepeat
              ? '⚠️ Please Bangaram... Time for your reminder ❤️'
              : '🔔 Reminder #$repeat: Reminder time bangaram! ❤️';

          await _scheduleSingleZoned(
            id: repeatId,
            baseId: baseId,
            title: repeatTitle,
            body: '${medicine.name} (${medicine.dose} ${medicine.doseUnit})\nPlease do not miss this!',
            scheduledDate: repeatTime,
            matchDateTimeComponents: null,
            medicine: medicine,
            scheduledTime: nextTime,
          );
        }
      } else {
        for (final dayOfWeek in medicine.daysOfWeek) {
          final tz.TZDateTime nextDayTime = _nextInstanceOfDayAndTime(dayOfWeek, time);
          final int baseId = getBaseId(medicine.id, dayOfWeek, time.hour, time.minute);

          await _scheduleSingleZoned(
            id: baseId,
            baseId: baseId,
            title: '❤️ Reminder Time Bangaram! ❤️',
            body: '${medicine.name} (${medicine.dose} ${medicine.doseUnit})',
            scheduledDate: nextDayTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            medicine: medicine,
            scheduledTime: nextDayTime,
          );

          for (int repeat = 1; repeat <= 6; repeat++) {
            final tz.TZDateTime repeatTime = nextDayTime.add(Duration(minutes: 10 * repeat));
            final int repeatId = baseId + repeat;
            final isFinalRepeat = repeat == 6;
            final repeatTitle = isFinalRepeat
                ? '⚠️ Please Bangaram... Time for your reminder ❤️'
                : '🔔 Reminder #$repeat: Reminder time bangaram! ❤️';

            await _scheduleSingleZoned(
              id: repeatId,
              baseId: baseId,
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

  Future<void> _scheduleSingleZoned({
    required int id,
    required int baseId,
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
      'baseId': baseId,
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
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'taken',
          'Taken',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze 10m',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    try {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (_) {
      try {
        await plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } catch (_) {}
    }
  }

  /// Schedule 10-minute snooze notification
  Future<void> scheduleSnoozeNotification({
    required String medicineId,
    required String medicineName,
    required DateTime scheduledTime,
    int snoozeMinutes = 10,
  }) async {
    final baseId = getBaseId(medicineId, 0, scheduledTime.hour, scheduledTime.minute);
    final snoozeId = baseId + 9;
    final snoozeTarget = tz.TZDateTime.now(tz.local).add(Duration(minutes: snoozeMinutes));

    final payload = jsonEncode({
      'medicineId': medicineId,
      'medicineName': medicineName,
      'baseId': baseId,
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
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'taken',
          'Taken',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    await plugin.zonedSchedule(
      snoozeId,
      '😠❤️ musukoni mundu vesuko!',
      'mundu medicine vesuko tharuvtha work chesko! Ippude $medicineName vesuko bangaram ❤️',
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
    for (int day = 0; day <= 7; day++) {
      for (int slot = 0; slot <= 24; slot++) {
        final base = getBaseId(medicineId, day, slot, 0);
        for (int i = 0; i <= 9; i++) {
          await plugin.cancel(base + i);
        }
      }
    }
  }

  /// Cancel remaining cascade nag reminders for today's dose
  Future<void> cancelTodayCascades(String medicineId, DateTime scheduledTime) async {
    final weekdayBase = getBaseId(medicineId, scheduledTime.weekday, scheduledTime.hour, scheduledTime.minute);
    final everydayBase = getBaseId(medicineId, 0, scheduledTime.hour, scheduledTime.minute);

    for (int i = 0; i <= 9; i++) {
      await plugin.cancel(weekdayBase + i);
      await plugin.cancel(everydayBase + i);
    }
  }

  /// On app start and after every Taken, re-sync: cancel all repeats for doses already taken today
  Future<void> resyncTodayAlarms() async {
    try {
      final storage = StorageService();
      await storage.init();
      final todayLogs = storage.todayLogs;
      for (final log in todayLogs) {
        if (log.isTaken) {
          await cancelTodayCascades(log.medicineId, log.scheduledTime);
        }
      }
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  /// Instant test alarm trigger
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
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'taken',
          'Taken',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'snooze',
          'Snooze 10m',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    await plugin.zonedSchedule(
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
        'baseId': 999990,
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
