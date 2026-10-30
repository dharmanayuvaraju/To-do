import 'package:flutter/material.dart';

/// Palette based on "Soft pastel nursery + night sky"
/// Warm, caring, protective, never clinical.
class AppColors {
  // Primary Nursery Pastels
  static const Color blushPink = Color(0xFFF8C8DC);
  static const Color lavender = Color(0xFFCDB4F6);
  static const Color cream = Color(0xFFFFF6EC);
  static const Color deepPlum = Color(0xFF3B2A4D);
  static const Color mintSuccess = Color(0xFFA8E6CF);

  // Secondary & Accents
  static const Color softPeach = Color(0xFFFFD6BA);
  static const Color pastelYellow = Color(0xFFFFF3B0);
  static const Color roseGold = Color(0xFFE5989B);
  static const Color crimsonLove = Color(0xFFD64045);
  static const Color nightIndigo = Color(0xFF1B1528);
  static const Color nightPlum = Color(0xFF271A38);
  static const Color softLilac = Color(0xFFE8DEF8);

  // Status Colors
  static const Color statusTaken = Color(0xFF5BC89B);
  static const Color statusMissed = Color(0xFFE65A65);
  static const Color statusSnoozed = Color(0xFFF3A638);
  static const Color statusPending = Color(0xFF8B7DB3);

  // Gradients
  static const LinearGradient blushLavenderGradient = LinearGradient(
    colors: [blushPink, lavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nightSkyGradient = LinearGradient(
    colors: [nightIndigo, deepPlum],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient creamLavenderGradient = LinearGradient(
    colors: [cream, Color(0xFFF3E8FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient alarmGradient = LinearGradient(
    colors: [
      Color(0xCC3B2A4D),
      Color(0xEE1B1528),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heartButtonGradient = LinearGradient(
    colors: [
      Color(0xFFFF7E9E),
      Color(0xFFE85A88),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism overlays
  static Color glassBg(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.65);

  static Color glassBorder(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.4);
}
