import 'package:flutter/material.dart';

/// MARIO app color palette.
class AppColors {
  AppColors._();

  // ── Authentic Italian "Il Tricolore" Theme 🇮🇹 ──────────────────────
  // Primary (Verde Italiano): Official Italian Flag Green / Fresh Genovese Basil
  static const Color primary = Color(0xFF008C45);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF005A2B);

  // Secondary (Rosso Pomodoro): Official Italian Flag Red / San Marzano Tomato
  static const Color secondary = Color(0xFFCD212A);
  static const Color secondaryLight = Color(0xFFE63946);
  static const Color secondaryDark = Color(0xFF9E0B20);

  // Accent (Parmigiano Gold): Warm Italian aged cheese & crust
  static const Color goldenCheese = Color(0xFFFFB703);
  static const Color goldenLight = Color(0xFFFFD166);

  // Authentic Italian Tricolore Triad
  static const Color tricoloreGreen = Color(0xFF008C45);
  static const Color tricoloreWhite = Color(0xFFFFFFFF);
  static const Color tricoloreRed = Color(0xFFCD212A);

  // Gradients for Hero Banners, Buttons & Headers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF009B4D), Color(0xFF005A2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFE02B36), Color(0xFF9E0B20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD166), Color(0xFFFFB703)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient italianFlagGradient = LinearGradient(
    colors: [Color(0xFF008C45), Color(0xFF0A9E52), Color(0xFFCD212A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Iconic 3-stripe Italian Tricolore Ribbon
  static const LinearGradient tricoloreRibbon = LinearGradient(
    colors: [
      Color(0xFF008C45),
      Color(0xFF008C45),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFCD212A),
      Color(0xFFCD212A),
    ],
    stops: [0.0, 0.333, 0.333, 0.666, 0.666, 1.0],
  );

  // ── Previous Red Theme Backup (To switch back anytime) ──────────────
  // static const Color primary = Color(0xFFE63946);
  // static const Color primaryDark = Color(0xFFc1121f);
  // static const Color secondary = Color(0xFF2A9D8F);
  // static const Color goldenCheese = Color(0xFFFFC107);

  // Neutral
  static const Color dark = Color(0xFF191C1A);
  static const Color grey = Color(0xFF636E67);
  static const Color lightGrey = Color(0xFFF2F4F2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFAF7F2); // Warm mozzarella / dough tone

  // Light theme surfaces
  static const Color bgLight = Color(0xFFFBFBF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE6EAE7);

  // Dark theme surfaces (Tuscan Midnight Olive tones)
  static const Color bgDark = Color(0xFF0B110D);
  static const Color surfaceDark = Color(0xFF131C16);
  static const Color surfaceHighDark = Color(0xFF1B261F);
  static const Color borderDark = Color(0xFF26362B);
  static const Color textDark = Color(0xFFF2F5F3);
  static const Color textSecondaryDark = Color(0xFF94A398);
}

/// Extension for easy theme-aware color access.
extension AppColorContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.bgDark : AppColors.bgLight;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get surfaceHigh => isDark ? AppColors.surfaceHighDark : AppColors.cream;
  Color get border => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color get text => isDark ? AppColors.textDark : AppColors.dark;
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.grey;
}
