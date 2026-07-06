// lib/features/parent/screens/parent_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _sb = Supabase.instance.client;

// ── Children provider ─────────────────────────
final childrenProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch the UID value (not the raw auth stream) so token-refresh events
  // on web don't restart this load in a loop → infinite spinner.
  // Fetch children + details + matches via a secure function (parents
  // can't read their child's users row directly due to RLS).
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];
  final raw = await _sb.rpc('parent_children_full')
      .timeout(const Duration(seconds: 12));
  final list = (raw as List?) ?? [];
  return list.map<Map<String, dynamic>>((c) {
    final m = (c as Map).cast<String, dynamic>();
    return {
      'id': m['link_id'],
      'child_name': m['child_name'],
      'child_id': m['child_id'],
      'users': {
        'id': m['child_id'],
        'full_name': m['full_name'],
        'school_year': m['school_year'],
        'onboarding_complete': m['onboarding_complete'],
      },
      'interests': m['interests'] ?? [],
      'matches': m['matches'] ?? [],
    };
  }).toList();
});

// ── Child detail provider ─────────────────────
final _childMatchesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final res = await _sb.rpc('parent_child_matches',
        params: {'p_child_id': userId});
    return ((res as List?) ?? []).cast<Map<String, dynamic>>();
  });

final _childInterestsProvider = FutureProvider.family<List<String>, String>(
  (ref, userId) async {
    final res = await _sb
        .from('user_interest')
        .select('interests(name)')
        .eq('user_id', userId);
    return (res as List)
        .map((e) => (e['interests'] as Map)['name'] as String)
        .toList();
  });

// ══════════════════════════════════════════════
// PARENT DASHBOARD — 3 tabs
// ══════════════════════════════════════════════
class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});
  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashState();
}

class _ParentDashState extends ConsumerState<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _sb.auth.currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Parent Dashboard 👨‍👩‍👧'),
        leading: GestureDetector(onTap: () => context.pop(), child: const BackBtn()),
        actions: [
          IconButton(icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/home')),
        ],
        bottom: isLoggedIn ? TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontFamily: 'Nunito',
            fontSize: 12, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: '👶 Children'),
            Tab(text: '📊 Insights'),
            Tab(text: '📋 Parents Hub'),
          ],
        ) : null,
      ),
      body: isLoggedIn
          ? TabBarView(controller: _tabs, children: [
              _ChildrenTab(),
              _InsightsTab(),
              _ParentsHubTab(),
            ])
          : _GuestPrompt(),
    );
  }
}

// ── TAB 1: Children ───────────────────────────
class _ChildrenTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    return childrenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (children) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (children.isEmpty) ...[
            const SizedBox(height: 32),
            const EmptyState(emoji: '👶', title: 'No children added yet',
              subtitle: 'Add your child to track their career journey'),
            const SizedBox(height: 24),
          ] else ...[
            Text('${children.length} Child${children.length != 1 ? 'ren' : ''}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 16,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...children.map((c) => _ChildCard(child: c)),
            const SizedBox(height: 12),
          ],
          PrimaryBtn(label: '+ Add Child',
            onPressed: () => _showAddChild(context, ref)),
          const SizedBox(height: 32),
          // How it works
          const Text('How it works', style: TextStyle(fontFamily: 'Nunito',
            fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...[
            ('1️⃣', 'Add your child', 'Enter their name and school year'),
            ('2️⃣', 'Select interests', 'Choose what they enjoy'),
            ('3️⃣', 'Get matches', 'See their personalised career matches'),
            ('4️⃣', 'Track progress', 'Monitor their journey from your dashboard'),
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EduCard(child: Row(children: [
              Text(s.$1, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$2, style: const TextStyle(fontFamily: 'Nunito',
                  fontSize: 13, fontWeight: FontWeight.w800)),
                Text(s.$3, style: const TextStyle(fontFamily: 'Nunito',
                  fontSize: 12, color: AppColors.textMid)),
              ])),
            ])))),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showAddChild(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _AddChildSheet(
          onAdded: () => ref.invalidate(childrenProvider)));
}

