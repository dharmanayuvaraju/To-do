import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_config.dart';
import 'notification_service.dart';

class PartnerService {
  static const String keyRole = 'partner_role'; // 'taker' or 'receiver'
  static const String keyPairCode = 'pair_code';
  static const String keySenderKey = 'partner_sender_key';
  static const String keyReceiverToken = 'partner_receiver_token';
  static const String keyAlertsEnabled = 'partner_alerts_enabled';
  static const String keyPartnerName = 'partner_name';
  static const String keyIncludeMedName = 'partner_include_med_name';
  static const String keyAlertMissed = 'partner_alert_missed';
  static const String keyPending = 'partner_pending';

  static AutoRefreshingAuthClient? _cachedAuthClient;
  static String? _cachedProjectId;
  static Timer? _retryTimer;

  /// Generates a secure, unguessable pair code: 'dn' + 32 random chars from [a-z0-9]
  static String generatePairCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    final buffer = StringBuffer('dn');
    for (int i = 0; i < 32; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  /// Validates format of pair code (starts with 'dn', length >= 34)
  static bool isValidPairCode(String code) {
    final trimmed = code.trim();
    return trimmed.startsWith('dn') && trimmed.length >= 34;
  }

  /// Validates the pasted service account JSON
  static Map<String, dynamic>? validateSenderKey(String rawJson) {
    try {
      final parsed = jsonDecode(rawJson.trim());
      if (parsed is Map<String, dynamic>) {
        if (parsed['type'] == 'service_account' &&
            parsed.containsKey('project_id') &&
            parsed.containsKey('client_email') &&
            parsed.containsKey('private_key')) {
          return parsed;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _formatDate(DateTime dt) {
    return DateFormat('yyyyMMdd').format(dt);
  }

  static String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  /// Ensure Firebase app and anonymous authentication are initialized
  static Future<void> ensureFirebaseReady() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      debugPrint('ensureFirebaseReady: $e');
    }
  }

  // ==========================================
  // HIS PHONE (RECEIVER) IMPLEMENTATION
  // ==========================================

  /// Initialize His phone: requests POST_NOTIFICATIONS, gets FCM token, writes to RTDB
  static Future<void> initReceiver() async {
    try {
      await ensureFirebaseReady();
      final messaging = FirebaseMessaging.instance;

      // Ask POST_NOTIFICATIONS
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final prefs = await SharedPreferences.getInstance();
      String? code = prefs.getString(keyPairCode);
      if (code == null || code.trim().isEmpty) {
        code = generatePairCode();
        await prefs.setString(keyPairCode, code);
      }

      await syncReceiverToken(code);

      // Listen for FCM token refreshes
      messaging.onTokenRefresh.listen((newToken) async {
        final currentCode = prefs.getString(keyPairCode);
        if (currentCode != null && currentCode.isNotEmpty) {
          try {
            await FirebaseConfig.database
                .ref('pairs/$currentCode/receiverToken')
                .set(newToken);
            await prefs.setString('receiver_last_synced_token', newToken);
          } catch (_) {}
        }
      });

      // Foreground message notification on His phone
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = message.notification;
        if (notif != null) {
          NotificationService.plugin.show(
            DateTime.now().millisecondsSinceEpoch % 100000000,
            notif.title ?? 'Medicine alert ❤️',
            notif.body ?? 'She took her medicine',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'partner_alerts',
                'Partner alerts',
                channelDescription: 'Alerts when partner takes or snoozes medicine',
                importance: Importance.max,
                priority: Priority.max,
                playSound: true,
                enableVibration: true,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('initReceiver error: $e');
    }
  }

  /// Write FCM token only if changed
  static Future<void> syncReceiverToken(String code) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final lastSynced = prefs.getString('receiver_last_synced_token');
      if (token != lastSynced) {
        await FirebaseConfig.database
            .ref('pairs/$code/receiverToken')
            .set(token);
        await prefs.setString('receiver_last_synced_token', token);
      }
    } catch (e) {
      debugPrint('Error syncing receiver token: $e');
    }
  }

  /// Regenerate pair code on His phone
  static Future<String> regenerateReceiverCode() async {
    final prefs = await SharedPreferences.getInstance();
    final newCode = generatePairCode();
    await prefs.setString(keyPairCode, newCode);
    await prefs.remove('receiver_last_synced_token');
    await syncReceiverToken(newCode);
    return newCode;
  }

  // ==========================================
  // HER PHONE (SENDER) IMPLEMENTATION
  // ==========================================

  /// Fetch receiver token from RTDB using pair code
  static Future<String?> fetchReceiverToken(String code) async {
    try {
      await ensureFirebaseReady();
      final snapshot = await FirebaseConfig.database
          .ref('pairs/$code/receiverToken')
          .get()
          .timeout(const Duration(seconds: 8));

      if (snapshot.exists && snapshot.value is String) {
        final token = snapshot.value as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyReceiverToken, token);
        return token;
      }
    } catch (_) {}
    return null;
  }

  /// Get or create authenticated client via service account JSON
  static Future<AutoRefreshingAuthClient?> _getAuthClient(String keyJson) async {
    if (_cachedAuthClient != null) {
      return _cachedAuthClient;
    }
    try {
      final Map<String, dynamic> keyData = jsonDecode(keyJson);
      _cachedProjectId = keyData['project_id'] as String?;
      final credentials = ServiceAccountCredentials.fromJson(keyData);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      _cachedAuthClient = await clientViaServiceAccount(credentials, scopes);
      return _cachedAuthClient;
    } catch (_) {
      return null;
    }
  }

  /// Core FCM HTTP v1 dispatcher
  static Future<bool> _dispatchFcmV1({
    required String keyJson,
    required String receiverToken,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final client = await _getAuthClient(keyJson);
      final projectId = _cachedProjectId;
      if (client == null || projectId == null || projectId.isEmpty) {
        return false;
      }

      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final payload = {
        'message': {
          'token': receiverToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'HIGH',
            'ttl': '21600s',
            'notification': {
              'channel_id': 'partner_alerts',
              'sound': 'default',
              'notification_priority': 'PRIORITY_MAX',
            },
          },
          'data': {
            'type': type,
          },
        },
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return true;
      }

      // If token is 404 or UNREGISTERED, re-read token once and retry
      if (response.statusCode == 404 || response.body.contains('UNREGISTERED')) {
        final prefs = await SharedPreferences.getInstance();
        final code = prefs.getString(keyPairCode);
        if (code != null && code.isNotEmpty) {
          final freshToken = await fetchReceiverToken(code);
          if (freshToken != null && freshToken.isNotEmpty && freshToken != receiverToken) {
            final retryPayload = {
              'message': {
                'token': freshToken,
                'notification': {
                  'title': title,
                  'body': body,
                },
                'android': {
                  'priority': 'HIGH',
                  'ttl': '21600s',
                  'notification': {
                    'channel_id': 'partner_alerts',
                    'sound': 'default',
                    'notification_priority': 'PRIORITY_MAX',
                  },
                },
                'data': {
                  'type': type,
                },
              },
            };
            final retryResponse = await client.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(retryPayload),
            ).timeout(const Duration(seconds: 8));
            return retryResponse.statusCode == 200;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Sends a push event directly via FCM HTTP v1 from Her phone
  static Future<void> sendEvent(
    String type, {
    String? med,
    String? medId,
    DateTime? scheduledTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final bool alertsEnabled = prefs.getBool(keyAlertsEnabled) ?? true;
      if (!alertsEnabled) return;

      final keyJson = prefs.getString(keySenderKey);
      final pairCode = prefs.getString(keyPairCode);
      if (keyJson == null || keyJson.isEmpty || pairCode == null || pairCode.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final sched = scheduledTime ?? now;
      final dateStr = _formatDate(sched);
      final medKey = medId ?? (med ?? 'default');

      // Deduplication:
      if (type == 'taken') {
        final dedupKey = 'partner_last_taken_${medKey}_$dateStr';
        if (prefs.getBool(dedupKey) == true) return;
        await prefs.setBool(dedupKey, true);
      } else if (type == 'snooze') {
        final dedupKey = 'partner_last_snooze_${medKey}_$dateStr';
        if (prefs.getBool(dedupKey) == true) return;
        await prefs.setBool(dedupKey, true);
      } else if (type == 'missed') {
        final alertMissed = prefs.getBool(keyAlertMissed) ?? true;
        if (!alertMissed) return;
        final dedupKey = 'partner_last_missed_${medKey}_$dateStr';
        if (prefs.getBool(dedupKey) == true) return;
        await prefs.setBool(dedupKey, true);
      }

      // Flush existing pending queue first
      await flushPending();

      final partnerName = prefs.getString(keyPartnerName) ?? 'She';
      final bool includeMed = prefs.getBool(keyIncludeMedName) ?? false;
      final timeStr = _formatTime(now);

      String title;
      String body;

      if (type == 'taken') {
        title = 'Medicine taken';
        body = (includeMed && med != null && med.isNotEmpty)
            ? '$partnerName took $med at $timeStr ❤️'
            : '$partnerName took her medicine at $timeStr ❤️';
      } else if (type == 'snooze') {
        title = 'Snoozed';
        body = (includeMed && med != null && med.isNotEmpty)
            ? '$partnerName snoozed $med for 10 min ⏳'
            : '$partnerName snoozed her medicine for 10 min ⏳';
      } else if (type == 'missed') {
        title = 'Missed dose';
        body = (includeMed && med != null && med.isNotEmpty)
            ? '$partnerName has not taken $med yet ⚠️'
            : '$partnerName has not taken her medicine yet ⚠️';
      } else {
        title = 'Test alert';
        body = 'Do It Now is connected ❤️';
      }

      String? receiverToken = prefs.getString(keyReceiverToken);
      if (receiverToken == null || receiverToken.isEmpty) {
        receiverToken = await fetchReceiverToken(pairCode);
      }

      bool success = false;
      if (receiverToken != null && receiverToken.isNotEmpty) {
        success = await _dispatchFcmV1(
          keyJson: keyJson,
          receiverToken: receiverToken,
          title: title,
          body: body,
          type: type,
        );
      }

      if (!success) {
        await _enqueuePending(
          type: type,
          med: med,
          medId: medId,
          name: partnerName,
          timeLabel: timeStr,
          ts: now.millisecondsSinceEpoch,
        );
      }
    } catch (_) {}
  }

  /// Sends a test alert
  static Future<bool> sendTestAlert() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final keyJson = prefs.getString(keySenderKey);
      final pairCode = prefs.getString(keyPairCode);
      if (keyJson == null || pairCode == null) return false;

      String? receiverToken = prefs.getString(keyReceiverToken);
      if (receiverToken == null || receiverToken.isEmpty) {
        receiverToken = await fetchReceiverToken(pairCode);
      }
      if (receiverToken == null || receiverToken.isEmpty) return false;

      return await _dispatchFcmV1(
        keyJson: keyJson,
        receiverToken: receiverToken,
        title: 'Test alert',
        body: 'Do It Now is connected ❤️',
        type: 'test',
      );
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // OFFLINE QUEUE (REPLACES RTDB PERSISTENCE)
  // ==========================================

  static Future<void> _enqueuePending({
    required String type,
    required String? med,
    required String? medId,
    required String name,
    required String timeLabel,
    required int ts,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(keyPending) ?? [];

      final now = DateTime.now();
      final filtered = list.where((item) {
        try {
          final data = jsonDecode(item) as Map<String, dynamic>;
          final itemTs = data['ts'] ?? 0;
          final age = now.difference(DateTime.fromMillisecondsSinceEpoch(itemTs));
          return age.inHours < 12;
        } catch (_) {
          return false;
        }
      }).toList();

      final newItem = jsonEncode({
        'type': type,
        'med': med,
        'medId': medId,
        'name': name,
        'timeLabel': timeLabel,
        'ts': ts,
      });
      filtered.add(newItem);

      // Max 20 items, drop oldest
      while (filtered.length > 20) {
        filtered.removeAt(0);
      }

      await prefs.setStringList(keyPending, filtered);
      startRetryTimer();
    } catch (_) {}
  }

  /// Flushes pending queue in order. Stops at first failure.
  static Future<void> flushPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(keyPending) ?? [];
      if (list.isEmpty) {
        _retryTimer?.cancel();
        _retryTimer = null;
        return;
      }

      final keyJson = prefs.getString(keySenderKey);
      final pairCode = prefs.getString(keyPairCode);
      if (keyJson == null || pairCode == null) return;

      String? receiverToken = prefs.getString(keyReceiverToken);
      if (receiverToken == null || receiverToken.isEmpty) {
        receiverToken = await fetchReceiverToken(pairCode);
      }
      if (receiverToken == null || receiverToken.isEmpty) return;

      final now = DateTime.now();
      final remaining = <String>[];
      bool hadFailure = false;

      for (final item in list) {
        if (hadFailure) {
          remaining.add(item);
          continue;
        }

        try {
          final data = jsonDecode(item) as Map<String, dynamic>;
          final int ts = data['ts'] ?? 0;
          final age = now.difference(DateTime.fromMillisecondsSinceEpoch(ts));
          if (age.inHours >= 12) {
            continue; // drop items older than 12 hours
          }

          final String type = data['type'] ?? 'taken';
          final String name = data['name'] ?? 'She';
          final String timeLabel = data['timeLabel'] ?? _formatTime(DateTime.fromMillisecondsSinceEpoch(ts));
          final String? med = data['med'];

          String title;
          String body;

          if (type == 'taken') {
            title = 'Medicine taken';
            body = med != null
                ? '$name took $med at $timeLabel ❤️'
                : '$name took her medicine at $timeLabel ❤️';
          } else if (type == 'snooze') {
            title = 'Snoozed';
            body = med != null
                ? '$name snoozed $med for 10 min (at $timeLabel) ⏳'
                : '$name snoozed her medicine for 10 min (at $timeLabel) ⏳';
          } else {
            title = 'Missed dose';
            body = med != null
                ? '$name has not taken $med yet (at $timeLabel) ⚠️'
                : '$name has not taken her medicine yet (at $timeLabel) ⚠️';
          }

          final ok = await _dispatchFcmV1(
            keyJson: keyJson,
            receiverToken: receiverToken,
            title: title,
            body: body,
            type: type,
          );

          if (!ok) {
            hadFailure = true;
            remaining.add(item);
          }
        } catch (_) {}
      }

      await prefs.setStringList(keyPending, remaining);
      if (remaining.isEmpty) {
        _retryTimer?.cancel();
        _retryTimer = null;
      }
    } catch (_) {}
  }

  /// While app is open and queue is not empty, retry every 2 minutes
  static void startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      flushPending();
    });
  }
}
