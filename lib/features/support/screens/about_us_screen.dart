// lib/features/support/screens/about_us_screen.dart
// About EduPaths — mission, team, story, contact, version
// Add route in router.dart:
//   GoRoute(path: '/about', builder: (c, s) => const AboutUsScreen()),
// Call from profile settings sheet:
//   _SettingRow(emoji: 'ℹ️', label: 'About EduPaths', onTap: () => context.push('/about'))

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('About EduPaths'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const BackBtn()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: gradientBox(radius: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎓', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('EduPaths', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 28,
                fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              const Text(
                'Helping UK teens aged 14–19 discover careers, compare routes, and build their future — one step at a time.',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  color: Colors.white70, height: 1.5)),
            ])),

          const SizedBox(height: 24),

          // Mission
          _Section(
            emoji: '🚀',
            title: 'Our Mission',
            body:
              'Too many young people make career decisions based on limited information or what people around them do. '
              'EduPaths exists to change that — giving every student access to the kind of personalised guidance that '
              'used to be available only to the privileged few.\n\n'
              'We match you to careers based on your real interests and strengths, show you every route to get there '
              '(university, apprenticeship, bootcamp), and walk you through the qualifications you need — step by step.',
          ),

          const SizedBox(height: 16),

          // What we offer
          _Section(
            emoji: '✨',
            title: 'What EduPaths Offers',
            body: null,
            child: Column(children: [
              _FeatureRow('🎯', 'AI career matching', 'Personalised to your interests and strengths'),
              _FeatureRow('🗺️', 'Step-by-step roadmaps', 'From Year 10 GCSEs to your first job'),
              _FeatureRow('⚖️', 'Route comparison', 'Uni vs apprenticeship vs bootcamp'),
              _FeatureRow('🔍', 'Course finder', 'University degrees and apprenticeships'),
              _FeatureRow('📚', 'Qualifications guide', 'GCSE, A-Level, BTEC, T-Level explained'),
              _FeatureRow('🧠', 'Career IQ quizzes', 'Myth-busting facts about real careers'),
              _FeatureRow('🤖', 'EduBot AI', 'Your 24/7 careers advisor'),
              _FeatureRow('👨‍👩‍👧', 'Parent dashboard', 'Stay involved in your child\'s journey'),
            ]),
          ),

          const SizedBox(height: 16),

          // Who we are
          _Section(
            emoji: '👥',
            title: 'Who We Are',
            body:
              'EduPaths is built by a small team passionate about education and equal opportunity. '
              'We\'re based in the UK and work closely with schools, advisors and young people to make '
              'sure our guidance is accurate, honest and actually useful.\n\n'
              'We\'re not here to tell you what career to pick — we\'re here to make sure you have '
              'everything you need to make that choice yourself.',
          ),

          const SizedBox(height: 16),

          // Pricing summary
          _Section(
            emoji: '💰',
            title: 'Free & Premium',
            body: null,
            child: Column(children: [
              _PriceRow('Free', [
                'Career matching (top 5)',
                'Browse all careers and courses',
                'Basic roadmap',
                'EduBot (5 messages/day)',
                'Save up to 3 items',
              ]),
              const SizedBox(height: 10),
              _PriceRow('Premium — £4.99/mo or £34.99/yr', [
                'Unlimited matches',
                'Full roadmap with grade targets',
                'Unlimited EduBot (~50/day)',
                'Personal statement builder',
                'Compare all routes side-by-side',
                'PDF career plan',
                'Salary insights',
              ], isPremium: true),
            ]),
          ),

          const SizedBox(height: 16),

          // Contact
          _Section(
            emoji: '📧',
            title: 'Get in Touch',
            body: null,
            child: Column(children: [
              _ContactTile('General enquiries', 'hello@edupaths.co.uk'),
              _ContactTile('Support', 'support@edupaths.co.uk'),
              _ContactTile('Schools & partnerships', 'schools@edupaths.co.uk'),
              _ContactTile('Report a bug', 'bugs@edupaths.co.uk'),
            ]),
          ),

          const SizedBox(height: 16),

          // Links
          EduCard(child: Column(children: [
            _LinkRow('🔒', 'Privacy Policy', 'https://edupaths.co.uk/privacy'),
            const Divider(height: 1),
            _LinkRow('📋', 'Terms of Service', 'https://edupaths.co.uk/terms'),
            const Divider(height: 1),
            _LinkRow('🌐', 'Website', 'https://edupaths.co.uk'),
          ])),

          const SizedBox(height: 24),

          // Version
          const Center(child: Column(children: [
            Text('EduPaths', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900,
              color: AppColors.textMid)),
            SizedBox(height: 4),
            Text('Version 1.0.0  ·  UK Careers Guidance',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                color: AppColors.textLight)),
            SizedBox(height: 4),
            Text('Made with ❤️ in the UK',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                color: AppColors.textLight)),
          ])),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String emoji, title;
  final String? body;
  final Widget? child;
  const _Section({required this.emoji, required this.title, this.body, this.child});

  @override
  Widget build(BuildContext context) => EduCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 12),
      if (body != null) Text(body!, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid, height: 1.6)),
      if (child != null) child!,
    ]));
}

class _FeatureRow extends StatelessWidget {
  final String emoji, title, subtitle;
  const _FeatureRow(this.emoji, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 13, fontWeight: FontWeight.w800)),
        Text(subtitle, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 11, color: AppColors.textMid)),
      ])),
    ]));
}

class _PriceRow extends StatelessWidget {
  final String label;
  final List<String> features;
  final bool isPremium;
  const _PriceRow(this.label, this.features, {this.isPremium = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isPremium ? const Color(0xFFFFFBEB) : AppColors.bgGrey,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isPremium
        ? const Color(0xFFD97706).withOpacity(0.4) : AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
        fontWeight: FontWeight.w900,
        color: isPremium ? const Color(0xFF92400E) : AppColors.textDark)),
      const SizedBox(height: 8),
      ...features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(Icons.check_rounded, size: 14,
            color: isPremium ? const Color(0xFFD97706) : AppColors.success),
          const SizedBox(width: 6),
          Expanded(child: Text(f, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid))),
        ]))),
    ]));
}

class _ContactTile extends StatelessWidget {
  final String label, email;
  const _ContactTile(this.label, this.email);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid))),
      Text(email, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
    ]));
}

class _LinkRow extends StatelessWidget {
  final String emoji, label, url;
  const _LinkRow(this.emoji, this.label, this.url);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700))),
        const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textLight),
      ])));
}
