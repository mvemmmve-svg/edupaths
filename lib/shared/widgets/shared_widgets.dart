// lib/shared/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
