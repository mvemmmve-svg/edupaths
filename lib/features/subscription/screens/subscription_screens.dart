// lib/features/subscription/screens/subscription_screens.dart
// REPLACES your existing subscription_screens.dart
// Incorporates the three pricing models from the screenshots:
//   - Student Premium (£2.99/mo, £19.99/yr, £9.99 results-day offer)
//   - Parent Premium  (£4.99/mo, £39.99/yr, £59.99 family)
//   - School/Advisor  (£149/yr starter, £299/yr standard, £499/yr whole school)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

// ══════════════════════════════════════════════
// PRICING SCREEN (tab-based: Student / Parent / School)
// ══════════════════════════════════════════════
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
              const Expanded(
                child: Text('Choose a plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 40),
            ]),
          ),
          const SizedBox(height: 8),
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMid,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Student'),
                  Tab(text: 'Parent'),
                  Tab(text: 'School'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _StudentPricing(),
                _ParentPricing(),
                _SchoolPricing(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Student pricing ────────────────────────────────────────────────────
class _StudentPricing extends StatefulWidget {
  const _StudentPricing();
  @override
  State<_StudentPricing> createState() => _StudentPricingState();
}

class _StudentPricingState extends State<_StudentPricing> {
  String _selected = 'annual';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Student Premium'),
        const SizedBox(height: 4),
        const Text('Everything you need to find your perfect career path.',
            style: TextStyle(fontSize: 13, color: AppColors.textMid)),
        const SizedBox(height: 20),

        // Plan cards
        _PlanCard(
          id: 'monthly',
          selected: _selected == 'monthly',
          label: 'Monthly',
          price: '£2.99',
          period: '/month',
          badge: null,
          detail: 'Impulse buy — less than a coffee',
          onTap: () => setState(() => _selected = 'monthly'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          id: 'annual',
          selected: _selected == 'annual',
          label: 'Annual',
          price: '£19.99',
          period: '/year',
          badge: 'Best value',
          detail: '44% saving — serious students choose this',
          onTap: () => setState(() => _selected = 'annual'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          id: 'results',
          selected: _selected == 'results',
          label: 'Results day offer',
          price: '£9.99',
          period: '/year',
          badge: 'Limited offer',
          detail: 'GCSE/A-Level results day promotion',
          onTap: () => setState(() => _selected = 'results'),
          badgeColor: AppColors.accentOrange,
        ),
        const SizedBox(height: 24),

        // Features
        const _FeatureList(features: [
          ('🔓', 'Unlimited career matches'),
          ('🗺️', 'Full roadmaps with grade requirements'),
          ('🤖', 'EduBot AI — up to 50 messages/day'),
          ('📝', 'Personal statement builder'),
          ('⚖️', 'Compare career routes side-by-side'),
          ('📄', 'Download your career plan as PDF'),
          ('💰', 'Salary insights and progression data'),
          ('🚫', 'Ad-free experience'),
        ]),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () => context.push(
                '/checkout?plan=premium&cycle=$_selected'),
            child: Text(
              _selected == 'monthly'
                  ? 'Start for £2.99/month'
                  : _selected == 'annual'
                      ? 'Get Annual for £19.99'
                      : 'Claim Results Day offer',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Cancel anytime · Secure payment via Stripe',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ),
      ]),
    );
  }
}

// ── Parent pricing ──────────────────────────────────────────────────────
class _ParentPricing extends StatefulWidget {
  const _ParentPricing();
  @override
  State<_ParentPricing> createState() => _ParentPricingState();
}

class _ParentPricingState extends State<_ParentPricing> {
  String _selected = 'annual';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Parent Premium'),
        const SizedBox(height: 4),
        const Text('Stay involved in your child\'s career journey.',
            style: TextStyle(fontSize: 13, color: AppColors.textMid)),
        const SizedBox(height: 20),

        _PlanCard(
          id: 'monthly',
          selected: _selected == 'monthly',
          label: 'Monthly',
          price: '£4.99',
          period: '/month',
          badge: null,
          detail: 'Parents have more disposable income than students',
          onTap: () => setState(() => _selected = 'monthly'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          id: 'annual',
          selected: _selected == 'annual',
          label: 'Annual',
          price: '£39.99',
          period: '/year',
          badge: 'Best value',
          detail: 'Covers the whole school year',
          onTap: () => setState(() => _selected = 'annual'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          id: 'family',
          selected: _selected == 'family',
          label: 'Family (up to 3 children)',
          price: '£59.99',
          period: '/year',
          badge: 'Family',
          detail: 'Increases value for larger families',
          onTap: () => setState(() => _selected = 'family'),
          badgeColor: const Color(0xFF059669),
        ),
        const SizedBox(height: 24),

        const _FeatureList(features: [
          ('👀', 'View your child\'s career matches'),
          ('🗺️', 'Track roadmap progress'),
          ('⭐', 'See interests and strengths profile'),
          ('✏️', 'Edit child profile and regenerate matches'),
          ('📰', 'Parents Hub — options, revision, wellbeing'),
          ('🤖', 'EduBot AI access'),
          ('📊', 'Salary and route comparison data'),
          ('👨‍👩‍👧', 'Add up to 3 children (family plan)'),
        ]),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () => context.push(
                '/checkout?plan=parent&cycle=$_selected'),
            child: Text(
              _selected == 'monthly'
                  ? 'Start for £4.99/month'
                  : _selected == 'annual'
                      ? 'Get Annual for £39.99'
                      : 'Get Family plan for £59.99',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Cancel anytime · Secure payment via Stripe',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ),
      ]),
    );
  }
}

