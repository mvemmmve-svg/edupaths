// lib/core/services/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../shared/models/models.dart';
import 'db_service.dart';

// ── Auth stream — single source of truth ──────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// ── Current UID — derived from auth stream ────────────────────
final currentUidProvider = Provider<String?>((ref) {
  // Watch auth stream so this updates on login/logout
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser?.id;
});

// ── App user — only re-fetches when UID changes ───────────────
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return DbService.getUserByUid(uid);
});

// ── Matches — only re-fetches when UID changes ────────────────
final matchesProvider = FutureProvider<List<AppMatch>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];
  return DbService.getMatches();
});

// ── Saved items ───────────────────────────────────────────────
final savedItemsProvider = FutureProvider<List<SavedItem>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];
  return DbService.getSavedItems();
});

// ── Subscription ──────────────────────────────────────────────
final subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return DbService.getSubscription();
});

// ── isPremium ─────────────────────────────────────────────────
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final sub = await ref.watch(subscriptionProvider.future);
  return sub != null &&
    (sub.plan == 'premium' || sub.plan == 'premium_plus') &&
    sub.status == 'active';
});

// ── Search query ──────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Saved filter ──────────────────────────────────────────────
// ── Roadmap selected career ──────────────────────────────────────────────
final roadmapCareerIdProvider = StateProvider<String>((ref) => '');

// Lowercase 'all' — the Saved screen chips and item types are lowercase,
// so the old default 'All' matched nothing until a chip was clicked.
final savedFilterProvider = StateProvider<String>((ref) => 'all');

// ── Interests ─────────────────────────────────────────────────
final interestsProvider = FutureProvider<List<Interest>>((ref) async {
  return DbService.getAllInterests();
});

// ── Traits ────────────────────────────────────────────────────
final traitsProvider = FutureProvider<List<Trait>>((ref) async {
  return DbService.getAllTraits();
});

// ── All careers ───────────────────────────────────────────────
final allCareersProvider = FutureProvider<List<Career>>((ref) async {
  return DbService.getAllCareers();
});

// ── Filtered careers ──────────────────────────────────────────
final filteredCareersProvider = FutureProvider<List<Career>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final all = await DbService.getAllCareers();
  if (query.isEmpty) return all;
  return all.where((c) =>
    c.displayName.toLowerCase().contains(query.toLowerCase())).toList();
});

// ── Career by ID ──────────────────────────────────────────────
final careerByIdProvider =
    FutureProvider.family<Career?, String>((ref, id) async {
  return DbService.getCareerById(id);
});

// ── All courses ───────────────────────────────────────────────
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  return DbService.getAllCourses();
});

// ── Course by ID ──────────────────────────────────────────────
final courseByIdProvider =
    FutureProvider.family<Course?, String>((ref, id) async {
  return DbService.getCourseById(id);
});

// ── Onboarding state ──────────────────────────────────────────
class OnboardingState {
  final Set<String> interestIds;
  final Set<String> traitIds;
  final Map<String, String> prefs;
  final String role;
  const OnboardingState({
    this.interestIds = const {},
    this.traitIds = const {},
    this.prefs = const {},
    this.role = 'student',
  });
  OnboardingState copyWith({
    Set<String>? interestIds, Set<String>? traitIds,
    Map<String, String>? prefs, String? role,
  }) => OnboardingState(
    interestIds: interestIds ?? this.interestIds,
    traitIds: traitIds ?? this.traitIds,
    prefs: prefs ?? this.prefs,
    role: role ?? this.role,
  );
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();
  void toggleInterest(String id) {
    final s = Set<String>.from(state.interestIds);
    s.contains(id) ? s.remove(id) : s.add(id);
    state = state.copyWith(interestIds: s);
  }
  void toggleTrait(String id) {
    final s = Set<String>.from(state.traitIds);
    s.contains(id) ? s.remove(id) : s.add(id);
    state = state.copyWith(traitIds: s);
  }
  void setPref(String k, String v) {
    final p = Map<String, String>.from(state.prefs);
    p[k] = v;
    state = state.copyWith(prefs: p);
  }
  void setRole(String r) => state = state.copyWith(role: r);
  void reset() => state = const OnboardingState();
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new);


// ── Unread support replies (item: bell notification) ──────────
// Counts admin replies the user hasn't seen; drives the red dot on the
// bell and the banner at the top of the Notifications screen.
final unreadSupportProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return 0;
  try {
    final res = await Supabase.instance.client
        .from('support_messages')
        .select('id')
        .eq('user_id', uid)
        .eq('sender', 'admin')
        .eq('read_by_user', false);
    return (res as List).length;
  } catch (_) {
    return 0;
  }
});


// ── Daily streak (interactivity) ───────────────────────────────
// Records today's visit and counts how many consecutive days the
// person has opened the app. Drives the 🔥 chip on Home.
final streakProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return 0;
  final sb = Supabase.instance.client;
  try {
    await sb.from('user_checkins').upsert({'user_id': uid});
  } catch (_) {}
  try {
    final rows = await sb.from('user_checkins')
        .select('day').eq('user_id', uid)
        .order('day', ascending: false).limit(60);
    final days = (rows as List)
        .map((e) => DateTime.parse(e['day'] as String))
        .toList();
    if (days.isEmpty) return 0;
    var streak = 0;
    var cursor = DateTime.now();
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    cursor = dateOnly(cursor);
    for (final d in days) {
      final dd = dateOnly(d);
      if (dd == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (dd.isBefore(cursor)) {
        break;
      }
    }
    return streak;
  } catch (_) {
    return 0;
  }
});


// ── Badges (interactivity) — computed from real activity ──────
final swipeCountProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return 0;
  try {
    final res = await Supabase.instance.client
        .from('career_feedback').select('career_id').eq('user_id', uid);
    return (res as List).length;
  } catch (_) { return 0; }
});
