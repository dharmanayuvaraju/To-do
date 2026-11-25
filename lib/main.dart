import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/partner_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge immersive UI with transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (_) {}

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (_) {}

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init: $e');
  }

  // Disable online GoogleFonts fetching so bundled offline fonts are used
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize offline storage service
  final storageService = StorageService();
  await storageService.init();

  // Initialize notification service & re-sync today's alarms (cancels repeats for doses already taken)
  await NotificationService().init();
  await NotificationService().resyncTodayAlarms();

  // If this phone is registered as receiver (His phone), keep FCM token synced
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(PartnerService.keyRole) == 'receiver') {
      PartnerService.initReceiver();
    }
  } catch (_) {}

  runApp(const MaaMadhuramApp());
}

class MaaMadhuramApp extends StatelessWidget {
  const MaaMadhuramApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

    return AnimatedBuilder(
      animation: storage,
      builder: (context, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: storage.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
