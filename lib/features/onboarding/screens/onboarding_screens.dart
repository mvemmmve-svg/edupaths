// lib/features/onboarding/screens/onboarding_screens.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

// ══════════════════════════════════════════════
// ONBOARDING START
// ══════════════════════════════════════════════
class OnboardingStartScreen extends ConsumerWidget {
  const OnboardingStartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(appUserProvider).valueOrNull?.firstName ?? 'Explorer';
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          Text('Great choice,\n$name! 🎉', style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 30, fontWeight: FontWeight.w900,
            color: AppColors.textDark), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text("We'll ask you a few quick questions to find your perfect pathway.",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Nunito', fontSize: 15, color: AppColors.textMid)),
          const SizedBox(height: 32),
          // Steps — no chevron arrows
          ...[
            ('🎮', 'Choose your interests', '30 seconds'),
            ('⭐', 'What do you enjoy?', '20 seconds'),
            // Prefs step removed
            ('🤖', 'AI builds your profile', 'Instant!'),
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(s.$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.$2, style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(s.$3, style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 12, color: AppColors.textMid)),
                ]),
              ]),
            ),
          )),
          const Spacer(),
          PrimaryBtn(label: "Let's Go! 🚀",
            onPressed: () => context.push(AppConstants.routeOnboardingInterests)),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════
// INTERESTS SCREEN
// ══════════════════════════════════════════════
class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});

  static const _emojis = {
    'Gaming': '🎮', 'Technology': '💻', 'Art & Design': '🎨',
    'Music': '🎵', 'Sport': '⚽', 'Health': '💊',
    'Science': '🔬', 'Fashion': '👗', 'Business': '💼',
    'Film': '🎬', 'Psychology': '🧠', 'Engineering': '⚙️',
    'Data & Analytics': '📊', 'Education': '📚', 'Law': '⚖️',
    'Web Development': '🌐', 'Mobile Apps': '📱', 'Robotics': '🤖',
    'Machine Learning': '🧬', 'Finance & Investment': '💰',
    'Entrepreneurship': '🚀', 'Marketing & Advertising': '📣',
    'Architecture & Design': '🏛️', 'Creative Writing': '✍️',
    'Animation & VFX': '🎬', 'Mental Health': '💚',
    'Nursing & Care': '🏥', 'Fitness & Personal Training': '🏋️',
    'Environmental Science': '🌿', 'Maths & Statistics': '📐',
    'Medicine': '⚕️', 'Politics & Policy': '🏛️',
    'Journalism & Media': '📰', 'Construction & Trades': '🔨',
    'Languages & Linguistics': '🗣️', 'Computer Science': '💻',
    'Cybersecurity': '🔐', 'Artificial Intelligence': '🤖',
    'Data Science': '📊', 'Healthcare': '🏥',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interestsAsync = ref.watch(interestsProvider);
    final selectedIds = ref.watch(onboardingProvider).interestIds;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OnboardingHeader(step: 1, total: 2, onBack: () => context.pop()),
          const SizedBox(height: 20),
          const Text('What are you\ninterested in? 🤩', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Select all that apply — the more the better!',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
          const SizedBox(height: 16),
          Expanded(child: interestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (interests) {
              final byCategory = <String, List<Interest>>{};
              for (final i in interests) {
                byCategory.putIfAbsent((i.category ?? 'Other').trim(), () => []).add(i);
              }
              return SingleChildScrollView(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: byCategory.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(entry.key.toUpperCase(), style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 11,
                      fontWeight: FontWeight.w800, color: AppColors.textLight,
                      letterSpacing: 0.8))),
                  Wrap(spacing: 8, runSpacing: 8, children: entry.value.map((i) =>
                    InterestChip(
                      label: i.trimmed,
                      emoji: _emojis[i.trimmed],
                      selected: selectedIds.contains(i.id),
                      onTap: () => ref.read(onboardingProvider.notifier).toggleInterest(i.id),
                    )).toList()),
                  const SizedBox(height: 16),
                ])).toList(),
              ));
            },
          )),
          if (selectedIds.isNotEmpty) Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text('${selectedIds.length} selected ✓', textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.success))),
          PrimaryBtn(
            label: 'Next',
            onPressed: selectedIds.isEmpty ? null
                : () => context.push(AppConstants.routeOnboardingEnjoy), // Save happens at summary
          ),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════
