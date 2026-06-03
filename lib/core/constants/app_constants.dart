// lib/core/constants/app_constants.dart
class AppConstants {
  // ── Supabase ──────────────────────────────────────────────
  static const supabaseUrl = 'https://ijpcynpztcmbgjhocsan.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqcGN5bnB6dGNtYmdqaG9jc2FuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3NzY2NDYsImV4cCI6MjA5NDM1MjY0Nn0.NmO5hzeiM3Tefh9gu2QMkeApYE2-7Uf91-r-jEcdHDg';

  // ── App ───────────────────────────────────────────────────
  static const appName = 'EduPaths';
  static const appTagline = 'Discover. Achieve. Unlock your future.';

  // ── Plans ─────────────────────────────────────────────────
  static const planFree = 'free';
  static const planPremium = 'premium';
  static const planPremiumPlus = 'premium_plus';

  // ── Free limits ───────────────────────────────────────────
  static const freeMatchLimit = 3;
  static const freeSavedLimit = 5;

  // ── Routes ────────────────────────────────────────────────
  static const routeSplash              = '/';
  static const routeWelcome             = '/welcome';
  static const routeSignup              = '/signup';
  static const routeLogin               = '/login';
  static const routeWhoAreYou           = '/who-are-you';
  static const routeOnboardingStart     = '/onboarding/start';
  static const routeOnboardingInterests = '/onboarding/interests';
  static const routeOnboardingEnjoy     = '/onboarding/enjoy';
  static const routeOnboardingPrefs     = '/onboarding/prefs';
  static const routeOnboardingSummary   = '/onboarding/summary';
  static const routeOnboardingComplete  = '/onboarding/complete';
  static const routeHome                = '/home';
  static const routePathwayDetail       = '/pathway/:id';
  static const routeRoadmap             = '/roadmap';
  static const routeAltRoutes           = '/alt-routes/:id';
  static const routeCompare             = '/compare';
  static const routeWhyMatch            = '/why-match/:id';
  static const routeExplore             = '/explore';
  static const routeCourseDetail        = '/course/:id';
  static const routeSaved               = '/saved';
  static const routeEduBot              = '/edubot';
  static const routeProfile             = '/profile';
  static const routeNotifications       = '/notifications';
  static const routeRoadmapPlan         = '/roadmap-plan';
  static const routeParentDashboard     = '/parent';
  static const routeParentInsights      = '/parent/insights';
  static const routePricing             = '/pricing';
  static const routeCheckout            = '/checkout';
  static const routeAdmin               = '/admin';
}