class _ChildCard extends ConsumerWidget {
  final Map<String, dynamic> child;
  const _ChildCard({required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = child['users'] as Map<String, dynamic>?;
    final name = child['child_name'] ?? userData?['full_name'] ?? 'Child';
    final year = userData?['school_year'] ?? 'Unknown year';
    final done = userData?['onboarding_complete'] == true;
    final childUserId = userData?['id'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EduCard(
        onTap: childUserId != null
            ? () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProviderScope(
                  parent: ProviderScope.containerOf(context),
                  child: _ChildProgressScreen(
                    childName: name,
                    childUserId: childUserId,
                    schoolYear: year))))
            : null,
        child: Row(children: [
          CircleAvatar(radius: 22,
            backgroundColor: AppColors.primaryPale,
            child: Text(name[0].toUpperCase(), style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900,
              fontSize: 18, color: AppColors.primary))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 14, fontWeight: FontWeight.w800)),
            Text(year, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 12, color: AppColors.textMid)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            TagBadge(
              label: done ? '✅ Profile done' : '⏳ In progress',
              bg: done ? const Color(0xFFECFDF5) : AppColors.bgGrey,
              fg: done ? const Color(0xFF065F46) : AppColors.textMid),
            if (done) const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('View progress →', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11, color: AppColors.primary,
                fontWeight: FontWeight.w700))),
          ]),
        ])));
  }
}

// ── TAB 2: Insights ───────────────────────────
class _InsightsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    return childrenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (children) {
        final withProfile = children.where((c) =>
            (c['users'] as Map?)?['onboarding_complete'] == true).toList();
        if (children.isEmpty) return const EmptyState(emoji: '📊',
          title: 'No children added yet',
          subtitle: 'Add a child to see insights');
        if (withProfile.isEmpty) return const EmptyState(emoji: '⏳',
          title: 'No insights yet',
          subtitle: 'Ask your child to complete their profile in EduPaths');
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Career Insights', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...withProfile.map((c) {
              final userData = c['users'] as Map<String, dynamic>?;
              final name = c['child_name'] ?? userData?['full_name'] ?? 'Child';
              final userId = userData?['id'] as String?;
              if (userId == null) return const SizedBox();
              return _ChildInsightCard(name: name, userId: userId);
            }),
          ],
        );
      },
    );
  }
}

class _ChildInsightCard extends ConsumerWidget {
  final String name, userId;
  const _ChildInsightCard({required this.name, required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(_childMatchesProvider(userId));
    final interestsAsync = ref.watch(_childInterestsProvider(userId));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: EduCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18,
            backgroundColor: AppColors.primaryPale,
            child: Text(name[0].toUpperCase(), style: const TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900,
              color: AppColors.primary))),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 12),

        // Interests
        interestsAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (interests) => interests.isEmpty ? const SizedBox()
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Interests', style: TextStyle(fontFamily: 'Nunito',
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textMid)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
                  children: interests.map((i) => TagBadge(label: i,
                    bg: AppColors.primaryPale, fg: AppColors.primaryDark)).toList()),
                const SizedBox(height: 12),
              ])),

        // Top matches
        matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
          data: (matches) => matches.isEmpty
              ? const Text('No matches yet.',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: AppColors.textMid))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Top Career Matches', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 12,
                    fontWeight: FontWeight.w700, color: AppColors.textMid)),
                  const SizedBox(height: 8),
                  ...matches.take(5).map((m) {
                    final career = m['careers'] as Map;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        MatchRing(pct: m['match_score'] as int, size: 36),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(career['name'] as String, style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 13,
                            fontWeight: FontWeight.w700)),
                          if (career['avg_salary'] != null)
                            Text(career['avg_salary'] as String,
                              style: const TextStyle(fontFamily: 'Nunito',
                                fontSize: 11, color: AppColors.textMid)),
                        ])),
                        if (career['category'] != null)
                          TagBadge(label: career['category'] as String,
                            bg: AppColors.bgGrey, fg: AppColors.textMid),
                      ]));
                  }),
                ])),
      ])));
  }
}