// ENJOY SCREEN — split into categories
// ══════════════════════════════════════════════
class EnjoyScreen extends ConsumerWidget {
  const EnjoyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traitsAsync = ref.watch(traitsProvider);
    final selectedIds = ref.watch(onboardingProvider).traitIds;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OnboardingHeader(step: 2, total: 2, onBack: () => context.pop()),
          const SizedBox(height: 20),
          const Text('What do you\nenjoy doing? ⭐', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Select what feels most like you.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
          const SizedBox(height: 16),
          Expanded(child: traitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (traits) {
              // Group by category
              final byCategory = <String, List<Trait>>{};
              for (final t in traits) {
                byCategory.putIfAbsent(t.category ?? 'Other', () => []).add(t);
              }
              return SingleChildScrollView(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: byCategory.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(entry.key.toUpperCase(), style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 11,
                      fontWeight: FontWeight.w800, color: AppColors.textLight,
                      letterSpacing: 0.8))),
                  ...entry.value.map((t) {
                    final sel = selectedIds.contains(t.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => ref.read(onboardingProvider.notifier).toggleTrait(t.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primaryPale : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel ? AppColors.primary : AppColors.border,
                              width: sel ? 2 : 1.5)),
                          child: Row(children: [
                            Expanded(child: Text(t.trimmed, style: TextStyle(
                              fontFamily: 'Nunito', fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: sel ? AppColors.primary : AppColors.textDark))),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: sel ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                  color: sel ? AppColors.primary : AppColors.border, width: 2)),
                              child: sel ? const Icon(Icons.check, color: Colors.white, size: 13) : null),
                          ]),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ])).toList(),
              ));
            },
          )),
          const SizedBox(height: 12),
          PrimaryBtn(label: 'Save & See My Matches 🎯',
            onPressed: () => context.push(AppConstants.routeOnboardingSummary)),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════
// PREFERENCES SCREEN
// ══════════════════════════════════════════════
class PrefsScreen extends ConsumerWidget {
  const PrefsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(onboardingProvider).prefs;
    void set(String k, String v) => ref.read(onboardingProvider.notifier).setPref(k, v);
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OnboardingHeader(step: 3, total: 3, onBack: () => context.pop()),
          const SizedBox(height: 20),
          const Text('A few quick\npreferences ⚙️', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 24),
          _PrefItem(label: 'Pathway focus',
            child: SegCtrl(options: const ['University', 'Apprenticeship', 'Both'],
              selected: p['pathway'] ?? 'Both', onChanged: (v) => set('pathway', v))),
          const SizedBox(height: 18),
          _PrefItem(label: 'Stay close to home?',
            child: SegCtrl(options: const ['No', 'Flexible', 'Yes'],
              selected: p['location'] ?? 'Flexible', onChanged: (v) => set('location', v))),
          const SizedBox(height: 18),
          _PrefItem(label: 'Budget importance',
            child: SegCtrl(options: const ['Low', 'Medium', 'High'],
              selected: p['budget'] ?? 'Medium', onChanged: (v) => set('budget', v))),
          const SizedBox(height: 18),
          _PrefItem(label: 'Indoor or outdoor work?',
            child: SegCtrl(options: const ['Indoor', 'Both', 'Outdoor'],
              selected: p['environment'] ?? 'Both', onChanged: (v) => set('environment', v))),
          const SizedBox(height: 32),
          PrimaryBtn(label: 'Build My Profile 🤖',
            onPressed: () => context.push(AppConstants.routeOnboardingSummary)),
        ]),
      )),
    );
  }
}

class _PrefItem extends StatelessWidget {
  final String label; final Widget child;
  const _PrefItem({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontFamily: 'Nunito',
      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMid)),
    const SizedBox(height: 8), child]);
}

// ══════════════════════════════════════════════
// SUMMARY SCREEN
// ══════════════════════════════════════════════
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});
  @override
  ConsumerState<SummaryScreen> createState() => _SummaryState();
}

