// lib/core/services/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../constants/app_constants.dart';
import '../router/app_router.dart' show NotFoundScreen;
import '../../features/auth/screens/auth_screens.dart';
import '../../features/onboarding/screens/onboarding_screens.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/careers/screens/career_screens.dart';
import '../../features/roadmap/screens/roadmap_screen.dart';
import '../../features/saved/screens/saved_screen.dart';
import '../../features/edubot/screens/edubot_screen.dart';
import '../../features/support/screens/support_screens.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/admin_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/subscription/screens/subscription_screens.dart';
import '../../features/school/screens/school_screens.dart';
import '../../features/parent/screens/parent_screens.dart';
import '../../shared/widgets/main_shell.dart';

// Routes that require login — EXACT matches only
const _loginRequired = {
  '/saved', '/edubot', '/roadmap-plan', '/support', '/admin-inbox', '/discover',
  '/notifications', '/who-are-you', '/checkout', '/parent', '/admin',
};

// Routes that logged-in users should not see
const _authRoutes = {'/', '/welcome', '/login', '/signup'};

// Single global navigator key — must not be recreated on rebuild
final _navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier();
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _navigatorKey,
    refreshListenable: notifier,
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final loc = state.matchedLocation;

      // If logged in and on an auth page → go to home
      if (isLoggedIn && _authRoutes.contains(loc)) {
        return AppConstants.routeHome;
      }

      // Admin users never need WhoAreYou screen
      if (isLoggedIn && loc == AppConstants.routeWhoAreYou) {
        // Can't easily check isAdmin here without async — handled in login flow
        // But if they somehow land here, let them through
      }

      // Guests exploring the app are funnelled to the guest Profile page
      // (which shows Sign Up / Log In) when they try to open gated content:
      // any career detail page, Saved, or the Roadmap (item 4).
      if (!isLoggedIn &&
          (loc.startsWith('/pathway/') ||      // career detail pages
           loc.startsWith('/course/') ||
           loc.startsWith('/alt-routes/') ||
           loc.startsWith('/why-match/') ||
           loc == AppConstants.routeSaved ||
           loc.startsWith(AppConstants.routeRoadmap))) {
        return AppConstants.routeProfile;
      }

      // If not logged in and on a protected page → go to splash
      // Only exact match — never startsWith — prevents detail page flicker
      if (!isLoggedIn && _loginRequired.contains(loc)) {
        return AppConstants.routeSplash;
      }

      return null;
    },
    // F6 — branded 404 for any unknown path (never a blank/default error page)
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      // ── Public routes ──────────────────────────────────────
      GoRoute(path: AppConstants.routeSplash,
        builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppConstants.routeWelcome,
        builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: AppConstants.routeSignup,
        builder: (c, s) => const SignupScreen()),
      GoRoute(path: AppConstants.routeLogin,
        builder: (c, s) => const LoginScreen()),

      // ── Onboarding ─────────────────────────────────────────
      GoRoute(path: AppConstants.routeWhoAreYou,
        builder: (c, s) => const WhoAreYouScreen()),
      GoRoute(path: AppConstants.routeOnboardingStart,
        builder: (c, s) => const OnboardingStartScreen()),
      GoRoute(path: AppConstants.routeOnboardingInterests,
        builder: (c, s) => const InterestsScreen()),
      GoRoute(path: AppConstants.routeOnboardingEnjoy,
        builder: (c, s) => const EnjoyScreen()),
      GoRoute(path: AppConstants.routeOnboardingPrefs,
        builder: (c, s) => const PrefsScreen()),
      GoRoute(path: AppConstants.routeOnboardingSummary,
        builder: (c, s) => const SummaryScreen()),
      GoRoute(path: AppConstants.routeOnboardingComplete,
        builder: (c, s) => const OnboardingCompleteScreen()),

      // ── Subscription ───────────────────────────────────────
      GoRoute(path: AppConstants.routePricing,
        builder: (c, s) => const PricingScreen()),
      GoRoute(path: AppConstants.routeCheckout,
        builder: (c, s) => CheckoutScreen(
          plan: s.uri.queryParameters['plan'] ?? 'premium',
          cycle: s.uri.queryParameters['cycle'] ?? 'monthly')),

      // ── Parent ─────────────────────────────────────────────
      GoRoute(path: AppConstants.routeParentDashboard,
        builder: (c, s) => const ParentDashboardScreen()),
      GoRoute(path: AppConstants.routeParentInsights,
        builder: (c, s) => const ParentInsightsScreen()),

      // ── Admin ──────────────────────────────────────────────
      GoRoute(path: '/school-advisor',
        builder: (c, s) => const SchoolAdvisorScreen()),
      GoRoute(path: '/discover',
        builder: (c, s) => const DiscoverScreen()),
      GoRoute(path: '/support',
        builder: (c, s) => const SupportThreadScreen()),
      GoRoute(path: '/admin-inbox',
        builder: (c, s) => const AdminInboxScreen()),
      GoRoute(path: '/admin-thread/:uid',
        builder: (c, s) => SupportThreadScreen(
          userId: s.pathParameters['uid'],
          userLabel: s.uri.queryParameters['name'])),
      GoRoute(path: AppConstants.routeAdmin,
        builder: (c, s) => const AdminScreen()),

      // ── Career / Course detail ─────────────────────────────
      GoRoute(path: '/careers-by-category/:category',
        builder: (c, s) => CareersByCategoryScreen(
          category: s.pathParameters['category']!)),
      GoRoute(path: '/pathway/:id',
        builder: (c, s) => CareerDetailScreen(
          careerId: s.pathParameters['id']!)),
      GoRoute(path: '/course/:id',
        builder: (c, s) => CourseDetailScreen(
          courseId: s.pathParameters['id']!)),
      GoRoute(path: '/alt-routes/:id',
        builder: (c, s) => AltRoutesScreen(
          careerId: s.pathParameters['id']!)),
      GoRoute(path: AppConstants.routeCompare,
        builder: (c, s) => CompareScreen(
          careerId: s.uri.queryParameters['career'])),
      GoRoute(path: '/why-match/:id',
        builder: (c, s) => WhyMatchScreen(
          careerId: s.pathParameters['id']!)),

      // ── Main shell with bottom/side nav ────────────────────
      ShellRoute(
        builder: (c, s, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppConstants.routeHome,
            builder: (c, s) => const HomeScreen()),
          GoRoute(path: AppConstants.routeExplore,
            builder: (c, s) => const ExploreScreen()),
          GoRoute(path: AppConstants.routeRoadmap,
            builder: (c, s) => const RoadmapScreen()),
          GoRoute(path: AppConstants.routeSaved,
            builder: (c, s) => const SavedScreen()),
          GoRoute(path: AppConstants.routeEduBot,
            builder: (c, s) => const EdubotScreen()),
          GoRoute(path: AppConstants.routeProfile,
            builder: (c, s) => const ProfileScreen()),
          GoRoute(path: AppConstants.routeNotifications,
            builder: (c, s) => const NotificationsScreen()),
          GoRoute(path: AppConstants.routeRoadmapPlan,
            builder: (c, s) => const RoadmapPlanScreen()),
        ],
      ),
    ],
  );
});

// Only fires on actual sign in / sign out — NOT on every auth state tick
class _AuthNotifier extends ChangeNotifier {
  late final _sub = Supabase.instance.client.auth.onAuthStateChange
      .listen((data) {
    final e = data.event;
    if (e == AuthChangeEvent.signedIn ||
        e == AuthChangeEvent.signedOut) {
      notifyListeners();
    }
  });

  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
