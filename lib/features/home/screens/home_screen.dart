// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../../core/constants/app_constants.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../shared/models/models.dart';
import '../../../core/utils/responsive.dart';


void _showAllMatches(BuildContext context, WidgetRef ref) {
  final matches = ref.read(matchesProvider).valueOrNull ?? [];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        Container(margin: const EdgeInsets.only(top: 12, bottom: 16),
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border,
            borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('All Your Matches 🎯', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900))),
        const SizedBox(height: 8),
        Expanded(child: matches.isEmpty
          ? const EmptyState(emoji: '🔍', title: 'No matches yet',
              subtitle: 'Complete onboarding to see your career matches')
          : ListView.separated(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final m = matches[i] as AppMatch;
              return EduCard(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/pathway/${m.careerId}');
                },
                child: Row(children: [
                  MatchRing(pct: m.matchScore, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.careerName, style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 14,
                      fontWeight: FontWeight.w800)),
                    if (m.avgSalary != null) Text(m.avgSalary!,
                      style: const TextStyle(fontFamily: 'Nunito',
                        fontSize: 12, color: AppColors.textMid)),
                  ])),
                  const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
                ]),
              );
            },
          )),
      ]),
    ),
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync    = ref.watch(appUserProvider);
    final matchesAsync = ref.watch(matchesProvider);
    final careersAsync = ref.watch(allCareersProvider);
    final isPrem       = ref.watch(isPremiumProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(matchesProvider);
          ref.invalidate(allCareersProvider);
          ref.invalidate(appUserProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ───────────────────────────────
            // One row, everything vertically centred. The greeting flexes
            // and ellipsises; the streak pill, bell and avatar are ALL
            // exactly 40px tall so nothing sits off-baseline, and they
            // never get pushed off-screen on small phones (iPhone SE etc).
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: userAsync.when(
                loading: () => const ShimmerCard(height: 44),
                error: (_, __) => const SizedBox(height: 44),
                data: (user) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Hi, ${user?.firstName ?? 'Explorer'}! 👋',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                        color: AppColors.textMid, fontWeight: FontWeight.w600)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text("Let's explore your future.",
                        maxLines: 1,
                        style: Theme.of(context).textTheme.headlineMedium)),
                  ]),
              )),
              const SizedBox(width: 12),
              // 🔥 streak chip — consecutive days in the app
              Consumer(builder: (c, r, _) {
                final n = r.watch(streakProvider).valueOrNull ?? 0;
                if (n < 2) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentOrange.withOpacity(0.4))),
                    child: Text('🔥 $n', style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentOrange))));
              }),
              GestureDetector(
                onTap: () => context.push(AppConstants.routeNotifications),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border)),
                    child: const Icon(Icons.notifications_outlined,
                      size: 20, color: AppColors.textMid)),
                  // Red badge = unread support replies waiting
                  Positioned(right: -4, top: -4,
                    child: Consumer(builder: (c, r, _) {
                      final n = r.watch(unreadSupportProvider).valueOrNull ?? 0;
                      if (n == 0) return const SizedBox();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5)),
                        child: Text('$n', style: const TextStyle(
                          color: Colors.white, fontSize: 10,
                          fontFamily: 'Nunito', fontWeight: FontWeight.w800)));
                    })),
                ]),
              ),
              const SizedBox(width: 8),
              userAsync.when(
                loading: () => const SizedBox(width: 40, height: 40,
                  child: CircleAvatar(backgroundColor: AppColors.primaryPale)),
                error: (_, __) => const SizedBox(width: 40, height: 40),
                data: (user) => GestureDetector(
                  onTap: () => context.go(AppConstants.routeProfile),
                  child: SizedBox(width: 40, height: 40,
                    child: CircleAvatar(backgroundColor: AppColors.primary,
                      child: Text(user?.initials ?? 'E',
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                          color: Colors.white, fontWeight: FontWeight.w800))))),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Upgrade banner ───────────────────────
            if (!isPrem) GestureDetector(
              onTap: () => context.push(AppConstants.routePricing),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.accentYellow.withOpacity(0.15),
                    AppColors.accentOrange.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentYellow.withOpacity(0.4))),
                child: Row(children: [
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text('Unlock unlimited matches!',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    Text('Upgrade to Premium — 7-day free trial',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                        color: AppColors.textMid)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.accentOrange),
                ]),
              ),
            ),

            const SizedBox(height: 14),

            // ── Discover deck entry (interactivity) ──
            // Deliberately the loudest thing on the page: hot gradient,
            // fanned card-deck graphic and a gentle pulse so it reads as
            // a GAME, not another list row.
            const _DiscoverPromoCard(),

            const SizedBox(height: 14),

            // ── Career of the Day (rotates daily) ──
            Consumer(builder: (c, r, _) {
              final careers = r.watch(allCareersProvider).valueOrNull;
              if (careers == null || careers.isEmpty) return const SizedBox();
              final today = DateTime.now();
              final idx = (today.year * 372 + today.month * 31 + today.day)
                  % careers.length;
              final cotd = careers[idx];
              return GestureDetector(
                onTap: () => context.push('/pathway/${cotd.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    const Text('📅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Career of the day',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMid)),
                      Text(cotd.displayName, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark)),
                    ])),
                    Text(cotd.salaryDisplay, style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 12,
                      fontWeight: FontWeight.w800, color: AppColors.success)),
                  ]),
                ));
            }),

            const SizedBox(height: 14),

            // ── Top AI Match Hero ────────────────────
            matchesAsync.when(
              loading: () => const ShimmerCard(height: 150),
              error: (_, __) => const SizedBox(),
              data: (matches) {
                if (matches.isEmpty) {
                  // Show generating state if user is onboarded
                  final user = ref.watch(appUserProvider).valueOrNull;
                  if (user?.onboardingComplete == true) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: gradientBox(radius: 20),
                      child: Column(children: [
                        const Text('🎯', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 12),
                        const Text('Your matches are almost ready',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 16,
                            fontWeight: FontWeight.w800, color: Colors.white),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        // Active recovery: re-run the matching engine, then
                        // refresh. Covers cases where generation was
                        // interrupted during onboarding.
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary),
                          onPressed: () async {
                            final uid = Supabase.instance.client
                                .auth.currentUser?.id;
                            if (uid != null) {
                              try {
                                await Supabase.instance.client.rpc(
                                  'generate_smart_matches',
                                  params: {'p_user_uid': uid});
                              } catch (_) {}
                            }
                            ref.invalidate(matchesProvider);
                          },
                          child: const Text('Show my matches',
                            style: TextStyle(fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800))),
                      ]));
                  }
                  return const SizedBox();
                }
                final top = matches.first;
                return GestureDetector(
                  onTap: () => context.push('/pathway/${top.careerId}'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: gradientBox(radius: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999)),
                          child: const Text('✨ AI Top Pick',
                            style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                              fontWeight: FontWeight.w800, color: Colors.white))),
                        const Spacer(),
                        MatchRing(pct: top.matchScore, size: 46),
                      ]),
                      const SizedBox(height: 12),
                      Text(top.careerName, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(top.avgSalary != null ? 'Avg: ${top.avgSalary}' : 'Explore this career',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                          color: Colors.white.withOpacity(0.75))),
                      const SizedBox(height: 8),
                      // Why we matched you — right on the card
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('✨ ', style: TextStyle(fontSize: 12)),
                        Flexible(child: Text(friendlyMatchReason(top.matchReason),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white, height: 1.35))),
                      ]),
                      const SizedBox(height: 14),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.35))),
                        child: const Text('View Full Pathway →',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                            fontWeight: FontWeight.w700, color: Colors.white))),
                    ]),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Top Matches ──────────────────────────
            SectionHeader(title: 'Top Matches for You',
              action: 'See all',
              onAction: () => _showAllMatches(context, ref)),
            const SizedBox(height: 12),
            matchesAsync.when(
              loading: () => Column(children: const [
                ShimmerCard(), SizedBox(height: 10), ShimmerCard()]),
              error: (_, __) => EmptyState(emoji: '🔍',
                title: 'No matches yet',
                subtitle: 'Complete onboarding to see your career matches'),
              data: (matches) {
                if (matches.isEmpty) return EmptyState(
                  emoji: '🎯', title: 'No matches yet',
                  subtitle: 'Complete onboarding to see your personalised career matches',
                  actionLabel: 'Get Started',
                  onAction: () => context.push(AppConstants.routeWhoAreYou));
                return Column(children: matches.take(3).toList().asMap().entries.map((e) {
                  final m = e.value;
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: EduCard(
                      onTap: () => context.push('/pathway/${m.careerId}'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(children: [
                          Container(width: 48, height: 48,
                            decoration: BoxDecoration(color: AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.work_rounded, color: AppColors.primary, size: 24)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text(m.careerName, style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800)),
                            if (m.avgSalary != null) Text('Avg: ${m.avgSalary}',
                              style: const TextStyle(fontFamily: 'Nunito',
                                fontSize: 12, color: AppColors.textMid)),
                          ])),
                          MatchRing(pct: m.matchScore),
                        ]),
                        // Why we matched you — tap for the full breakdown
                        MatchReasonLine(reason: m.matchReason, careerId: m.careerId),
                      ]),
                    ));
                }).toList());
              },
            ),

            const SizedBox(height: 24),

            // ── Browse Categories ────────────────────
            // Browsing is FREE — the hook comes first, the paywall sits on
            // deeper features (compare, unlimited saves, full roadmap).
            const SectionHeader(title: 'Browse by Category'),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _CatCard(emoji: '💻', label: 'Technology', color: AppColors.primaryPale,
                  onTap: () => context.push('/careers-by-category/Technology')),
                const SizedBox(width: 10),
                _CatCard(emoji: '🎨', label: 'Creative',
                  color: const Color(0xFFFDF2F8),
                  onTap: () => context.push('/careers-by-category/Creative & Media')),
                const SizedBox(width: 10),
                _CatCard(emoji: '💼', label: 'Business',
                  color: const Color(0xFFFFFBEB),
                  onTap: () => context.push('/careers-by-category/Business & Finance')),
                const SizedBox(width: 10),
                _CatCard(emoji: '💊', label: 'Health',
                  color: const Color(0xFFECFDF5),
                  onTap: () => context.push('/careers-by-category/Health & Medicine')),
                const SizedBox(width: 10),
                _CatCard(emoji: '🔬', label: 'Science',
                  color: const Color(0xFFEFF6FF),
                  onTap: () => context.push('/careers-by-category/Engineering')),
                const SizedBox(width: 10),
                _CatCard(emoji: '⚖️', label: 'Law',
                  color: const Color(0xFFF5F3FF),
                  onTap: () => context.push('/careers-by-category/Law & Social Work')),
              ]),
            ),

            const SizedBox(height: 24),

            // ── All Careers ──────────────────────────
            SectionHeader(title: 'All Careers',
              action: 'See all',
              onAction: () => context.go(AppConstants.routeExplore)),
            const SizedBox(height: 12),
            careersAsync.when(
              loading: () => const ShimmerCard(),
              error: (_, __) => const SizedBox(),
              data: (careers) => Column(children: careers.take(6).map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EduCard(
                  onTap: () => context.push('/pathway/${c.id}'),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.work_outline_rounded,
                        color: AppColors.primary, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(c.displayName, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(c.salaryDisplay, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                  ]),
                ),
              )).toList()),
            ),

            const SizedBox(height: 100),
          ]),
        ),
      )),
    );
  }
}

