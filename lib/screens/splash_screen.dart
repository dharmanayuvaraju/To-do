import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';
import '../services/quote_service.dart';
import '../utils/app_colors.dart';
import '../utils/battery_optimizer_helper.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Initialize all offline services
    final storage = StorageService();
    await storage.init();
    await QuoteService().init();
    await NotificationService().init();
    await AlarmService().syncAndRescheduleAll();

    // Softly request notification permissions on first launch
    await BatteryOptimizerHelper.requestNotificationPermissions();
    await BatteryOptimizerHelper.requestExactAlarmPermission();

    // Wait a moment for the sweet splash animations to play
    await Future.delayed(const Duration(milliseconds: 2200));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final herName = storage.isInitialized ? storage.herName : 'Bujji';
    final myName = storage.isInitialized ? storage.myName : 'Chinnu';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cream,
              Color(0xFFFDE8E9),
              Color(0xFFE8DEF8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Romantic Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glowing background ring
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blushPink.withOpacity(0.7),
                            blurRadius: 35,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // Outer Ring
                    Container(
                      width: 154,
                      height: 154,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/hero_star.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/me.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    // Floating Heart Badge
                    Positioned(
                      bottom: 4,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.heartButtonGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.easeOutBack)
                    .then()
                    .shimmer(duration: 1200.ms),

                const SizedBox(height: 32),

                // App Title
                Text(
                  'Do It Now',
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepPlum,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(delay: 300.ms).moveY(begin: 12, end: 0),

                Text(
                  'Care & Daily Reminders',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: const Color(0xFF7A5A88),
                  ),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 24),

                // Sweet personal greeting
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.blushPink.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'For my dearest $herName ❤️ With love from $myName',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.deepPlum,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).scale(),

                const SizedBox(height: 36),

                // Subtle loving progress indicator
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.roseGold),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

