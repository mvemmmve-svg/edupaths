// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary       = Color(0xFF5B4FE9);
  static const primaryLight  = Color(0xFF7B72F0);
  static const primaryDark   = Color(0xFF3D33C7);
  static const primaryPale   = Color(0xFFEEECFF);

  static const uniRoute  = Color(0xFF2456E6);
  static const appRoute  = Color(0xFF0E9B76);
  static const waypoint  = Color(0xFFF2B33D);

  static const accentPink    = Color(0xFFEC4899);
  static const accentOrange  = Color(0xFFFF8C42);

  static const accentGreen  = success;
  static const accentBlue   = uniRoute;
  static const accentYellow = waypoint;

  static const bgPage        = Color(0xFFF7F6FF);
  static const bgCard        = Color(0xFFFFFFFF);
  static const bgSurface     = Color(0xFFEEECFF);
  static const bgGrey        = Color(0xFFF1F5F9);

  static const textDark      = Color(0xFF14103F);
  static const textMid       = Color(0xFF3D4660);
  static const textLight     = Color(0xFF6E7891);

  static const success       = Color(0xFF16A34A);
  static const error         = Color(0xFFDC2626);
  static const warning       = Color(0xFFD97706);
  static const border        = Color(0xFFDDD8F7);
}

enum PathwayType { university, apprenticeship }

Color routeColorFor(PathwayType type) => switch (type) {
  PathwayType.university     => AppColors.uniRoute,
  PathwayType.apprenticeship => AppColors.appRoute,
};

String pathwayLabel(PathwayType type) => switch (type) {
  PathwayType.university     => 'University',
  PathwayType.apprenticeship => 'Apprenticeship',
};

abstract final class AppText {
  static TextStyle get data => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    letterSpacing: 0.2,
  );
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

class AppTheme {
  static ThemeData get light {
    // Use google_fonts to generate the text theme with Nunito at lighter weights
    final base = GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPage,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.bgCard,
      ),
      textTheme: base.copyWith(
        // Lighter weights than before — was w900/w800/w700, now w700/w600/w500
        displayLarge:   GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textDark),
        displayMedium:  GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textDark),
        headlineMedium: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
        headlineSmall:  GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark),
        titleLarge:     GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        bodyLarge:      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textDark),
        bodyMedium:     GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMid),
        bodySmall:      GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textLight),
        labelLarge:     GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600),
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
        hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
    );
  }

  static ThemeData get dark {
    final base = GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0D1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.dark,
      ),
      textTheme: base.copyWith(
        displayLarge:   GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
        displayMedium:  GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall:  GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge:     GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge:      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium:     GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0A8D0)),
        bodySmall:      GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF7B6EA0)),
        labelLarge:     GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F0D1E),
        elevation: 0,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
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
        hintStyle: GoogleFonts.nunito(color: const Color(0xFF7B6EA0), fontSize: 14),
      ),
    );
  }
}