// ── TAB 3: Parents Hub ────────────────────────
class _ParentsHubTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Container(padding: const EdgeInsets.all(20), decoration: gradientBox(radius: 16),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Parents Hub 📋', style: TextStyle(fontFamily: 'Nunito',
            fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 8),
          Text('Resources and guidance to support your child\'s career journey.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
              color: Colors.white70, height: 1.4)),
        ])),
      const SizedBox(height: 20),

      const SectionHeader(title: 'Understanding Your Child\'s Options'),
      const SizedBox(height: 12),
      ...[
        ('🎓', 'A-Levels', 'Traditional 2-year qualifications studied at sixth form or college. '
          'Required for most university degrees. Students choose 3-4 subjects. '
          'Graded A*-E. Recognized by all universities.'),
        ('📋', 'BTECs', 'Vocational qualifications with coursework-based assessment. '
          'Equivalent to A-Levels. Merit and Distinction grades. '
          'Excellent for practical career paths and many universities accept them.'),
        ('🔨', 'T-Levels', 'New technical qualifications launched from 2020. '
          'Equivalent to 3 A-Levels. Industry placement included. '
          'Ideal for technical careers like engineering, health, digital.'),
        ('💼', 'Degree Apprenticeships', 'Work and study simultaneously. '
          'Earn a full degree while getting paid. No student debt. '
          'Available at top companies including NHS, PwC, BAE Systems.'),
        ('📝', 'UCAS', 'The UK university application system. '
          'Students apply to up to 5 universities. Main deadline January 29. '
          'Oxford/Cambridge and medicine courses have an October deadline.'),
      ].map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _HubCard(emoji: item.$1, title: item.$2, body: item.$3))),

      const SizedBox(height: 20),
      const SectionHeader(title: 'Key Dates 2025/26'),
      const SizedBox(height: 12),
      ...[
        ('Oct 2025', 'UCAS Oxford/Cambridge deadline'),
        ('Jan 2026', 'UCAS main application deadline'),
        ('May 2026', 'GCSE & A-Level exams begin'),
        ('Aug 2026', 'A-Level results day'),
        ('Aug 2026', 'GCSE results day'),
      ].map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(8)),
            child: Text(d.$1, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary))),
          const SizedBox(width: 12),
          Expanded(child: Text(d.$2, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 13, fontWeight: FontWeight.w600))),
        ])))),

      const SizedBox(height: 20),
      const SectionHeader(title: 'Useful Resources'),
      const SizedBox(height: 12),
      ...[
        ('🎓', 'UCAS', 'University application guide for parents', 'ucas.com/parents'),
        ('💼', 'Apprenticeships', 'Find degree apprenticeships', 'findapprenticeship.service.gov.uk'),
        ('📚', 'National Careers Service', 'Free careers guidance', 'nationalcareers.service.gov.uk'),
        ('🏫', 'GOV.UK Education', 'School and college information', 'gov.uk/education'),
      ].map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EduCard(child: Row(children: [
          Text(r.$1, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.$2, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 13, fontWeight: FontWeight.w800)),
            Text(r.$3, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 12, color: AppColors.textMid)),
            Text(r.$4, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 11, color: AppColors.primary)),
          ])),
        ])))),

      const SizedBox(height: 20),
      const SectionHeader(title: 'Support by Exam Board'),
      const SizedBox(height: 4),
      const Padding(padding: EdgeInsets.only(bottom: 12),
        child: Text('Check which board each subject uses (ask the school), then '
          'use their free past papers and specifications.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5,
            color: AppColors.textMid, height: 1.4))),
      ...[
        ('AQA', 'The largest board in England. Free past papers and mark schemes on their site.', 'aqa.org.uk'),
        ('OCR', 'Common for sciences and computing. Past papers and specs are free online.', 'ocr.org.uk'),
        ('Edexcel (Pearson)', 'Popular for Maths. Past papers plus the excellent free "Save My Exams" resources.', 'qualifications.pearson.com'),
        ('WJEC / Eduqas', 'Used across Wales and parts of England, especially English and Humanities.', 'eduqas.co.uk'),
      ].map((b) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _LinkCard(emoji: '📄', title: b.$1, body: b.$2, url: b.$3)))
        .toList(),

      const SizedBox(height: 20),
      const SectionHeader(title: 'Books & Revision Resources'),
      const SizedBox(height: 12),
      ...[
        ('📘', 'CGP Revision Guides', 'The classic GCSE & A-Level revision books — concise and student-favourite.', 'cgpbooks.co.uk'),
        ('📺', 'BBC Bitesize', 'Free revision by subject, level and exam board. Videos, notes and quizzes.', 'bbc.co.uk/bitesize'),
        ('✅', 'Save My Exams', 'Topic notes and past-paper questions by exam board (free + paid).', 'savemyexams.com'),
        ('🎥', 'Seneca Learning', 'Free smart revision that adapts to your child. Great for quick recall.', 'senecalearning.com'),
        ('🛒', 'Amazon: revision guides', 'Search CGP, Oxford or Collins guides for your child\'s exact subjects.', 'amazon.co.uk'),
      ].map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _LinkCard(emoji: r.$1, title: r.$2, body: r.$3, url: r.$4)))
        .toList(),

      const SizedBox(height: 20),
      const SectionHeader(title: 'Healthy Revision & Screen Time'),
      const SizedBox(height: 12),
      _HubCard(emoji: '⏰', title: 'How much revision is healthy?',
        body: 'A good guide: Years 10–11 around 1–2 hours on a school night '
          'and 3–4 hours a day in the holidays; Years 12–13 around 2–3 hours '
          'on a school night. Short focused blocks (25–40 mins) with breaks '
          'beat long marathons. Quality over quantity — and never at the '
          'expense of sleep.'),
      _HubCard(emoji: '📱', title: 'Screen time & phones',
        body: 'Phones are the biggest revision distraction. A simple win: '
          'agree the phone stays in another room during revision blocks. '
          'Aim to switch screens off ~1 hour before bed — blue light and '
          'social media harm the sleep that memory depends on. Downtime and '
          'gaming are fine once the agreed revision is done.'),
      _HubCard(emoji: '😴', title: 'Sleep, food & breaks',
        body: 'Teenagers need 8–10 hours\' sleep — it\'s when the brain locks '
          'in what they revised. Regular meals, water and fresh-air breaks '
          'do more for grades than one extra late-night hour of cramming.'),

      const SizedBox(height: 80),
    ],
  );
}

