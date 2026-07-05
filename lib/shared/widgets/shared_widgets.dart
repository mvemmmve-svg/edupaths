// lib/shared/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/providers.dart';
import '../../core/theme/app_theme.dart';

// ── Buttons ───────────────────────────────────────────────────
class PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  const PrimaryBtn({super.key, required this.label, this.onPressed,
    this.isLoading = false, this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 54,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        splashFactory: InkRipple.splashFactory, // visible colour change on press
      ),
      child: isLoading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : FittedBox(fit: BoxFit.scaleDown,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label, maxLines: 1),
            ])),
    ),
  );
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const OutlineBtn({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 54,
    child: OutlinedButton(onPressed: onPressed, child: Text(label)));
}

class GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GhostBtn({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(color: AppColors.textMid, fontSize: 14)));
}

// ── Cards ─────────────────────────────────────────────────────
class EduCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;
  final Border? border;
  const EduCard({super.key, required this.child, this.onTap,
    this.padding, this.color, this.border});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    ),
  );
}

// ── Section header ────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      if (action != null) GestureDetector(
        onTap: onAction,
        child: Text(action!, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
    ],
  );
}

// ── Tags ──────────────────────────────────────────────────────
class TagBadge extends StatelessWidget {
  final String label;
  final Color? bg;
  final Color? fg;
  const TagBadge({super.key, required this.label, this.bg, this.fg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg ?? AppColors.primaryPale,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: fg ?? AppColors.primaryDark)),
  );
}

// ── Interest chip ─────────────────────────────────────────────
class InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;
  const InterestChip({super.key, required this.label,
    required this.selected, required this.onTap, this.emoji});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPale : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6)],
        Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: selected ? AppColors.primary : AppColors.textMid)),
      ]),
    ),
  );
}

// ── Match ring ────────────────────────────────────────────────
class MatchRing extends StatelessWidget {
  final int pct;
  final double size;
  const MatchRing({super.key, required this.pct, this.size = 52});
  Color get _color {
    if (pct >= 85) return AppColors.accentGreen;
    if (pct >= 70) return AppColors.primary;
    return AppColors.accentOrange;
  }
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(
        value: pct / 100,
        backgroundColor: AppColors.bgGrey,
        valueColor: AlwaysStoppedAnimation<Color>(_color),
        strokeWidth: 4,
      ),
      Text('$pct%', style: TextStyle(
        fontSize: size * 0.2, fontWeight: FontWeight.w800, color: _color)),
    ]),
  );
}

// ── Shimmer ───────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 80});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.primaryPale,
    highlightColor: Colors.white,
    child: Container(height: height,
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16))),
  );
}

// ── Progress bar ──────────────────────────────────────────────
class StepBar extends StatelessWidget {
  final int step;
  final int total;
  const StepBar({super.key, required this.step, required this.total});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      value: step / total, minHeight: 6,
      backgroundColor: AppColors.primaryPale,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)),
  );
}

// ── Onboarding header ─────────────────────────────────────────
class OnboardingHeader extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback? onBack;
  const OnboardingHeader({super.key, required this.step, required this.total, this.onBack});
  @override
  Widget build(BuildContext context) => Row(children: [
    if (onBack != null) GestureDetector(
      onTap: onBack,
      child: Container(width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
        child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textMid)),
    ),
    if (onBack != null) const SizedBox(width: 12),
    Expanded(child: StepBar(step: step, total: total)),
    const SizedBox(width: 12),
    Text('$step of $total', style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMid)),
  ]);
}

// ── Empty state ───────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.emoji, required this.title,
    required this.subtitle, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          PrimaryBtn(label: actionLabel!, onPressed: onAction),
        ],
      ]),
    ),
  );
}

// ── Error view ────────────────────────────────────────────────
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('😕', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          OutlineBtn(label: 'Try again', onPressed: onRetry),
        ],
      ]),
    ),
  );
}

// ── Segmented control ─────────────────────────────────────────
class SegCtrl extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const SegCtrl({super.key, required this.options,
    required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.bgGrey,
      borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.all(4),
    child: Row(children: options.map((o) {
      final sel = o == selected;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
          child: Text(o, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : AppColors.textMid)),
        ),
      ));
    }).toList()),
  );
}

// ── Back button ───────────────────────────────────────────────
class BackBtn extends StatelessWidget {
  const BackBtn({super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border)),
      child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textMid)),
  );
}


