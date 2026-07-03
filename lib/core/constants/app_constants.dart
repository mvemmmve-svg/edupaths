// lib/core/constants/app_constants.dart
class AppConstants {
  // ── Supabase ──────────────────────────────────────────────
  // Prefers the value passed at build time via --dart-define (see
  // netlify.toml); falls back to the built-in project values whenever the
  // define is ABSENT **or empty** — an unset build variable expands to an
  // empty string, which must never blank out the Supabase address (this
  // exact failure broke login on 3 Jul 2026). The anon key is public by
  // design (protected by Supabase RLS) — but the Anthropic API key must
  // NEVER appear here or in any dart-define.
  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const _fallbackUrl = 'https://ijpcynpztcmbgjhocsan.supabase.co';
  static const _fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlqcGN5bnB6dGNtYmdqaG9jc2FuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3NzY2NDYsImV4cCI6MjA5NDM1MjY0Nn0.NmO5hzeiM3Tefh9gu2QMkeApYE2-7Uf91-r-jEcdHDg';

  static const supabaseUrl = _envUrl != '' ? _envUrl : _fallbackUrl;
  static const supabaseAnonKey =
      _envAnonKey != '' ? _envAnonKey : _fallbackAnonKey;

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
