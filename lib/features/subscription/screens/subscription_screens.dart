// lib/features/subscription/screens/subscription_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

class _Plan {
  final String id, name, emoji;
  final int monthlyPence, yearlyPence;
  final Color color;
  final String? badge;
  final List<String> features, missing;
  const _Plan({required this.id, required this.name, required this.emoji,
    required this.monthlyPence, required this.yearlyPence, required this.color,
    this.badge, required this.features, required this.missing});
  String get monthlyDisplay => monthlyPence == 0 ? 'Free' : '£${(monthlyPence / 100).toStringAsFixed(2)}/mo';
  String get yearlyDisplay  => yearlyPence == 0  ? 'Free' : '£${(yearlyPence / 100).toStringAsFixed(2)}/yr';
  String price(bool yearly) => yearly ? yearlyDisplay : monthlyDisplay;
}

const _plans = [
  _Plan(
    id: AppConstants.planFree, name: 'Free', emoji: '🆓',
    monthlyPence: 0, yearlyPence: 0, color: Color(0xFF64748B),
    features: ['3 AI career matches', 'Basic roadmap view', 'Browse careers & courses',
      'EduBot (5 messages/day)'],
    missing: ['Unlimited AI recommendations', 'Full roadmap builder',
      'Uni comparisons', 'Parent dashboard'],
  ),
  _Plan(
    id: AppConstants.planPremium, name: 'Premium', emoji: '⭐',
    monthlyPence: 599, yearlyPence: 4999,
    color: AppColors.primary, badge: 'Most Popular',
    features: ['Unlimited AI matches', 'Full EduBot access', 'Full roadmap builder',
      'University comparisons', 'Application tracker', 'Scholarship alerts',
      '7-day free trial'],
    missing: ['Family accounts (3 users)', 'Parent dashboard'],
  ),
  _Plan(
    id: AppConstants.planPremiumPlus, name: 'Premium+', emoji: '👑',
    monthlyPence: 999, yearlyPence: 7999,
    color: Color(0xFFB45309), badge: 'Family Plan',
    features: ['Everything in Premium', 'Family accounts (3 users)',
      'Parent dashboard', 'Progress reports', 'Scholarship alerts',
      '7-day free trial'],
    missing: [],
  ),
];

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});
  @override
  ConsumerState<PricingScreen> createState() => _PricingState();
}

class _PricingState extends ConsumerState<PricingScreen> {
  bool _yearly = false;
  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 180, pinned: true,
          backgroundColor: AppColors.primary,
          leading: GestureDetector(onTap: () => context.pop(),
            child: Container(margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white))),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: gradientBox(radius: 0),
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                  Text('👑', style: TextStyle(fontSize: 36)),
                  Text('Unlock Your Full Future',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 22,
                      fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('with Premium', style: TextStyle(fontFamily: 'Nunito',
                    fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w600)),
                ]),
              )),
            ),
          ),
        ),
        SliverList(delegate: SliverChildListDelegate([const SizedBox(height: 0),
          Padding(
            padding: const EdgeInsets.all(20),
            child: EduCard(padding: const EdgeInsets.all(6),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _yearly = false),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_yearly ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10)),
                    child: Text('Monthly', textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: !_yearly ? Colors.white : AppColors.textMid))))),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _yearly = true),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _yearly ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [
                      Text('Yearly', textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _yearly ? Colors.white : AppColors.textMid)),
                      Text('Save 30%', style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: _yearly ? Colors.white70 : AppColors.accentGreen)),
                    ])))),
              ]))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: _plans.map((plan) {
              final current = subAsync.valueOrNull?.plan == plan.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PlanCard(plan: plan, yearly: _yearly, current: current,
                  onTap: plan.monthlyPence == 0 ? null : () => context.push(
                    '${AppConstants.routeCheckout}?plan=${plan.id}&cycle=${_yearly ? "yearly" : "monthly"}')));
            }).toList())),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Text('Cancel anytime. No commitment. 7-day free trial on all paid plans.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textLight))),
        ])),
      ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool yearly, current;
  final VoidCallback? onTap;
  const _PlanCard({required this.plan, required this.yearly, required this.current, this.onTap});
  @override
  Widget build(BuildContext context) {
    final isPop = plan.badge == 'Most Popular';
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPop ? plan.color : AppColors.border, width: isPop ? 2 : 1.5),
          boxShadow: isPop ? [BoxShadow(color: plan.color.withOpacity(0.15),
            blurRadius: 20, offset: const Offset(0, 4))] : []),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(plan.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(plan.name, style: TextStyle(fontFamily: 'Nunito',
              fontSize: 18, fontWeight: FontWeight.w900, color: plan.color)),
            const Spacer(),
            Text(plan.price(yearly), style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ]),
          if (plan.monthlyPence > 0) const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('7-day free trial included!', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 11,
              color: AppColors.accentGreen, fontWeight: FontWeight.w700))),
          const SizedBox(height: 14),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, size: 16, color: plan.color),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600))),
            ]))),
          if (plan.missing.isNotEmpty) ...plan.missing.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Icon(Icons.remove_circle_outline_rounded,
                size: 16, color: AppColors.textLight),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13, color: AppColors.textLight))),
            ]))),
          const SizedBox(height: 14),
          current
            ? Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: AppColors.bgGrey,
                  borderRadius: BorderRadius.circular(12)),
                child: const Text('Current Plan', textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w800, color: AppColors.textMid)))
            : GestureDetector(
                onTap: plan.monthlyPence == 0 ? null : onTap,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: plan.monthlyPence == 0 ? null
                        : LinearGradient(colors: [plan.color, plan.color.withOpacity(0.8)]),
                    color: plan.monthlyPence == 0 ? AppColors.bgGrey : null,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(plan.monthlyPence == 0 ? 'Current Plan' : 'Start Free Trial',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: plan.monthlyPence == 0 ? AppColors.textLight : Colors.white)))),
        ])),
      if (plan.badge != null && !current) Positioned(top: -10, right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: plan.color, borderRadius: BorderRadius.circular(999)),
          child: Text(plan.badge!, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)))),
    ]);
  }
}