// ── Premium lock (free-tier gate) ──────────────────────────────
// Drop-in card shown in place of a locked feature; taps go to Pricing.
class PremiumLock extends StatelessWidget {
  final String title;
  final String subtitle;
  const PremiumLock({super.key, required this.title,
    this.subtitle = 'Upgrade to Premium to unlock this feature.'});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/pricing'),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.waypoint.withOpacity(0.5))),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.waypoint.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.lock_rounded,
            color: AppColors.waypoint, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(title, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 14.5, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 12, color: AppColors.textMid, height: 1.35)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: AppColors.waypoint),
      ]),
    ));
}

// ── Match reason humaniser ─────────────────────────────────────
// Turns the raw match_reason stored in the DB, e.g.
//   "Matched on: Technology, Gaming · Strengths: Problem solving"
// into a friendly one-liner for cards:
//   "Because you're into Technology & Gaming — and you shine at problem solving"
String friendlyMatchReason(String? raw, {int maxInterests = 2}) {
  const fallback = 'Matched to your interests and strengths';
  if (raw == null || raw.trim().isEmpty) return fallback;
  final r = raw.trim();
  if (!r.contains('Matched on')) {
    // Already a human sentence (or unknown format) — show it if short.
    return r.length <= 90 ? r : fallback;
  }
  var body = r
      .replaceAll('Matched on your interests in:', '')
      .replaceAll('Matched on:', '');
  String? strengths;
  final sIdx = body.indexOf('Strengths:');
  if (sIdx != -1) {
    strengths = body.substring(sIdx + 'Strengths:'.length).trim();
    body = body.substring(0, sIdx);
    strengths = strengths.split(',').first.replaceAll('·', '').trim();
    if (strengths.isEmpty) strengths = null;
  }
  final interests = body
      .replaceAll('·', '')
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .take(maxInterests)
      .toList();
  if (interests.isNotEmpty && strengths != null) {
    return "Because you're into ${interests.join(' & ')} — and you shine at ${strengths.toLowerCase()}";
  }
  if (interests.isNotEmpty) {
    return "Because you're into ${interests.join(' & ')}";
  }
  if (strengths != null) {
    return "Because you shine at ${strengths.toLowerCase()}";
  }
  return fallback;
}

// ── Match reason line (✨ on cards) ────────────────────────────
// Small tappable line under a match card title. Tapping opens the
// full "Why this matches you" screen.
class MatchReasonLine extends StatelessWidget {
  final String? reason;
  final String careerId;
  final Color? color;
  const MatchReasonLine({super.key, required this.reason,
    required this.careerId, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => context.push('/why-match/$careerId'),
    child: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✨ ', style: TextStyle(fontSize: 11)),
        Flexible(child: Text(friendlyMatchReason(reason),
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 11.5,
            fontWeight: FontWeight.w700, height: 1.3,
            color: color ?? AppColors.primary))),
      ]),
    ));
}

// ── Free-tier save limit ───────────────────────────────────────
// Free accounts can save up to [kFreeSaveLimit] items; Premium is
// unlimited. Call guardSaveLimit() BEFORE saving — if the limit is
// reached it shows a friendly upgrade sheet and returns false.
const kFreeSaveLimit = 3;

Future<bool> guardSaveLimit(BuildContext context, WidgetRef ref) async {
  final isPrem = ref.read(isPremiumProvider).valueOrNull ?? false;
  if (isPrem) return true;
  int savedCount;
  final cached = ref.read(savedItemsProvider).valueOrNull;
  if (cached != null) {
    savedCount = cached.length;
  } else {
    try {
      savedCount = (await ref.read(savedItemsProvider.future)).length;
    } catch (_) {
      savedCount = 0; // fail open — never block a save on a fetch error
    }
  }
  if (savedCount < kFreeSaveLimit) return true;
  if (context.mounted) showSaveLimitSheet(context);
  return false;
}

void showSaveLimitSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔖', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 12),
        const Text('Your Saved list is full!',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 19,
            fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'Free accounts can save up to $kFreeSaveLimit careers or courses. '
          'Go Premium for unlimited saves, route comparison and your full roadmap.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13.5,
            color: AppColors.textMid, height: 1.5)),
        const SizedBox(height: 18),
        PrimaryBtn(label: 'Go Premium — unlimited saves ⭐',
          onPressed: () {
            Navigator.pop(ctx);
            context.push('/pricing');
          }),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Maybe later',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
              fontWeight: FontWeight.w700, color: AppColors.textMid))),
      ]),
    ));
}
