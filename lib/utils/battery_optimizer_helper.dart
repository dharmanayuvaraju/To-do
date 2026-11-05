import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizerHelper {
  /// Request system ignore battery optimizations
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Check current battery optimization status
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Check Notification permission status
  static Future<bool> isNotificationGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.notification.isGranted;
  }

  /// Request Notification permissions (Android 13+)
  static Future<bool> requestNotificationPermissions() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check Exact Alarm permission status
  static Future<bool> isExactAlarmGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.scheduleExactAlarm.isGranted;
  }

  /// Request Exact Alarm permissions (Android 12+)
  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  /// Open Android App Settings screen directly
  static Future<void> openAppSystemSettings() async {
    await openAppSettings();
  }

  /// Request all 3 core permissions in sequence
  static Future<void> requestAllCorePermissions() async {
    if (!Platform.isAndroid) return;
    await requestNotificationPermissions();
    await requestExactAlarmPermission();
    await requestIgnoreBatteryOptimizations();
  }

  /// Brand specific instructions
  static const Map<String, List<String>> brandGuides = {
    'Vivo / iQOO (Funtouch OS / OriginOS)': [
      '1. Settings > Battery > "High background power consumption" > Toggle ON for Do It Now (Most Important!)',
      '2. Settings > Apps & Permissions > "Autostart" > Toggle ON for Do It Now',
      '3. Settings > Apps > Do It Now > Single permission settings > Enable "Display pop-up window while running in background"',
      '4. In Recent Apps tray, swipe down on the Do It Now card and tap the Lock 🔒 icon',
    ],
    'Samsung (One UI)': [
      '1. Settings > Apps > Do It Now > Battery > Select "Unrestricted" (crucial!)',
      '2. Device Care > Battery > Background usage limits > Ensure Do It Now is in "Never sleeping apps"',
      '3. Settings > Apps > Special access > "Alarms & reminders" > Allow for Do It Now',
      '4. Enable "Appear on top" permission for full-screen alarm ringing',
    ],
    'Xiaomi / Redmi / POCO (MIUI / HyperOS)': [
      '1. Settings > Apps > Manage Apps > Do It Now > Enable "Autostart"',
      '2. In the same menu, set "Battery Saver" to "No restrictions"',
      '3. Other permissions > Enable "Show on Lock screen" and "Display pop-up windows"',
      '4. Lock Do It Now in the Recent Apps tray with the padlock 🔒 icon',
    ],
    'Oppo / Realme (ColorOS / Realme UI)': [
      '1. Settings > Battery > Battery usage > Do It Now > Turn ON "Allow foreground" and "Allow background activity"',
      '2. Settings > Apps > Auto-launch > Enable for Do It Now',
      '3. App Info > Battery > "Don\'t optimize"',
    ],
    'OnePlus (OxygenOS)': [
      '1. Settings > Battery > Battery optimization > Select "Don\'t optimize"',
      '2. Settings > Apps > Auto-launch > Enable for Do It Now',
      '3. Lock the app in Recent Apps tray',
    ],
    'Motorola / Pixel / Stock Android': [
      '1. Settings > Apps > Do It Now > App battery usage > Select "Unrestricted"',
      '2. Settings > Apps > Special app access > "Alarms & reminders" > Allowed',
    ],
  };
}