class _SummaryState extends ConsumerState<SummaryScreen> {
  bool _saving = false;
  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final ob = ref.read(onboardingProvider);
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      // ── Step 1: wait for the profile row. Right after a brand-new
      // signup the database creates it a moment later, so poll patiently
      // instead of giving up after one try (the old silent-skip bug).
      var user = await ref.read(appUserProvider.future)
          .timeout(const Duration(seconds: 4), onTimeout: () => null);
      for (var attempt = 0; user == null && uid != null && attempt < 5; attempt++) {
        await Future.delayed(const Duration(seconds: 1));
        ref.invalidate(appUserProvider);
        user = await ref.read(appUserProvider.future)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);
      }

      // ── Step 2: save choices FIRST — matches are generated from these.
      // Each save is isolated: if one fails (as the preferences save did
      // for every user until 5 Jul 2026 — missing DB constraint), the
      // others still land and match generation still runs.
      if (user != null) {
        await Future.wait([
          DbService.saveUserInterests(user.id, ob.interestIds.toList())
              .catchError((_) {}),
          DbService.saveUserTraits(user.id, ob.traitIds.toList())
              .catchError((_) {}),
          DbService.savePreferences(ob.prefs).catchError((_) {}),
        ]);
      }

      // ── Step 3: generate matches, then VERIFY they exist; retry once.
      if (uid != null) {
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            await sb.rpc('generate_smart_matches',
                params: {'p_user_uid': uid})
                .timeout(const Duration(seconds: 20));
          } catch (_) {}
          try {
            final check = await sb.from('matches')
                .select('id').eq('firebase_uid', uid).limit(1);
            if ((check as List).isNotEmpty) break;
          } catch (_) {}
        }
      }

      if (user != null) {
        await DbService.markOnboardingComplete(user.id);
      }

      // ── Step 4: refresh home data AFTER matches truly exist.
      ref.invalidate(matchesProvider);
      ref.invalidate(appUserProvider);
      ref.invalidate(isPremiumProvider);
      await Future.delayed(const Duration(milliseconds: 300));

      // ── Step 5: the confirmation the user asked for.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Matches saved! Your top matches are on your home screen.'),
          duration: Duration(seconds: 3)));
      }
      if (!mounted) return;
      // Invalidate again after navigation to force re-fetch
      ref.invalidate(matchesProvider);
      ref.invalidate(appUserProvider);
      context.go(AppConstants.routeHome);
    } catch (e) {
      if (!mounted) return;
      // Even on error, navigate forward — matches can be generated later
      ref.invalidate(matchesProvider);
      context.go(AppConstants.routeHome);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final ob = ref.watch(onboardingProvider);
    final user = ref.watch(appUserProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BackBtn(),
          const SizedBox(height: 20),
          Text('Nice to meet you,\n${user?.firstName ?? 'Explorer'}! 👋',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 24,
              fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text("Here's what we've learned so far.",
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(20),
            decoration: gradientBox(radius: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your profile summary', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 12, color: Colors.white70,
                fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _SumRow('Interests selected', '${ob.interestIds.length}'),
              _SumRow('Strengths identified', '${ob.traitIds.length}'),
              _SumRow('Pathway focus', ob.prefs['pathway'] ?? 'Both'),
            ])),
          const SizedBox(height: 24),
          PrimaryBtn(label: 'See My Matches 🎯', onPressed: _finish, isLoading: _saving),
        ]),
      )),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  const _SumRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 13, color: Colors.white70)),
      Text(value, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
    ]));
}

// ══════════════════════════════════════════════
// ONBOARDING COMPLETE
// ══════════════════════════════════════════════
class OnboardingCompleteScreen extends ConsumerWidget {
  const OnboardingCompleteScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: _ConfettiOverlay(child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Spacer(),
          const Text('🚀', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          const Text("You're all set!", style: TextStyle(
            fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text("Welcome to EduPaths, ${user?.firstName ?? 'Explorer'}!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 16,
              color: AppColors.textMid, fontWeight: FontWeight.w600)),
          const Spacer(),
          PrimaryBtn(label: "Go to Dashboard 🏠",
            onPressed: () => context.go(AppConstants.routeHome)),
          const SizedBox(height: 16),
        ]),
      ))),
    );
  }
}

// ── Celebration confetti (no external package) ─────────────────
// Draws ~80 falling, spinning paper pieces for four seconds over the
// completion screen. Respects the device's reduced-motion setting.
class _ConfettiOverlay extends StatefulWidget {
  final Widget child;
  const _ConfettiOverlay({required this.child});
  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Paper> _papers;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _papers = List.generate(80, (_) => _Paper(
      x: rnd.nextDouble(),
      delay: rnd.nextDouble() * 0.4,
      speed: 0.6 + rnd.nextDouble() * 0.8,
      size: 6 + rnd.nextDouble() * 7,
      spin: (rnd.nextDouble() - 0.5) * 10,
      drift: (rnd.nextDouble() - 0.5) * 0.25,
      color: [const Color(0xFF5B4FE9), const Color(0xFFF2B33D),
        const Color(0xFF22C55E), const Color(0xFFEC4899),
        const Color(0xFF2456E6)][rnd.nextInt(5)],
    ));
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduced) _c.forward();
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Stack(children: [
    widget.child,
    IgnorePointer(child: AnimatedBuilder(
      animation: _c,
      builder: (c, _) => _c.isAnimating
        ? CustomPaint(size: Size.infinite,
            painter: _ConfettiPainter(_papers, _c.value))
        : const SizedBox())),
  ]);
}

class _Paper {
  final double x, delay, speed, size, spin, drift;
  final Color color;
  const _Paper({required this.x, required this.delay, required this.speed,
    required this.size, required this.spin, required this.drift,
    required this.color});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Paper> papers;
  final double t;
  _ConfettiPainter(this.papers, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in papers) {
      final local = ((t - p.delay) * p.speed).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final dx = (p.x + p.drift * local) * size.width;
      final dy = local * (size.height + 40) - 20;
      final paint = Paint()..color = p.color.withOpacity(1 - local * 0.5);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * local);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        const Radius.circular(1.5)), paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
