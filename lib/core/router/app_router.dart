// lib/core/router/app_router.dart
// R1 — centralized route registry (F2, F3, F6)
// Adapted to use existing EduPaths screen names.
// 
// Add to main.dart:
//   import 'package:flutter_web_plugins/url_strategy.dart';
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     usePathUrlStrategy(); // clean /pathway/:id URLs — pairs with F1 rewrite
//     await Supabase.initialize(...);
//     runApp(const ProviderScope(child: EduPathsApp()));
//   }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// R1 — single source of truth for all route paths.
/// Import this anywhere a path string is needed.
abstract final class Paths {
  static const home = '/home';
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const whoAreYou = '/who-are-you';
  static const onboardingStart = '/onboarding/start';
  static const onboardingInterests = '/onboarding/interests';
  static const onboardingEnjoy = '/onboarding/enjoy';
  static const onboardingSummary = '/onboarding/summary';
  static const roadmap = '/roadmap';
  static const explore = '/explore';
  static const saved = '/saved';
  static const notifications = '/notifications';
  static const admin = '/admin';
  static const pricing = '/pricing';
  static const checkout = '/checkout';
  static const parent = '/parent';
  static const schoolAdvisor = '/school-advisor';
  static const edubot = '/edubot';

  // F3 — parameterised routes use IDs (UUIDs from Supabase), never display names
  static String pathway(String careerId) => '/pathway/$careerId';
  static String course(String courseId) => '/course/$courseId';
  static String altRoutes(String careerId) => '/alt-routes/$careerId';
  static String whyMatch(String careerId) => '/why-match/$careerId';
  static String careersByCategory(String category) =>
      '/careers-by-category/${Uri.encodeComponent(category)}';
}

/// F3 helper — derive a URL-safe slug from a display name.
/// Use at data-ingest time; store the slug on the record.
String slugify(String name) => name
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r"[''']"), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// F6 — branded 404 page wired to go_router errorBuilder.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A2 — pathway line breaks on 404
                const Text('🔀', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                const Text(
                  "This path doesn't exist",
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 24,
                    fontWeight: FontWeight.w900, color: Color(0xFF1A1560)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here are two that do:',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 16,
                    color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(Paths.home),
                    child: const Text('Go to Dashboard'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(Paths.explore),
                    child: const Text('Explore Careers'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
