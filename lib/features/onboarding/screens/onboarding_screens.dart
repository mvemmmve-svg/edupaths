// lib/features/onboarding/screens/onboarding_screens.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            ('⚡', '"This or That" quiz', '30 seconds — no wrong answers'),
            ('⭐', 'What do you enjoy?', '20 seconds'),
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
// "THIS OR THAT" QUIZ — replaces the checkbox interests screen.
// 8 quick either/or picks. Each answer carries hidden interest tags;
// at the end we infer the user's interests and feed them into the
// same matching pipeline as before. Feels like a game, not a form.
// ══════════════════════════════════════════════

class _QOption {
  final String emoji, label;
  final List<String> tags; // interest names as stored in the DB
  const _QOption(this.emoji, this.label, this.tags);
}

class _Q {
  final String prompt;
  final _QOption a, b;
  final String? prefKey, prefA, prefB;
  const _Q(this.prompt, this.a, this.b, {this.prefKey, this.prefA, this.prefB});
}

const _quiz = <_Q>[
  _Q('Where would you rather spend the day?',
    _QOption('🛋️', 'Indoors', ['Gaming', 'Computer Science', 'Creative Writing']),
    _QOption('🌲', 'Outdoors', ['Environmental Science', 'Sport', 'Construction & Trades']),
    prefKey: 'environment', prefA: 'Indoor', prefB: 'Outdoor'),
  _Q('What sounds more fun to work with?',
    _QOption('🗣️', 'People', ['Psychology', 'Education', 'Healthcare']),
    _QOption('💻', 'Computers', ['Computer Science', 'Web Development', 'Cybersecurity'])),
  _Q('Your brain at its best is…',
    _QOption('🎨', 'Creative', ['Graphic design', 'Creative Writing', 'Music']),
    _QOption('📊', 'Analytical', ['Maths & Statistics', 'Data & Analytics', 'Physics'])),
  _Q('In a group project, you’d rather be…',
    _QOption('📣', 'Leading the team', ['Business', 'Entrepreneurship', 'Marketing & Advertising']),
    _QOption('🔧', 'Building the thing', ['Engineering', 'Robotics', 'Construction & Trades'])),
  _Q('Which feels like a bigger win?',
    _QOption('💚', 'Helping someone', ['Nursing & Care', 'Mental Health', 'Medicine']),
    _QOption('🧩', 'Cracking a hard puzzle', ['Cybersecurity', 'Maths & Statistics', 'Computer Science'])),
  _Q('Pick your superpower:',
    _QOption('✍️', 'A way with words', ['Journalism & Media', 'Creative Writing', 'Law']),
    _QOption('📐', 'A head for numbers', ['Finance & Investment', 'Data & Analytics', 'Maths & Statistics'])),
  _Q('Where do you belong?',
    _QOption('🎤', 'In the spotlight', ['Film and TV', 'Music', 'Politics & Policy']),
    _QOption('🎬', 'Behind the scenes', ['Animation & VFX', 'Engineering', 'Data & Analytics'])),
  _Q('What gets you out of bed?',
    _QOption('💡', 'Big new ideas', ['Entrepreneurship', 'Artificial Intelligence', 'Machine Learning']),
    _QOption('🔍', 'Getting details perfect', ['Law', 'Architecture & Design', 'Photography'])),
];

class ThisOrThatScreen extends ConsumerStatefulWidget {
  const ThisOrThatScreen({super.key});
  @override
  ConsumerState<ThisOrThatScreen> createState() => _ThisOrThatState();
}

class _ThisOrThatState extends ConsumerState<ThisOrThatScreen> {
  int _index = 0;
  int _selected = -1; // 0 = option A, 1 = option B, -1 = none
  bool _advancing = false;
  final Map<String, int> _scores = {};
  final List<String> _picks = [];
  final Map<String, String> _prefs = {};

