// lib/features/support/screens/about_screen.dart
// Route: '/about'
// Add to router and link from Profile screen menu.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('About EduPaths',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Nunito')),
                        SizedBox(height: 6),
                        Text('Helping every young person find their path',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: 'Nunito')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission
                  _Section(
                    emoji: '🎯',
                    title: 'Our Mission',
                    child: const Text(
                      'EduPaths exists to make careers guidance genuinely useful for every young person in the UK — not just those with access to expensive advisors or well-connected parents.\n\nWe use smart matching, real data, and AI to help 14–19 year olds discover careers they\'ll actually love, understand every route to get there, and take their first confident steps forward.',
                      style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.textMid),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // What we offer
                  _Section(
                    emoji: '✨',
                    title: 'What EduPaths Offers',
                    child: Column(
                      children: [
                        _FeatureRow('🔍', 'Personalised career matching', 'Based on your interests and strengths — no two students get the same results.'),
                        _FeatureRow('🗺️', 'Step-by-step roadmaps', 'From Year 10 to age 18 and beyond, for every career we cover.'),
                        _FeatureRow('🎓', 'University & apprenticeship routes', 'Real courses, real entry requirements, real salary data.'),
                        _FeatureRow('🤖', 'EduBot AI', 'Your personal careers assistant — available 24/7.'),
                        _FeatureRow('👨‍👩‍👧', 'Parent dashboard', 'Stay involved without hovering. See your child\'s matches and progress.'),
                        _FeatureRow('🏫', 'School & advisor portal', 'Track whole cohorts, upload student data, and deliver Gatsby-compliant guidance at scale.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gatsby benchmarks
                  _Section(
                    emoji: '📋',
                    title: 'Gatsby Benchmarks',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EduPaths fully meets three of the eight Gatsby Benchmarks for Good Career Guidance — the UK government\'s gold standard for schools careers programmes.',
                          style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMid),
                        ),
                        const SizedBox(height: 16),
                        _GatsbyCard(
                          number: '2',
                          title: 'Learning from career and labour market information',
                          description: 'Students access real salary data, entry requirements, career overviews and apprenticeship links for 99 careers — updated directly in our database and verified against live government data.',
                        ),
                        const SizedBox(height: 12),
                        _GatsbyCard(
                          number: '3',
                          title: 'Addressing the needs of each student',
                          description: 'Our interest and trait matching algorithm produces genuinely personalised career recommendations, unique to each student. No two students get the same results.',
                        ),
                        const SizedBox(height: 12),
                        _GatsbyCard(
                          number: '7',
                          title: 'Encounters with further and higher education',
                          description: 'University courses, apprenticeship routes, UCAS guidance in the Parents Hub, T-Level and BTEC explanations, and direct links to Find an Apprenticeship for all careers.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // For schools
                  _Section(
                    emoji: '🏫',
                    title: 'For Schools & Advisors',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EduPaths gives careers advisors and teachers a powerful, affordable alternative to expensive guidance platforms.',
                          style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMid),
                        ),
                        const SizedBox(height: 14),
                        _PricingCard(
                          tier: 'Starter',
                          price: '£149/year',
                          students: 'Up to 100 students',
                          color: const Color(0xFF0891B2),
                        ),
                        const SizedBox(height: 8),
                        _PricingCard(
                          tier: 'Standard',
                          price: '£299/year',
                          students: 'Up to 300 students',
                          color: AppColors.primary,
                          highlighted: true,
                        ),
                        const SizedBox(height: 8),
                        _PricingCard(
                          tier: 'Whole School',
                          price: '£499/year',
                          students: 'Unlimited students',
                          color: const Color(0xFF059669),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(child: Text(
                              'Compare: Unifrog costs £1,800–£4,500/year. EduPaths delivers Gatsby-aligned guidance at a fraction of the cost.',
                              style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.5),
                            )),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact
                  _Section(
                    emoji: '📬',
                    title: 'Get in Touch',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'We\'d love to hear from schools, advisors, parents and students. Whether you have a question, feedback, or want to explore a school partnership — reach out.',
                          style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textMid),
                        ),
                        const SizedBox(height: 14),
                        _ContactRow(Icons.language, 'edupathmve.netlify.app'),
                        const SizedBox(height: 8),
                        _ContactRow(Icons.school_outlined, 'School partnerships available'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer
                  Center(
                    child: Column(children: [
                      const Text('Made with 💜 in the UK',
                          style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('© ${DateTime.now().year} EduPaths',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String emoji, title;
  final Widget child;
  const _Section({required this.emoji, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Nunito')),
      ]),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class _FeatureRow extends StatelessWidget {
  final String emoji, title, subtitle;
  const _FeatureRow(this.emoji, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMid, height: 1.4)),
      ])),
    ]),
  );
}

class _GatsbyCard extends StatelessWidget {
  final String number, title, description;
  const _GatsbyCard({required this.number, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Benchmark $number — $title',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        Text(description,
            style: const TextStyle(fontSize: 13, color: AppColors.textMid, height: 1.5)),
      ])),
    ]),
  );
}

class _PricingCard extends StatelessWidget {
  final String tier, price, students;
  final Color color;
  final bool highlighted;
  const _PricingCard({
    required this.tier, required this.price,
    required this.students, required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: highlighted ? color : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: highlighted ? color : AppColors.border, width: highlighted ? 2 : 1),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tier, style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: highlighted ? Colors.white : AppColors.textDark)),
        Text(students, style: TextStyle(
            fontSize: 12, color: highlighted ? Colors.white70 : AppColors.textMid)),
      ])),
      Text(price, style: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 16,
          color: highlighted ? Colors.white : color)),
    ]),
  );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppColors.primary),
    const SizedBox(width: 10),
    Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textMid)),
  ]);
}
