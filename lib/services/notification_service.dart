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
      // Cancel remaining repeating notifications for this dose
      final notifPlugin = FlutterLocalNotificationsPlugin();
      final baseId = medicineId.hashCode;
      for (int i = 0; i <= 6; i++) {
        await notifPlugin.cancel((baseId + i).abs() % 100000000);
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

  /// Schedule alarm reminder with 6 repeat cascades
  Future<void> scheduleMedicineAlarm({
    required Medicine medicine,
    required TimeOfDay time,
    required DateTime targetDate,
  }) async {
    final quote = QuoteService().getRandomQuote();
    final baseId = medicine.id.hashCode;

    final scheduledDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      time.hour,
      time.minute,
    );

    // If the scheduled time is already in the past for today, don't schedule
    if (scheduledDateTime.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledDateTime, tz.local);

    final payload = jsonEncode({
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'dose': medicine.dose,
      'doseUnit': medicine.doseUnit,
      'note': medicine.note,
      'quoteTelugu': quote.telugu,
      'quoteEnglish': quote.english,
      'scheduledTime': scheduledDateTime.toIso8601String(),
    });

    final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const RawResourceAndroidNotificationSound('alarm_chime'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      color: const Color(0xFFF8C8DC),
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/ic_notification'),
      styleInformation: BigTextStyleInformation(
        '${quote.telugu}\n\n${medicine.name} (${medicine.dose} ${medicine.doseUnit})\n${medicine.note}',
        contentTitle: '❤️ మందుల సమయం అయింది బంగారం! / Medicine Time',
        summaryText: 'Do It Now Care',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          AppConstants.actionTaken,
          'Taken / తీసుకున్నాను ✅',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          AppConstants.actionSnooze,
          'Snooze 10m / 10 నిమిషాలు ఆపు ⏳',
          showsUserInterface: false,
        ),
      ],
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Schedule the primary alarm (repeat index 0)
    final notificationId = (baseId).abs() % 100000000;
    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '❤️ మందుల సమయం అయింది బంగారం!',
        '${quote.telugu}\n${medicine.name} (${medicine.dose} ${medicine.doseUnit})',
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling exact alarm: $e');
    }

    // Schedule 6 repeat reminders (every 10 minutes) in case she doesn't mark taken
    for (int repeat = 1; repeat <= 6; repeat++) {
      final repeatTime = tzScheduledTime.add(Duration(minutes: 10 * repeat));
      final repeatId = (baseId + repeat).abs() % 100000000;
      final repeatQuote = QuoteService().getRandomQuote();

      final isFinalRepeat = repeat == 6;
      final repeatTitle = isFinalRepeat
          ? '⚠️ ప్లీజ్ బంగారం... మందులు వేసుకో / Please Take Medicine'
          : '🔔 రిమైండర్ #${repeat}: మందులు వేసుకున్నావా బంగారం?';

      final repeatDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const RawResourceAndroidNotificationSound('alarm_chime'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        color: const Color(0xFFE85A88),
        styleInformation: BigTextStyleInformation(
          '${repeatQuote.telugu}\n\n${medicine.name} (${medicine.dose} ${medicine.doseUnit})\nఈ డోస్ మిస్ అవ్వద్దు!',
          contentTitle: repeatTitle,
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            AppConstants.actionTaken,
            'Taken / తీసుకున్నాను ✅',
            showsUserInterface: true,
          ),
          if (!isFinalRepeat)
            const AndroidNotificationAction(
              AppConstants.actionSnooze,
              'Snooze 10m / ఆపు ⏳',
              showsUserInterface: false,
            ),
        ],
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          repeatId,
          repeatTitle,
          '${repeatQuote.telugu}\n${medicine.name} (${medicine.dose} ${medicine.doseUnit})',
          repeatTime,
          NotificationDetails(android: repeatDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e) {
        debugPrint('Error scheduling repeat cascade #$repeat: $e');
      }
    }
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
      priority: Priority.high,
      fullScreenIntent: true,
      sound: const RawResourceAndroidNotificationSound('alarm_chime'),
      playSound: true,
      enableVibration: true,
      color: const Color(0xFFF3A638),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          AppConstants.actionTaken,
          'Taken / తీసుకున్నాను ✅',
          showsUserInterface: true,
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      snoozeId,
      '⏳ స్నూజ్ సమయం ముగిసింది! / Snooze Ended',
      '${quote.telugu}\n${medicineName} వేసుకునే సమయం అయింది బంగారం!',
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
      priority: Priority.high,
      fullScreenIntent: true,
      sound: const RawResourceAndroidNotificationSound('alarm_chime'),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        '${quote.telugu}\n\nఇది టెస్ట్ అలారమ్! నోటిఫికేషన్, సౌండ్ మరియు వైబ్రేషన్ సరిగ్గా పనిచేస్తున్నాయి ❤️',
        contentTitle: '❤️ టెస్ట్ అలారమ్ / Test Loving Reminder',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          AppConstants.actionTaken,
          'Taken / తీసుకున్నాను ✅',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          AppConstants.actionSnooze,
          'Snooze 10m / ఆపు ⏳',
          showsUserInterface: false,
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      999999,
      '❤️ టెస్ట్ అలారమ్ / Test Loving Reminder',
      quote.telugu,
      testTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'medicineId': 'test_med',
        'medicineName': 'Test Medicine (లవ్ టాబ్లెట్)',
        'dose': '1',
        'doseUnit': 'Dose of Love',
        'note': 'టెస్ట్ అలారమ్ సరిగ్గా రింగ్ అయింది!',
        'quoteTelugu': quote.telugu,
        'quoteEnglish': quote.english,
        'scheduledTime': DateTime.now().toIso8601String(),
      }),
    );
  }
}
