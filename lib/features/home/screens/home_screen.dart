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
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              userAsync.when(
                loading: () => const ShimmerCard(height: 50),
                error: (_, __) => const SizedBox(),
                data: (user) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi, ${user?.firstName ?? 'Explorer'}! 👋',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                      color: AppColors.textMid, fontWeight: FontWeight.w600)),
                  Text("Let's explore your future.",
                    style: Theme.of(context).textTheme.headlineMedium),
                ]),
              ),
              Row(children: [
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
                  loading: () => const CircleAvatar(radius: 20, backgroundColor: AppColors.primaryPale),
                  error: (_, __) => const SizedBox(),
                  data: (user) => GestureDetector(
                    onTap: () => context.go(AppConstants.routeProfile),
                    child: CircleAvatar(radius: 20, backgroundColor: AppColors.primary,
                      child: Text(user?.initials ?? 'E',
                        style: const TextStyle(fontFamily: 'Nunito',
                          color: Colors.white, fontWeight: FontWeight.w800)))),
                ),
              ]),
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

            const SizedBox(height: 20),

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
              action: isPrem ? 'See all' : '🔒 Premium', onAction: isPrem
                ? () => _showAllMatches(context, ref)
                : () => context.push(AppConstants.routePricing)),
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
                      child: Row(children: [
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
                    ));
                }).toList());
              },
            ),

            const SizedBox(height: 24),

            // ── Browse Categories ────────────────────
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
              action: isPrem ? 'See all' : '🔒 Premium', onAction: isPrem
                ? () => _showAllMatches(context, ref)
                : () => context.push(AppConstants.routePricing)),
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