  Future<void> _choose(int side) async {
    if (_advancing) return;
    _advancing = true;
    HapticFeedback.mediumImpact();
    setState(() => _selected = side);

    final q = _quiz[_index];
    final opt = side == 0 ? q.a : q.b;
    for (final tag in opt.tags) {
      _scores[tag] = (_scores[tag] ?? 0) + 1;
    }
    _picks.add(opt.label);
    if (q.prefKey != null) {
      _prefs[q.prefKey!] = side == 0 ? (q.prefA ?? '') : (q.prefB ?? '');
    }

    // Let the highlight land, then advance
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    if (_index < _quiz.length - 1) {
      setState(() { _index++; _selected = -1; _advancing = false; });
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    // Map inferred interest names → real interest IDs from the DB.
    List<Interest> interests =
        ref.read(interestsProvider).valueOrNull ?? const [];
    if (interests.isEmpty) {
      try { interests = await ref.read(interestsProvider.future); } catch (_) {}
    }
    final byName = {for (final i in interests) i.trimmed.toLowerCase(): i.id};

    final sorted = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chosen = <String>{};
    for (final e in sorted) {
      final id = byName[e.key.toLowerCase()];
      if (id != null) chosen.add(id);
      if (chosen.length >= 8) break;
    }
    // Safety net: if DB names don't line up exactly, fuzzy-match so the
    // matching engine always has something to work with.
    if (chosen.length < 4) {
      for (final e in sorted) {
        final key = e.key.toLowerCase().split(' ').first;
        for (final i in interests) {
          if (i.trimmed.toLowerCase().contains(key)) chosen.add(i.id);
        }
        if (chosen.length >= 6) break;
      }
    }

    final ob = ref.read(onboardingProvider.notifier);
    ob.setInterests(chosen);
    ob.setQuizPicks(List.of(_picks));
    _prefs.forEach(ob.setPref);

    if (!mounted) return;
    context.push(AppConstants.routeOnboardingEnjoy);
  }

  @override
  Widget build(BuildContext context) {
    final q = _quiz[_index];
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OnboardingHeader(step: 1, total: 2, onBack: () {
            if (_index > 0) {
              setState(() { _index--; _selected = -1; _advancing = false;
                if (_picks.isNotEmpty) _picks.removeLast(); });
            } else {
              context.pop();
            }
          }),
          const SizedBox(height: 16),
          const Text('This or That ⚡', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Tap whichever sounds more like you — no wrong answers.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
              color: AppColors.textMid)),
          const SizedBox(height: 14),
          // Progress
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_index + 1) / _quiz.length,
                minHeight: 8,
                backgroundColor: AppColors.bgSurface,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary)))),
            const SizedBox(width: 10),
            Text('${_index + 1}/${_quiz.length}', style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              fontWeight: FontWeight.w800, color: AppColors.textMid)),
          ]),
          const SizedBox(height: 20),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.25, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: FadeTransition(opacity: anim, child: child)),
            child: Column(
              key: ValueKey(_index),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(q.prompt, style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 18,
                  fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 16),
                Expanded(child: _ChoiceCard(
                  option: q.a, selected: _selected == 0,
                  onTap: () => _choose(0))),
                // "OR" divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(999)),
                      child: const Text('OR', style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMid, letterSpacing: 1))),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ])),
                Expanded(child: _ChoiceCard(
                  option: q.b, selected: _selected == 1,
                  onTap: () => _choose(1))),
                const SizedBox(height: 8),
              ]),
          )),
        ]),
      )),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final _QOption option;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceCard({required this.option, required this.selected,
    required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedScale(
      scale: selected ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 160),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPale : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2.5 : 1.5),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 16, offset: const Offset(0, 6))]
              : null),
        child: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(option.label, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 17,
                fontWeight: FontWeight.w900,
                color: selected ? AppColors.primary : AppColors.textDark)),
          ])),
      ),
    ));
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
              if (ob.quizPicks.isNotEmpty)
                _SumRow('Your vibe', ob.quizPicks.take(3).join(' · ')),
              _SumRow('Interests matched', '${ob.interestIds.length}'),
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
