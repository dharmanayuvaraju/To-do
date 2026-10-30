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

  /// Check current status
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Request Notification permissions (Android 13+)
  static Future<bool> requestNotificationPermissions() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request Exact Alarm permissions (Android 12+)
  static Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  /// Brand specific instructions
  static const Map<String, List<String>> brandGuides = {
    'Funtouch OS / OriginOS (Recommended)': [
      '1. Settings > Battery > "High background power consumption" > Toggle ON for Do It Now (Most Important!)',
      '2. Settings > Apps & Permissions > "Autostart" > Toggle ON for Do It Now',
      '3. Settings > Apps > Do It Now > Single permission settings > Enable "Display pop-up window while running in background"',
      '4. In Recent Apps tray, swipe down on the Do It Now card and tap the Lock 🔒 icon',
    ],
    'One UI': [
      '1. Settings > Apps > Do It Now > Battery > Select "Unrestricted"',
      '2. Device Care > Battery > Background usage limits > Ensure Do It Now is NOT sleeping',
      '3. Enable "Appear on top" permission for full-screen alarm ringing',
    ],
    'Xiaomi / Redmi / POCO (MIUI / HyperOS)': [
      '1. Settings > Apps > Manage Apps > Do It Now > Enable "Autostart"',
      '2. Set "Battery Saver" to "No restrictions"',
      '3. Enable "Show on Lock screen" and "Display pop-up windows"',
    ],
    'Oppo / Realme (ColorOS)': [
      '1. Settings > Battery > Battery usage > Do It Now > Turn ON "Allow foreground" and "Allow background activity"',
      '2. Turn ON "Allow auto-launch"',
    ],
    'OnePlus (OxygenOS)': [
      '1. Settings > Battery > Battery optimization > Select "Don\'t optimize"',
      '2. Lock the app in Recent Apps',
    ],
  };
}