class CheckoutScreen extends ConsumerStatefulWidget {
  final String plan, cycle;
  const CheckoutScreen({super.key, required this.plan, required this.cycle});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<CheckoutScreen> {
  int _payMethod = 0;
  bool _loading = false;

  String get _planName {
    switch (widget.plan) {
      case AppConstants.planPremiumPlus: return 'Premium+';
      case AppConstants.planPremium: return 'Premium';
      default: return 'Free';
    }
  }

  int get _pricePence {
    final isYearly = widget.cycle == 'yearly';
    if (widget.plan == AppConstants.planPremiumPlus) return isYearly ? 7999 : 999;
    return isYearly ? 4999 : 599;
  }

  String get _priceDisplay => '£${(_pricePence / 100).toStringAsFixed(2)}';
  String get _cycleLabel => widget.cycle == 'yearly' ? '/year' : '/month';

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    await DbService.activatePlan(widget.plan, widget.cycle);
    ref.invalidate(subscriptionProvider);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _loading = false);
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Welcome to $_planName!', textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 20,
            fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Your 7-day free trial has started!', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
        const SizedBox(height: 20),
        PrimaryBtn(label: 'Lets Go!', onPressed: () {
          Navigator.pop(context);
          context.go(AppConstants.routeHome);
        }),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: const Text('Complete Your Purchase'),
        leading: GestureDetector(onTap: () => context.pop(), child: const BackBtn())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EduCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Order Summary', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('EduPaths $_planName'),
              Text('$_priceDisplay$_cycleLabel', style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800)),
            ]),
            const Divider(height: 24),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('7-day free trial', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
              Text('Free today', style: TextStyle(fontFamily: 'Nunito',
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentGreen)),
            ]),
            const SizedBox(height: 6),
            Text('Then $_priceDisplay$_cycleLabel after trial. Cancel anytime.',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppColors.textLight)),
          ])),
          const SizedBox(height: 20),
          const Text('Payment Method', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _PayOption(index: 0, selected: _payMethod, emoji: '💳', label: 'Credit / Debit Card',
            onTap: () => setState(() => _payMethod = 0)),
          const SizedBox(height: 8),
          _PayOption(index: 1, selected: _payMethod, emoji: '🍎', label: 'Apple Pay',
            onTap: () => setState(() => _payMethod = 1)),
          const SizedBox(height: 8),
          _PayOption(index: 2, selected: _payMethod, emoji: '🔵', label: 'Google Pay',
            onTap: () => setState(() => _payMethod = 2)),
          const SizedBox(height: 28),
          PrimaryBtn(label: 'Start 7-Day Free Trial', onPressed: _subscribe, isLoading: _loading),
          const SizedBox(height: 12),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_outline, size: 14, color: AppColors.textLight),
            SizedBox(width: 4),
            Text('Secure checkout. Cancel anytime.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 11, color: AppColors.textLight)),
          ]),
        ]),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final int index, selected;
  final String emoji, label;
  final VoidCallback onTap;
  const _PayOption({required this.index, required this.selected,
    required this.emoji, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = index == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryPale : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 2 : 1.5)),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          AnimatedContainer(duration: const Duration(milliseconds: 180),
            width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: sel ? AppColors.primary : Colors.transparent,
              border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: 2)),
            child: sel ? const Icon(Icons.check, color: Colors.white, size: 12) : null),
        ]),
      ),
    );
  }
}
