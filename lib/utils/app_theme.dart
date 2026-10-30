import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      primaryColor: AppColors.deepPlum,
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepPlum,
        secondary: AppColors.blushPink,
        surface: Colors.white,
        background: AppColors.cream,
        onPrimary: Colors.white,
        onSecondary: AppColors.deepPlum,
      ),
      textTheme: GoogleFonts.notoSansTeluguTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.ramabhadra(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.deepPlum,
        ),
        headlineMedium: GoogleFonts.notoSansTelugu(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.deepPlum,
        ),
        titleLarge: GoogleFonts.notoSansTelugu(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.deepPlum,
        ),
        bodyLarge: GoogleFonts.notoSansTelugu(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF4A3E59),
        ),
        bodyMedium: GoogleFonts.notoSansTelugu(
          fontSize: 14,
          color: const Color(0xFF6B5F79),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white.withOpacity(0.85),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.deepPlum),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.nightIndigo,
      primaryColor: AppColors.lavender,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lavender,
        secondary: AppColors.blushPink,
        surface: AppColors.nightPlum,
        background: AppColors.nightIndigo,
        onPrimary: AppColors.nightIndigo,
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.notoSansTeluguTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.ramabhadra(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.notoSansTelugu(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.notoSansTelugu(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.notoSansTelugu(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: const Color(0xFFDED5EA),
        ),
        bodyMedium: GoogleFonts.notoSansTelugu(
          fontSize: 14,
          color: const Color(0xFFB5A7C6),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.nightPlum.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