// ── School / Advisor pricing ────────────────────────────────────────────
class _SchoolPricing extends StatefulWidget {
  const _SchoolPricing();
  @override
  State<_SchoolPricing> createState() => _SchoolPricingState();
}

class _SchoolPricingState extends State<_SchoolPricing> {
  String _selected = 'standard';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('School Advisor Platform'),
        const SizedBox(height: 4),
        const Text(
            'Gatsby-compliant careers guidance at a fraction of the cost of Unifrog.',
            style: TextStyle(fontSize: 13, color: AppColors.textMid)),
        const SizedBox(height: 20),

        _PlanCard(
          id: 'starter',
          selected: _selected == 'starter',
          label: 'Starter',
          price: '£149',
          period: '/year',
          badge: null,
          detail: 'Up to 100 students · Affordable entry for small schools',
          onTap: () => setState(() => _selected = 'starter'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          id: 'standard',
          selected: _selected == 'standard',
          label: 'Standard',
          price: '£299',
          period: '/year',
          badge: 'Most popular',
          detail: 'Up to 300 students · Your current cohort_300 tier',
          onTap: () => setState(() => _selected = 'standard'),
        ),
        const SizedBox(height: 10),
        _PlanCard(
          id: 'wholeschool',
          selected: _selected == 'wholeschool',
          label: 'Whole School',
          price: '£499',
          period: '/year',
          badge: 'Best value',
          detail: 'Unlimited students · Compete with Unifrog at 1/10th the price',
          onTap: () => setState(() => _selected = 'wholeschool'),
        ),
        const SizedBox(height: 20),

        // Gatsby callout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📋 Gatsby Benchmarks met',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primary)),
              const SizedBox(height: 8),
              ...[
                'Benchmark 2 — Real LMI, salary data and entry requirements for 99 careers',
                'Benchmark 3 — Personalised matching unique to every student',
                'Benchmark 7 — University, apprenticeship and FE routes for all careers',
              ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.primary,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const _FeatureList(features: [
          ('🏫', 'School advisor portal with cohort overview'),
          ('📤', 'CSV student upload'),
          ('🔑', 'Kahoot-style join-school cohort codes'),
          ('👩‍🎓', 'View individual student matches and roadmaps'),
          ('📊', 'Interest and strength profiles per student'),
          ('📨', 'Broadcast messages to your cohort'),
          ('📋', 'Gatsby benchmark reporting'),
        ]),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0891B2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () => context.push(
                '/checkout?plan=school&cycle=$_selected'),
            child: Text(
              _selected == 'starter'
                  ? 'Get Starter for £149/year'
                  : _selected == 'standard'
                      ? 'Get Standard for £299/year'
                      : 'Get Whole School for £499/year',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Invoice available · Secure payment via Stripe',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════
// CHECKOUT SCREEN (UI shell — Stripe not yet wired)
// ══════════════════════════════════════════════
class CheckoutScreen extends StatelessWidget {
  final String plan;
  final String cycle;
  const CheckoutScreen({super.key, required this.plan, required this.cycle});

  String get _displayPrice {
    if (plan == 'premium') {
      if (cycle == 'monthly') return '£2.99/month';
      if (cycle == 'results') return '£9.99/year';
      return '£19.99/year';
    }
    if (plan == 'parent') {
      if (cycle == 'monthly') return '£4.99/month';
      if (cycle == 'family') return '£59.99/year';
      return '£39.99/year';
    }
    if (plan == 'school') {
      if (cycle == 'starter') return '£149/year';
      if (cycle == 'wholeschool') return '£499/year';
      return '£299/year';
    }
    return '';
  }

  String get _displayName {
    if (plan == 'premium') return 'Student Premium';
    if (plan == 'parent') return 'Parent Premium';
    if (plan == 'school') return 'School Advisor Platform';
    return 'EduPaths Premium';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Checkout',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(_displayName,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_displayPrice,
                style: const TextStyle(
                    fontSize: 18, color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.textMid),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stripe payment integration coming soon. Tap below to join the waitlist and be first to know when premium launches.',
                    style: TextStyle(fontSize: 14, color: AppColors.textMid, height: 1.5),
                  ),
                ),
              ]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("You're on the waitlist! We'll email you when payments go live."),
                  ));
                  context.pop();
                },
                child: const Text("Join the waitlist",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900));
}

class _PlanCard extends StatelessWidget {
  final String id, label, price, period;
  final String? badge;
  final String detail;
  final bool selected;
  final VoidCallback onTap;
  final Color badgeColor;

  const _PlanCard({
    required this.id,
    required this.selected,
    required this.label,
    required this.price,
    required this.period,
    required this.badge,
    required this.detail,
    required this.onTap,
    this.badgeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPale : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1.5,
        ),
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 13)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(label, style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: selected ? AppColors.primary : AppColors.textDark)),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text(detail,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMid)),
          ],
        )),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(price, style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: selected ? AppColors.primary : AppColors.textDark)),
          Text(period, style: const TextStyle(
              fontSize: 11, color: AppColors.textMid)),
        ]),
      ]),
    ),
  );
}

class _FeatureList extends StatelessWidget {
  final List<(String, String)> features;
  const _FeatureList({required this.features});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("What's included",
          style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textMid)),
      const SizedBox(height: 10),
      ...features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(f.$1, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(f.$2,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark))),
        ]),
      )),
    ],
  );
}
