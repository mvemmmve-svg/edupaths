// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary       = Color(0xFF5B4FE9);
  static const primaryLight  = Color(0xFF7B72F0);
  static const primaryDark   = Color(0xFF3D33C7);
  static const primaryPale   = Color(0xFFEEECFF);
  static const accentGreen   = Color(0xFF22C55E);
  static const accentOrange  = Color(0xFFFF8C42);
  static const accentPink    = Color(0xFFEC4899);
  static const accentBlue    = Color(0xFF3B82F6);
  static const accentYellow  = Color(0xFFF59E0B);
  static const bgPage        = Color(0xFFF7F6FF);
  static const bgCard        = Color(0xFFFFFFFF);
  static const bgSurface     = Color(0xFFEEECFF);
  static const bgGrey        = Color(0xFFF1F5F9);
  static const textDark      = Color(0xFF1A1560);
  static const textMid       = Color(0xFF64748B);
  static const textLight     = Color(0xFFADB5BD);
  static const success       = Color(0xFF22C55E);
  static const error         = Color(0xFFEF4444);
  static const warning       = Color(0xFFF59E0B);
  static const border        = Color(0xFFE8E5FF);
}

BoxDecoration gradientBox({double radius = 16, List<Color>? colors}) =>
    BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
    );

// Use system font stack - no google_fonts dependency needed
const _fontFamily = 'Nunito';

TextStyle _n(double size, FontWeight w, Color c) =>
    TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: w, color: c);

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: AppColors.bgPage,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.bgCard,
    ),
    textTheme: TextTheme(
      displayLarge:   _n(32, FontWeight.w900, AppColors.textDark),
      displayMedium:  _n(26, FontWeight.w800, AppColors.textDark),
      headlineMedium: _n(20, FontWeight.w800, AppColors.textDark),
      headlineSmall:  _n(17, FontWeight.w700, AppColors.textDark),
      titleLarge:     _n(15, FontWeight.w700, AppColors.textDark),
      bodyLarge:      _n(15, FontWeight.w500, AppColors.textDark),
      bodyMedium:     _n(14, FontWeight.w400, AppColors.textMid),
      bodySmall:      _n(12, FontWeight.w400, AppColors.textLight),
      labelLarge:     _n(15, FontWeight.w700, Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      hintStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textLight, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPage,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
      iconTheme: IconThemeData(color: AppColors.textDark),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: const Color(0xFF0F0D1E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.dark,
    ),
    textTheme: TextTheme(
      displayLarge:   _n(32, FontWeight.w900, Colors.white),
      displayMedium:  _n(26, FontWeight.w800, Colors.white),
      headlineMedium: _n(20, FontWeight.w800, Colors.white),
      headlineSmall:  _n(17, FontWeight.w700, Colors.white),
      titleLarge:     _n(15, FontWeight.w700, Colors.white),
      bodyLarge:      _n(15, FontWeight.w500, Colors.white),
      bodyMedium:     _n(14, FontWeight.w400, const Color(0xFFB0A8D0)),
      bodySmall:      _n(12, FontWeight.w400, const Color(0xFF7B6EA0)),
      labelLarge:     _n(15, FontWeight.w700, Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0D1E),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1760),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2D2A6E))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2D2A6E))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      hintStyle: const TextStyle(fontFamily: _fontFamily, color: Color(0xFF7B6EA0), fontSize: 14),
    ),
  );
}
