// lib/core/theme/app_theme.dart
//
// CORRECTIONS vs. the previous draft:
//  1. The spec's core Phase-4 rule was missing: each pathway type owns one
//     semantic route color used everywhere (A1). The old file only had
//     decorative accentBlue/accentGreen. Added uniRoute/appRoute/waypoint as
//     semantic tokens + routeColorFor(). Per the spec's own note, the hex
//     values are mapped onto the app's existing purple brand rather than
//     replacing it — the semantic rule matters more than the exact hexes.
//  2. 'Nunito' was referenced but never bundled (no google_fonts, no fonts:
//     in pubspec) so everything silently rendered Roboto. pubspec.yaml now
//     bundles Nunito + IBM Plex Mono; this file adds AppText.data for the
//     Plex Mono data chips (spec A1/A4: entry grades, fees, pay, duration).
//  3. Kept gradientBox but note spec A2: "no gradients competing with the
//     pathway line" — use it sparingly or retire it during Phase 4.

import 'package:flutter/material.dart';

class AppColors {
  // Existing brand (kept)
  static const primary       = Color(0xFF5B4FE9);
  static const primaryLight  = Color(0xFF7B72F0);
  static const primaryDark   = Color(0xFF3D33C7);
  static const primaryPale   = Color(0xFFEEECFF);

  // A1 — SEMANTIC route tokens. Never use these decoratively; blue always
  // means university, green always means apprenticeship, on every screen.
  static const uniRoute  = Color(0xFF2456E6); // university route blue
  static const appRoute  = Color(0xFF0E9B76); // apprenticeship route green
  static const waypoint  = Color(0xFFF2B33D); // CTAs + progress nodes ONLY —
                                              // never body text on light bg (fails AA)

  // Decorative accents (existing — do not reuse for pathway identity)
  static const accentPink    = Color(0xFFEC4899);
  static const accentOrange  = Color(0xFFFF8C42);

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

enum PathwayType { university, apprenticeship }

/// A1 rule enforced in one place: route color is looked up, never hardcoded.
Color routeColorFor(PathwayType type) => switch (type) {
      PathwayType.university => AppColors.uniRoute,
      PathwayType.apprenticeship => AppColors.appRoute,
    };

/// A7 — color is never the sole differentiator; badges always carry text.
String pathwayLabel(PathwayType type) => switch (type) {
      PathwayType.university => 'University',
      PathwayType.apprenticeship => 'Apprenticeship',
    };

const _font = 'Nunito';
const _mono = 'IBMPlexMono';

TextStyle _n(double size, FontWeight w, Color c) =>
    TextStyle(fontFamily: _font, fontSize: size, fontWeight: w, color: c);

/// A1/A4 — data values (UCAS points, £9,535/yr, 3 yrs) in mono so the
/// numbers students compare are instantly scannable.
abstract final class AppText {
  static const data = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
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
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: _font,
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
        textStyle: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700),
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
        textStyle: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700),
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
      hintStyle: const TextStyle(fontFamily: _font, color: AppColors.textLight, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPage,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
      iconTheme: IconThemeData(color: AppColors.textDark),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _font,
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
        fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
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
      hintStyle: const TextStyle(fontFamily: _font, color: Color(0xFF7B6EA0), fontSize: 14),
    ),
  );
}