// Tappable resource card that opens an external link.
class _LinkCard extends StatelessWidget {
  final String emoji, title, body, url;
  const _LinkCard({required this.emoji, required this.title,
    required this.body, required this.url});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => launchUrl(
      Uri.parse(url.startsWith('http') ? url : 'https://$url'),
      mode: LaunchMode.externalApplication),
    child: EduCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(title, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(body, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 12, color: AppColors.textMid, height: 1.35)),
        const SizedBox(height: 3),
        Row(children: [
          Text(url, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new_rounded, size: 11, color: AppColors.primary),
        ]),
      ])),
    ])));
}

class _HubCard extends StatefulWidget {
  final String emoji, title, body;
  const _HubCard({required this.emoji, required this.title, required this.body});
  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => EduCard(
    onTap: () => setState(() => _expanded = !_expanded),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(widget.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Text(widget.title, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800))),
        Icon(_expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
          color: AppColors.textLight),
      ]),
      if (_expanded) ...[
        const SizedBox(height: 10),
        Text(widget.body, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 13, color: AppColors.textMid, height: 1.5)),
      ],
    ]));
}

// ── Child Progress Screen ─────────────────────
class _ChildProgressScreen extends ConsumerWidget {
  final String childName, childUserId, schoolYear;
  const _ChildProgressScreen({
    required this.childName, required this.childUserId,
    required this.schoolYear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(_childMatchesProvider(childUserId));
    final interestsAsync = ref.watch(_childInterestsProvider(childUserId));

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(childName, style: const TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context), child: const BackBtn())),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        // Profile card
        Container(padding: const EdgeInsets.all(20), decoration: gradientBox(radius: 16),
          child: Row(children: [
          CircleAvatar(radius: 32, backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(childName[0].toUpperCase(), style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(childName, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(schoolYear, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999)),
              child: const Text('✅ Profile Complete', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 12, color: Colors.white,
                fontWeight: FontWeight.w700))),
          ])),
        ])),
        const SizedBox(height: 20),

        // Interests
        const SectionHeader(title: 'Their Interests 🎯'),
        const SizedBox(height: 10),
        interestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const SizedBox(),
          data: (interests) => interests.isEmpty
              ? const Text('No interests saved yet.')
              : Wrap(spacing: 8, runSpacing: 8,
                  children: interests.map((i) => TagBadge(label: i,
                    bg: AppColors.primaryPale, fg: AppColors.primaryDark)).toList())),

        const SizedBox(height: 20),
        // Career matches
        const SectionHeader(title: 'Top Career Matches 🏆'),
        const SizedBox(height: 10),
        matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Text('Could not load matches'),
          data: (matches) => matches.isEmpty
              ? const EmptyState(emoji: '🔍', title: 'No matches yet',
                  subtitle: 'Child needs to complete onboarding')
              : Column(children: matches.map((m) {
                  final career = m['careers'] as Map;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EduCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        MatchRing(pct: m['match_score'] as int, size: 44),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(career['name'] as String, style: const TextStyle(
                            fontFamily: 'Nunito', fontSize: 15,
                            fontWeight: FontWeight.w800)),
                          if (career['avg_salary'] != null)
                            Text(career['avg_salary'] as String,
                              style: const TextStyle(fontFamily: 'Nunito',
                                fontSize: 12, color: AppColors.textMid)),
                        ])),
                        if (career['category'] != null) TagBadge(
                          label: career['category'] as String,
                          bg: AppColors.primaryPale, fg: AppColors.primaryDark),
                      ]),
                      if (m['match_reason'] != null &&
                          (m['match_reason'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(m['match_reason'] as String,
                          style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 12, color: AppColors.textMid)),
                      ],
                    ])));
                }).toList())),
        const SizedBox(height: 80),
      ])),
    );
  }
}