class _CatCard extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  const _CatCard({required this.emoji, required this.label,
    required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════
// DISCOVER PROMO CARD — the loudest card on Home.
// Hot pink→orange gradient, fanned mini card-deck graphic, and a
// slow breathe animation so the eye can't skip past it.
// ══════════════════════════════════════════════
class _DiscoverPromoCard extends StatefulWidget {
  const _DiscoverPromoCard();
  @override
  State<_DiscoverPromoCard> createState() => _DiscoverPromoCardState();
}

class _DiscoverPromoCardState extends State<_DiscoverPromoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _miniCard(String emoji, double angle, Color tint) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 40, height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18),
          blurRadius: 6, offset: const Offset(0, 3))]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Container(width: 22, height: 4, decoration: BoxDecoration(
          color: tint.withOpacity(0.35),
          borderRadius: BorderRadius.circular(2))),
      ])));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: 1.0 + 0.015 * _pulse.value, child: child),
      child: GestureDetector(
        onTap: () => context.push('/discover'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFFF5FA2), Color(0xFFFF8C42)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: const Color(0xFFFF5FA2).withOpacity(0.45),
              blurRadius: 18, offset: const Offset(0, 8))]),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(999)),
                child: const Text('🔥 SWIPE GAME', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 9,
                  fontWeight: FontWeight.w900, color: Colors.white,
                  letterSpacing: 1))),
              const SizedBox(height: 8),
              const Text('Discover Careers', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 19,
                fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 2),
              const Text('Swipe right on your future.\nLike it or bin it 👉',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                  fontWeight: FontWeight.w600, color: Colors.white,
                  height: 1.35)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999)),
                child: const Text('Play now →', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF5FA2)))),
            ])),
            const SizedBox(width: 6),
            // Fanned mini card deck
            SizedBox(width: 86, height: 78, child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(left: 0,
                  child: _miniCard('🩺', -0.22, const Color(0xFF0E9B76))),
                Positioned(right: 0,
                  child: _miniCard('🎨', 0.22, const Color(0xFFEC4899))),
                _miniCard('🚀', 0, const Color(0xFF5B4FE9)),
              ])),
          ]),
        ),
      ));
  }
}
