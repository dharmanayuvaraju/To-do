import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static const List<String> teluguDays = [
    'Aadivaram',
    'Somavaram',
    'Mangalavaram',
    'Budhavaram',
    'Guruvaram',
    'Shukravaram',
    'Shanivaram',
  ];

  static const List<String> teluguShortDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const List<String> englishShortDays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  /// Format TimeOfDay to "8:30 AM"
  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  /// Format DateTime to "Today, 8:30 AM" or "29 Oct, 8:30 AM"
  static String formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat('hh:mm a').format(dt);
    if (today == target) {
      return 'Today, $timeStr';
    } else if (today.difference(target).inDays == 1) {
      return 'Yesterday, $timeStr';
    } else {
      return '${DateFormat('d MMM').format(dt)}, $timeStr';
    }
  }

  /// Get Short Day Label (e.g. "Mon")
  static String getBilingualDay(int weekdayIndex) {
    // DateTime weekday: 1 = Monday, 7 = Sunday
    final engIndex = weekdayIndex % 7;
    return englishShortDays[engIndex];
  }

  /// Date string in YYYY-MM-DD for grouping
  static String dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