// ══════════════════════════════════════════════
// ADD CHILD SHEET
// ══════════════════════════════════════════════
class _AddChildSheet extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const _AddChildSheet({required this.onAdded});
  @override
  ConsumerState<_AddChildSheet> createState() => _AddChildState();
}

class _AddChildState extends ConsumerState<_AddChildSheet> {
  final _nameCtrl = TextEditingController();
  String? _schoolYear;
  Set<String> _selectedInterestIds = {};
  Set<String> _selectedTraitIds = {};
  int _step = 0; // 0=details, 1=interests, 2=traits
  bool _saving = false;
  String? _error;

  static const _years = ['Year 7','Year 8','Year 9','Year 10',
    'Year 11','Year 12','Year 13','Sixth Form'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: _step == 0 ? _buildDetails() : _step == 1 ? _buildInterests() : _buildTraits());
  }

  Widget _buildDetails() => Column(mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Add Your Child 👶', style: TextStyle(
      fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    const Text('Set up a profile for your child to get their career matches.',
      style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
    const SizedBox(height: 20),
    if (_error != null) Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(_error!, style: const TextStyle(
        color: AppColors.error, fontFamily: 'Nunito', fontSize: 13))),
    TextFormField(controller: _nameCtrl,
      decoration: const InputDecoration(hintText: "Child's name",
        prefixIcon: Icon(Icons.person_outline))),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(value: _schoolYear,
      hint: const Text('School Year'),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
      items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
      onChanged: (v) => setState(() => _schoolYear = v)),
    const SizedBox(height: 20),
    PrimaryBtn(label: 'Next: Select Interests →',
      onPressed: () {
        if (_nameCtrl.text.trim().isEmpty) {
          setState(() => _error = 'Please enter your child\'s name'); return;
        }
        setState(() { _step = 1; _error = null; });
      }),
  ]);

  Widget _buildInterests() {
    final interestsAsync = ref.watch(interestsProvider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(onTap: () => setState(() => _step = 0),
          child: const Icon(Icons.arrow_back_rounded, size: 20)),
        const SizedBox(width: 10),
        Text("${_nameCtrl.text.trim()}'s Interests 🎯",
          style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 17, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 4),
      const Text('Select interests to generate personalised career matches.',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
      const SizedBox(height: 12),
      Expanded(child: interestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (interests) {
          final byCategory = <String, List<Interest>>{};
          for (final i in interests) {
            byCategory.putIfAbsent(i.category ?? 'Other', () => []).add(i);
          }
          return SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: byCategory.entries.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(e.key.toUpperCase(), style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.textLight, letterSpacing: 0.8))),
              Wrap(spacing: 8, runSpacing: 8, children: e.value.map((i) {
                final sel = _selectedInterestIds.contains(i.id);
                return GestureDetector(
                  onTap: () => setState(() => sel
                      ? _selectedInterestIds.remove(i.id)
                      : _selectedInterestIds.add(i.id)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border)),
                    child: Text(i.trimmed, style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textMid))));
              }).toList()),
            ])).toList()));
        })),
      const SizedBox(height: 12),
      Text('${_selectedInterestIds.length} selected',
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
          color: AppColors.textMid)),
      const SizedBox(height: 8),
      PrimaryBtn(
        label: 'Next: Select Strengths →',
        onPressed: _selectedInterestIds.isEmpty ? null
            : () => setState(() => _step = 2)),
    ]));
  }

  Widget _buildTraits() {
    final traitsAsync = ref.watch(traitsProvider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(onTap: () => setState(() => _step = 1),
          child: const Icon(Icons.arrow_back_rounded, size: 20)),
        const SizedBox(width: 10),
        Text("What does ${_nameCtrl.text.trim()} enjoy? ⭐",
          style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 16, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 4),
      const Text('Select strengths to improve career matching.',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
      const SizedBox(height: 12),
      Expanded(child: traitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (traits) {
          final byCategory = <String, List<Trait>>{};
          for (final t in traits) {
            byCategory.putIfAbsent(t.category ?? 'Other', () => []).add(t);
          }
          return SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: byCategory.entries.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(e.key.toUpperCase(), style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800,
                  color: AppColors.textLight, letterSpacing: 0.8))),
              ...e.value.map((t) {
                final sel = _selectedTraitIds.contains(t.id);
                return Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => sel
                        ? _selectedTraitIds.remove(t.id)
                        : _selectedTraitIds.add(t.id)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryPale : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border,
                          width: sel ? 2 : 1.5)),
                      child: Row(children: [
                        Expanded(child: Text(t.trimmed, style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 13,
                          color: sel ? AppColors.primary : AppColors.textDark))),
                        if (sel) const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 18),
                      ]))));
              }),
            ])).toList()));
        })),
      const SizedBox(height: 8),
      Text('${_selectedTraitIds.length} selected',
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
      const SizedBox(height: 8),
      PrimaryBtn(
        label: _saving ? 'Creating profile...' : 'Create Profile & Get Matches 🎉',
        isLoading: _saving,
        onPressed: _saving ? null : _save),
    ]));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_sb.auth.currentUser == null) {
        setState(() { _saving = false; _error = 'Please log in again.'; });
        return;
      }

      // One secure call creates the virtual child, saves interests/traits,
      // links to this parent, and generates matches — all server-side.
      // (Direct inserts were blocked by RLS / the supabase_uid unique
      //  constraint, which is why the button appeared to do nothing.)
      await _sb.rpc('parent_create_child', params: {
        'p_name': _nameCtrl.text.trim(),
        'p_school_year': _schoolYear,
        'p_interest_ids': _selectedInterestIds.toList(),
        'p_trait_ids': _selectedTraitIds.toList(),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Child profile created with career matches!'),
          backgroundColor: AppColors.success));
      }
    } catch (e) {
      setState(() { _saving = false; _error = 'Error: $e'; });
    }
  }
}

// ── Screens exported for router ───────────────
class ParentInsightsScreen extends ConsumerWidget {
  const ParentInsightsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const ParentDashboardScreen();
}

// ── Guest prompt ──────────────────────────────
class _GuestPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('👨‍👩‍👧', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('Sign in to access\nParent Dashboard',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Nunito', fontSize: 22,
          fontWeight: FontWeight.w900, color: AppColors.textDark)),
      const SizedBox(height: 8),
      const Text('Track your child\'s career journey and see their top matches.',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: AppColors.textMid)),
      const SizedBox(height: 24),
      PrimaryBtn(label: 'Sign In',
        onPressed: () => context.push(AppConstants.routeLogin)),
      const SizedBox(height: 12),
      OutlineBtn(label: 'Create Account',
        onPressed: () => context.push(AppConstants.routeSignup)),
    ]));
}
