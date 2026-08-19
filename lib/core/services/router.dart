// lib/core/services/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../constants/app_constants.dart';
import '../router/app_router.dart' show NotFoundScreen;
import '../../features/auth/screens/auth_screens.dart';
import '../../features/onboarding/screens/onboarding_screens.dart';
import '../../features/onboarding/screens/onboarding_slider_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/careers/screens/career_screens.dart';
import '../../features/roadmap/screens/roadmap_screen.dart';
import '../../features/saved/screens/saved_screen.dart';
import '../../features/edubot/screens/edubot_screen.dart';
import '../../features/support/screens/support_screens.dart';
import '../../features/support/screens/about_us_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/quiz/screens/career_quiz_screen.dart';
import '../../features/school/screens/join_school_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/admin_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/subscription/screens/subscription_screens.dart';
import '../../features/school/screens/school_screens.dart';
import '../../features/parent/screens/parent_screens.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_support_screen.dart';
import '../../features/admin/screens/admin_view_as_screen.dart';
import '../../features/admin/screens/admin_test_screens.dart';

const _loginRequired = {
  '/saved', '/edubot', '/roadmap-plan', '/support', '/admin-inbox', '/discover',
  '/notifications', '/who-are-you', '/checkout', '/parent', '/admin',
  '/school-advisor', '/join-school', '/career-quiz',
  '/admin-home', '/admin-support', '/admin-view-as',
  '/admin-test-onboarding', '/admin-test-home',
};

const _authRoutes = {'/', '/welcome', '/login', '/signup'};

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

      if (isLoggedIn && _authRoutes.contains(loc)) return AppConstants.routeHome;

      if (!isLoggedIn &&
          (loc.startsWith('/pathway/') ||
           loc.startsWith('/course/') ||
           loc.startsWith('/alt-routes/') ||
           loc.startsWith('/why-match/') ||
           loc == AppConstants.routeSaved ||
           loc.startsWith(AppConstants.routeRoadmap))) {
        return AppConstants.routeProfile;
      }

      if (!isLoggedIn && _loginRequired.contains(loc)) return AppConstants.routeLogin;

      return null;
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [

      // ── Public ─────────────────────────────────────────────────────────
      GoRoute(path: AppConstants.routeSplash,
          builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppConstants.routeWelcome,
          builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: AppConstants.routeSignup,
          builder: (c, s) => const SignupScreen()),
      GoRoute(path: AppConstants.routeLogin,
          builder: (c, s) => const LoginScreen()),

      // ── Onboarding ──────────────────────────────────────────────────────
      GoRoute(path: AppConstants.routeWhoAreYou,
          builder: (c, s) => const WhoAreYouScreen()),
      GoRoute(path: AppConstants.routeOnboardingStart,
          builder: (c, s) => const OnboardingStartScreen()),
      GoRoute(path: AppConstants.routeOnboardingInterests,
          builder: (c, s) => const OnboardingSliderScreen()),
      GoRoute(path: AppConstants.routeOnboardingEnjoy,
          builder: (c, s) => const EnjoyScreen()),
      GoRoute(path: AppConstants.routeOnboardingPrefs,
          builder: (c, s) => const PrefsScreen()),
      GoRoute(path: AppConstants.routeOnboardingSummary,
          builder: (c, s) => const SummaryScreen()),
      GoRoute(path: AppConstants.routeOnboardingComplete,
          builder: (c, s) => const OnboardingCompleteScreen()),

      // ── Subscription ────────────────────────────────────────────────────
      GoRoute(path: AppConstants.routePricing,
          builder: (c, s) => const PricingScreen()),
      GoRoute(path: AppConstants.routeCheckout,
          builder: (c, s) => CheckoutScreen(
              plan: s.uri.queryParameters['plan'] ?? 'premium',
              cycle: s.uri.queryParameters['cycle'] ?? 'monthly')),

      // ── Parent ──────────────────────────────────────────────────────────
      GoRoute(path: AppConstants.routeParentDashboard,
          builder: (c, s) => const ParentDashboardScreen()),
      GoRoute(path: AppConstants.routeParentInsights,
          builder: (c, s) => const ParentInsightsScreen()),

      // ── School / Support ────────────────────────────────────────────────
      GoRoute(path: '/school-advisor',
          builder: (c, s) => const SchoolAdvisorScreen()),
      GoRoute(path: '/discover',
          builder: (c, s) => const DiscoverScreen()),
      GoRoute(path: '/career-quiz',
          builder: (c, s) => const CareerQuizScreen()),
      GoRoute(path: '/join-school',
          builder: (c, s) => const JoinSchoolScreen()),
      GoRoute(path: '/support',
          builder: (c, s) => const SupportThreadScreen()),
      GoRoute(path: '/admin-inbox',
          builder: (c, s) => const AdminInboxScreen()),
      GoRoute(path: '/admin-thread/:uid',
          builder: (c, s) => SupportThreadScreen(
              userId: s.pathParameters['uid'],
              userLabel: s.uri.queryParameters['name'])),
      GoRoute(path: '/about',
          builder: (c, s) => const AboutUsScreen()),
      GoRoute(path: AppConstants.routeAdmin,
          builder: (c, s) => const AdminScreen()),

      // ── Admin hub ───────────────────────────────────────────────────────
      GoRoute(path: '/admin-home',
          builder: (c, s) => const AdminHomeScreen()),
      GoRoute(path: '/admin-support',
          builder: (c, s) => const AdminSupportScreen()),
      GoRoute(path: '/admin-view-as',
          builder: (c, s) => const AdminViewAsScreen()),
      GoRoute(path: '/admin-test-onboarding',
          builder: (c, s) => const AdminTestOnboardingScreen()),
      GoRoute(path: '/admin-test-home',
          builder: (c, s) => const AdminTestHomeScreen()),

      // ── Career / Course detail ──────────────────────────────────────────
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

      // ── Main shell ──────────────────────────────────────────────────────
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

class _AuthNotifier extends ChangeNotifier {
  late final _sub = Supabase.instance.client.auth.onAuthStateChange
      .listen((data) {
    final e = data.event;
    if (e == AuthChangeEvent.signedIn || e == AuthChangeEvent.signedOut) {
      notifyListeners();
    }
  });

  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
