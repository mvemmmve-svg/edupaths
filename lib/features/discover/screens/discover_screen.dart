// lib/features/discover/screens/discover_screen.dart
//
// DISCOVER — swipeable career cards for younger users.
// Swipe right (or tap ❤️) = "more like this": records a like, saves the
// career, and gently boosts future matches. Swipe left (or tap ✖️) = skip.
// Already-swiped careers don't come back.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _deckProvider = FutureProvider<List<Career>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  final all = await ref.watch(allCareersProvider.future);
  if (uid == null) return all..shuffle();
  try {
    final seen = await Supabase.instance.client
        .from('career_feedback')
        .select('career_id')
        .eq('user_id', uid);
    final seenIds =
        (seen as List).map((e) => e['career_id'].toString()).toSet();
    final fresh = all.where((c) => !seenIds.contains(c.id)).toList()
      ..shuffle();
    return fresh;
  } catch (_) {
    return all..shuffle();
  }
});

// ── Free-tier daily swipe limit ────────────────────────────────
// Free users get a fresh hand of swipes each day; Premium is unlimited.
// Counted server-side from today's career_feedback rows so it survives
// refreshes and app restarts.
const kFreeDailySwipes = 10;

final _todaySwipesProvider = FutureProvider<int>((ref) async {
  final sb = Supabase.instance.client;
  final uid = sb.auth.currentUser?.id;
  if (uid == null) return 0;
  final now = DateTime.now();
  final startOfDay =
      DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
  try {
    final res = await sb.from('career_feedback')
        .select('career_id')
        .eq('user_id', uid)
        .gte('created_at', startOfDay);
    return (res as List).length;
  } catch (_) {
    return 0;
  }
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverState();
}

class _DiscoverState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final List<Career> _deck = [];
  bool _loaded = false;
  int _liked = 0;
  int _sessionSwipes = 0; // swipes this session (adds to today's DB count)

  // drag state for the top card
  Offset _drag = Offset.zero;
  late AnimationController _fly;
  Animation<Offset>? _flyAnim;
  bool _flyIsLike = false;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _fly.addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        _commitTopCard(_flyIsLike);
        _fly.reset();
        setState(() => _drag = Offset.zero);
      }
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  void _startFly(bool like) {
    if (_deck.isEmpty || _fly.isAnimating) return;
    final w = MediaQuery.of(context).size.width;
    _flyIsLike = like;
    _flyAnim = Tween<Offset>(
            begin: _drag,
            end: Offset(like ? w * 1.3 : -w * 1.3, _drag.dy - 40))
        .animate(CurvedAnimation(parent: _fly, curve: Curves.easeIn));
    _fly.forward();
  }

  Future<void> _commitTopCard(bool like) async {
    if (_deck.isEmpty) return;
    final career = _deck.removeAt(0);
    if (like) _liked++;
    _sessionSwipes++;
    setState(() {});
    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await sb.from('career_feedback').upsert({
        'user_id': uid,
        'career_id': career.id,
        'verdict': like ? 'like' : 'skip',
      });
      if (like) {
        // A like also bookmarks the career so it appears in Saved —
        // but free accounts cap at kFreeSaveLimit saves.
        final isPrem = ref.read(isPremiumProvider).valueOrNull ?? false;
        final savedCount =
            (ref.read(savedItemsProvider).valueOrNull ?? const []).length;
        if (isPrem || savedCount < kFreeSaveLimit) {
          await DbService.saveItem(
              itemType: 'career', itemId: career.id,
              title: career.displayName, subtitle: career.category);
          ref.invalidate(savedItemsProvider);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              '❤️ Liked! Your Saved list is full — Premium = unlimited saves'),
            duration: Duration(seconds: 2)));
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(_deckProvider);
    if (!_loaded && deckAsync.hasValue) {
      _deck.addAll(deckAsync.value!);
      _loaded = true;
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: const Text('Discover 🔥')),
      body: SafeArea(
        child: Builder(builder: (context) {
          final isPrem = ref.watch(isPremiumProvider).valueOrNull ?? false;
          final baseSwipes = ref.watch(_todaySwipesProvider).valueOrNull ?? 0;
          final used = baseSwipes + _sessionSwipes;
          final left = kFreeDailySwipes - used;

          if (!_loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!isPrem && left <= 0) {
            return _SwipeLimitReached(liked: _liked);
          }
          if (_deck.isEmpty) return _AllDone(liked: _liked);

          return Column(children: [
                    const SizedBox(height: 4),
                    const Text('Swipe right if it sounds like you ➡️',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: AppColors.textMid,
                            fontWeight: FontWeight.w600)),
                    if (!isPrem) Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: left <= 3
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.primaryPale,
                          borderRadius: BorderRadius.circular(999)),
                        child: Text('🔥 $left swipe${left == 1 ? '' : 's'} left today',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: left <= 3
                                ? AppColors.error : AppColors.primary)))),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: math.min(
                              MediaQuery.of(context).size.width - 48, 380),
                          height: 440,
                          child: Stack(children: [
                            // Card underneath (next up)
                            if (_deck.length > 1)
                              Positioned.fill(
                                  child: Transform.scale(
                                      scale: 0.94,
                                      child: _CareerCard(
                                          career: _deck[1], dim: true))),
                            // Top, draggable card
                            Positioned.fill(child: _buildTopCard()),
                          ]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _RoundBtn(
                                emoji: '✖️',
                                color: AppColors.error,
                                onTap: () => _startFly(false)),
                            const SizedBox(width: 20),
                            _RoundBtn(
                                emoji: 'ℹ️',
                                color: AppColors.textMid,
                                small: true,
                                onTap: () => context
                                    .push('/pathway/${_deck.first.id}')),
                            const SizedBox(width: 20),
                            _RoundBtn(
                                emoji: '❤️',
                                color: AppColors.success,
                                onTap: () => _startFly(true)),
                          ]),
                    ),
                  ]);
        }),
      ),
    );
  }

  Widget _buildTopCard() {
    return AnimatedBuilder(
      animation: _fly,
      builder: (context, _) {
        final off = _fly.isAnimating ? _flyAnim!.value : _drag;
        final angle = (off.dx / 600).clamp(-0.35, 0.35);
        final likeOpacity = (off.dx / 120).clamp(0.0, 1.0);
        final skipOpacity = (-off.dx / 120).clamp(0.0, 1.0);
        return GestureDetector(
          onPanUpdate: (d) {
            if (_fly.isAnimating) return;
            setState(() => _drag += d.delta);
          },
          onPanEnd: (_) {
            if (_fly.isAnimating) return;
            if (_drag.dx > 100) {
              _startFly(true);
            } else if (_drag.dx < -100) {
              _startFly(false);
            } else {
              setState(() => _drag = Offset.zero);
            }
          },
          child: Transform.translate(
            offset: off,
            child: Transform.rotate(
              angle: angle,
              child: Stack(children: [
                _CareerCard(career: _deck.first),
                // LIKE / SKIP stamps fade in as you drag
                Positioned(
                    top: 24,
                    left: 20,
                    child: Opacity(
                        opacity: likeOpacity,
                        child: _Stamp(
                            label: 'LIKE', color: AppColors.success))),
                Positioned(
                    top: 24,
                    right: 20,
                    child: Opacity(
                        opacity: skipOpacity,
                        child:
                            _Stamp(label: 'SKIP', color: AppColors.error))),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _CareerCard extends StatelessWidget {
  final Career career;
  final bool dim;
  const _CareerCard({required this.career, this.dim = false});
  @override
  Widget build(BuildContext context) {
    final emojiByCat = {
      'Technology': '💻', 'Health & Medicine': '🩺', 'Engineering': '⚙️',
      'Creative & Media': '🎨', 'Business & Finance': '📈',
      'Education & People': '📚', 'Law & Social Work': '⚖️',
    };
    return Container(
      decoration: BoxDecoration(
        color: dim ? AppColors.bgSurface : AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: dim
            ? null
            : [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10))
              ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(10)),
            child: Text(career.category ?? 'Career',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary))),
        const Spacer(),
        Text(emojiByCat[career.category] ?? '💼',
            style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(career.displayName,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                height: 1.15)),
        const SizedBox(height: 8),
        Text(career.description ?? '',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13.5,
                color: AppColors.textMid,
                height: 1.45)),
        const Spacer(),
        Row(children: [
          const Text('💰', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(career.salaryDisplay,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
        ]),
      ]),
    );
  }
}

class _Stamp extends StatelessWidget {
  final String label;
  final Color color;
  const _Stamp({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2)));
}

class _RoundBtn extends StatelessWidget {
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  final bool small;
  const _RoundBtn(
      {required this.emoji,
      required this.color,
      required this.onTap,
      this.small = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: small ? 48 : 64,
          height: small ? 48 : 64,
          decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: Center(
              child: Text(emoji,
                  style: TextStyle(fontSize: small ? 20 : 28)))));
}

class _AllDone extends StatelessWidget {
  final int liked;
  const _AllDone({required this.liked});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text("You've seen them all!",
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
                liked > 0
                    ? 'You liked $liked career${liked == 1 ? '' : 's'} — they\'re waiting in Saved 🔖'
                    : 'Check back when new careers are added.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: AppColors.textMid)),
            const SizedBox(height: 20),
            PrimaryBtn(
                label: 'View Saved 🔖',
                onPressed: () => context.go('/saved')),
          ])));
}

// ── Daily swipe limit reached (free tier) ──────────────────────
class _SwipeLimitReached extends StatelessWidget {
  final int liked;
  const _SwipeLimitReached({required this.liked});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🔥', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 14),
      Text("That's your $kFreeDailySwipes swipes for today!",
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 19,
          fontWeight: FontWeight.w900, color: AppColors.textDark)),
      const SizedBox(height: 8),
      Text(
        liked > 0
            ? 'You liked $liked career${liked == 1 ? '' : 's'} — nice taste. '
              'Come back tomorrow for a fresh deck, or go unlimited now.'
            : 'Come back tomorrow for a fresh deck of careers — '
              'or go unlimited right now.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 13.5,
          color: AppColors.textMid, height: 1.5)),
      const SizedBox(height: 20),
      PrimaryBtn(label: '⭐ Unlimited swipes with Premium',
        onPressed: () => context.push('/pricing')),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () => context.go('/home'),
        child: const Text('Back to Home', style: TextStyle(
          fontFamily: 'Nunito', fontSize: 13,
          fontWeight: FontWeight.w700, color: AppColors.textMid))),
    ])));
}
