// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/services/router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // F2 — clean path URLs (/pathway/abc) instead of /#/ hash URLs.
  // Pairs with the SPA rewrite in netlify.toml (F1).
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Catch any startup errors and show them instead of blank screen
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    runApp(const ProviderScope(child: EduPathsApp()));
  } catch (e) {
    // If Supabase fails to init, show a fallback error screen
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'EduPaths failed to start.\nPlease refresh the page.\n\nError: $e',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'sans-serif', fontSize: 16)))))));
  }
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Cached router — never recreated, prevents GlobalKey duplicate errors
GoRouter? _cachedRouter;

class EduPathsApp extends ConsumerWidget {
  const EduPathsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _cachedRouter ??= ref.read(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _cachedRouter!,
      debugShowCheckedModeBanner: false,
    );
  }
}
