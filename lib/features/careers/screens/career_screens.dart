// lib/features/careers/screens/career_screens.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../../core/widgets/external_link.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/models.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _careerCoursesProvider = FutureProvider.family<List<Course>, String>((ref, careerId) async {
  final links = await Supabase.instance.client
    .from('career_course').select('course_id').eq('career_id', careerId);
  final ids = (links as List).map((e) => e['course_id'] as String).toList();
  if (ids.isEmpty) return [];
  final all = await DbService.getAllCourses();
  return all.where((c) => ids.contains(c.id)).toList();
});

class _SkillItem { final String emoji, name; final double level; const _SkillItem(this.emoji, this.name, this.level); }
class _RouteItem { final Color color; final String emoji, title, duration; final List<String> pros, cons; const _RouteItem(this.color, this.emoji, this.title, this.duration, this.pros, this.cons); }
class _CompareHeader { final String emoji, name; final Color color; const _CompareHeader(this.emoji, this.name, this.color); }
class _MatchReason { final String emoji, text; final Color color; const _MatchReason(this.emoji, this.text, this.color); }

class CareerDetailScreen extends ConsumerStatefulWidget {
  final String careerId;
  const CareerDetailScreen({super.key, required this.careerId});
  @override
  ConsumerState<CareerDetailScreen> createState() => _CareerDetailState();
}

class _CareerDetailState extends ConsumerState<CareerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    DbService.isItemSaved(widget.careerId).then((v) {
      if (mounted) setState(() => _saved = v);
    });
  }

  Future<void> _toggle(String name, String? salary) async {
    if (_saved) {
      await DbService.unsaveItem(widget.careerId);
    } else {
      await DbService.saveItem(itemType: 'career', itemId: widget.careerId,
        title: name, subtitle: salary);
    }
    setState(() => _saved = !_saved);
    ref.invalidate(savedItemsProvider);
  }


  void _showRoadmapSheet(BuildContext ctx, WidgetRef ref,
      String careerId, String careerName) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(ctx),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.4,
          expand: false,
          builder: (_, ctrl) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Scaffold(
              appBar: AppBar(
                title: Text('$careerName — Pathway',
                  style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 16, fontWeight: FontWeight.w800)),
                leading: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const BackBtn())),
              body: _RoadmapSheet(
                careerId: careerId,
                careerName: careerName,
                scrollController: ctrl))))));
  }

  @override
  Widget build(BuildContext context) {
    final careerAsync  = ref.watch(careerByIdProvider(widget.careerId));
    final coursesAsync = ref.watch(_careerCoursesProvider(widget.careerId));
    final matchesAsync = ref.watch(matchesProvider);
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;

    return Scaffold(
      body: careerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (career) {
          if (career == null) return const ErrorView(message: 'Career not found');
          final myMatch = matchesAsync.valueOrNull?.where(
            (m) => (m as AppMatch).careerId == widget.careerId).firstOrNull;
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 240, pinned: true,
                backgroundColor: AppColors.primary,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white))),
                actions: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                    tooltip: 'Dashboard'),
                  IconButton(
                    onPressed: () => _toggle(career.displayName, career.avgSalary),
                    icon: Icon(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _saved ? Colors.red[300] : Colors.white)),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: gradientBox(radius: 0),
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (myMatch != null) Row(children: [
                        MatchRing(pct: myMatch.matchScore, size: 42),
                        const SizedBox(width: 10),
                        Text('${myMatch.matchScore}% Match',
                          style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                      const SizedBox(height: 8),
                      Text(career.displayName, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(children: [
                        TagBadge(label: career.salaryDisplay,
                          bg: Colors.white.withOpacity(0.2), fg: Colors.white),
                      ]),
                    ])),
                ),
                bottom: TabBar(
                  controller: _tabs,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: const [Tab(text: 'Overview'), Tab(text: 'Skills'), Tab(text: 'Institutions')],
                ),
              ),
            ],
            body: TabBarView(controller: _tabs, children: [
              SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
                EduCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('About this career', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(career.description ?? 'A rewarding career with excellent prospects combining expertise with real-world problem solving.',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                      color: AppColors.textMid, height: 1.6)),
                ])),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _StatBox('💰', 'Avg Salary', career.salaryDisplay)),
                  const SizedBox(width: 10),
                  const Expanded(child: _StatBox('🔥', 'Demand', 'High')),
                ]),
                const SizedBox(height: 10),
                const Row(children: [
                  Expanded(child: _StatBox('🏢', 'Work Style', 'Flexible')),
                  SizedBox(width: 10),
                  Expanded(child: _StatBox('🎓', 'Study Time', '3-4 Years')),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: PrimaryBtn(label: 'View Full Pathway',
                    onPressed: () => _showRoadmapSheet(context, ref, career.id, career.displayName))),
                  const SizedBox(width: 10),
    
                ]),
                const SizedBox(height: 10),
                EduCard(
                  color: AppColors.primaryPale,
                  onTap: () {
                  final isPrem = ref.read(isPremiumProvider).valueOrNull ?? false;
                  isPrem ? context.push('${AppConstants.routeCompare}?career=${widget.careerId}') : context.push(AppConstants.routePricing);
                },
                  child: const Row(children: [
                    Text('⚖️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('Compare Routes', style: TextStyle(fontFamily: 'Nunito',
                          fontSize: 14, fontWeight: FontWeight.w800)),
                        SizedBox(width: 6),
                        Icon(Icons.lock_rounded, size: 14,
                           color: AppColors.textLight),
                      ]),
                      Text('Uni vs Apprenticeship vs Bootcamp',
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ])),
              ])),
              _SkillsTab(careerId: widget.careerId),
              coursesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(message: e.toString()),
                data: (courses) => _CoursesTab(courses: courses),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji, label, value;
  const _StatBox(this.emoji, this.label, this.value);
  @override
  Widget build(BuildContext context) => EduCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 11, color: AppColors.textMid, fontWeight: FontWeight.w600)),
      Text(value, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 15, fontWeight: FontWeight.w800)),
    ]));
}

class _TopCareersTab extends ConsumerWidget {
  final String careerId;
  const _TopCareersTab({required this.careerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(allCareersProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (careers) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: careers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => EduCard(
          onTap: () => context.push('/pathway/${careers[i].id}'),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(careers[i].displayName, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700)),
              Text(careers[i].salaryDisplay, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ])),
      ),
    );
  }
}

class _CoursesTab extends StatelessWidget {
  final List<dynamic> courses;
  const _CoursesTab({required this.courses});
  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const EmptyState(emoji: '🎓',
      title: 'No courses yet', subtitle: 'Courses will appear here soon');
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = courses[i];
        return EduCard(
          onTap: () => context.push('/course/${c.id}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(c.trimmed, style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800))),
            TagBadge(label: c.isApprenticeship ? '🔨 Apprenticeship' : '🎓 Degree'),
          ]),
          if (c.institution != null) ...[
            const SizedBox(height: 4),
            Text(c.institution!.trimmed, style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
          ],
          if (c.duration != null) ...[
            const SizedBox(height: 8),
            Text(c.duration!, style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
          ],
        ]));
      });
  }
}

// Skills are stored per-career in the careers.skills column (jsonb) so
// every career shows its own tailored list (user request, item 4).
final _careerSkillsProvider =
    FutureProvider.family<List<_SkillItem>, String>((ref, careerId) async {
  try {
    final res = await Supabase.instance.client
        .from('careers').select('skills').eq('id', careerId).maybeSingle();
    final raw = res?['skills'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => _SkillItem(
        (e['e'] ?? '💡') as String,
        (e['n'] ?? '') as String,
        ((e['p'] ?? 0.8) as num).toDouble(),
      )).toList();
    }
  } catch (_) {}
  // Fallback if a career has no tailored data yet
  return const [
    _SkillItem('💡', 'Problem Solving', 0.9),
    _SkillItem('💬', 'Communication', 0.8),
    _SkillItem('🤝', 'Teamwork', 0.75),
    _SkillItem('📊', 'Analytical Thinking', 0.8),
  ];
});

class _SkillsTab extends ConsumerWidget {
  final String careerId;
  const _SkillsTab({required this.careerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(_careerSkillsProvider(careerId));
    final skills = skillsAsync.valueOrNull;
    if (skills == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(padding: const EdgeInsets.all(20), children: [
      EduCard(child: Column(children: skills.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(s.emoji), const SizedBox(width: 8),
            Text(s.name, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${(s.level * 100).toInt()}%', style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: s.level, minHeight: 8,
              backgroundColor: AppColors.bgGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary))),
        ]))).toList())),
    ]);
  }
}

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseByIdProvider(courseId));
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (course) {
          if (course == null) return const ErrorView(message: 'Course not found');
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 180, pinned: true,
              backgroundColor: AppColors.accentBlue,
              leading: GestureDetector(onTap: () => context.pop(),
                child: Container(margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white))),
              actions: [
                Consumer(builder: (ctx, r, _) {
                  return FutureBuilder<bool>(
                    future: DbService.isItemSaved(courseId),
                    builder: (ctx, snap) {
                      final saved = snap.data ?? false;
                      return IconButton(
                        icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: Colors.white),
                        tooltip: saved ? 'Saved' : 'Save course',
                        onPressed: () async {
                          if (saved) {
                            await DbService.unsaveItem(courseId);
                          } else {
                            await DbService.saveItem(
                              itemType: 'course',
                              itemId: courseId,
                              title: course?.title ?? '',
                              subtitle: course?.institution?.name);
                          }
                          r.invalidate(savedItemsProvider);
                          (ctx as Element).markNeedsBuild();
                        });
                    });
                }),
                IconButton(icon: const Icon(Icons.home_rounded, color: Colors.white),
                  tooltip: 'Dashboard', onPressed: () => context.go('/home')),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.primary])),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    TagBadge(label: course.isApprenticeship ? '🔨 Apprenticeship' : '🎓 Degree',
                      bg: Colors.white.withOpacity(0.2), fg: Colors.white),
                    const SizedBox(height: 8),
                    Text(course.trimmed, style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900,
                      color: Colors.white)),
                    if (course.institution != null) Text(course.institution!.trimmed,
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                        color: Colors.white.withOpacity(0.75))),
                  ])),
              ),
            ),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                EduCard(child: Column(children: [
                  _InfoRow('Duration', course.duration ?? 'See website'),
                  _InfoRow('Location', course.institution?.location ?? 'UK'),
                  _InfoRow('Fees (Home)', course.feesHome != null ? '£${course.feesHome}/yr' : 'See website'),
                  _InfoRow('Institution', course.institution?.trimmed ?? 'TBC'),
                  if (course.ucasCode != null) _InfoRow('UCAS Code', course.ucasCode!),
                  if (course.startDate != null) _InfoRow('Start Date', course.startDate!),
                ])),
                const SizedBox(height: 16),
                PrimaryBtn(label: 'Apply / Learn More', onPressed: () async {
                  final url = course.url ?? '';
                  if (url.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('No link available for this course.')));
                    return;
                  }
                  // F4 — normalize schemeless URLs (e.g. "www.ox.ac.uk")
                  // and open in a new tab.
                  await launchExternal(url);
                }),
                const SizedBox(height: 10),
                OutlineBtn(label: 'Save Course', onPressed: () async {
                  await DbService.saveItem(itemType: 'course', itemId: course.id,
                    title: course.trimmed, subtitle: course.institution?.trimmed);
                  ref.invalidate(savedItemsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Course saved! ✓'), backgroundColor: AppColors.success));
                }),
              ]),
            )),
          ]);
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 13, color: AppColors.textMid)),
      Text(value, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 13, fontWeight: FontWeight.w700)),
    ]));
}

class AltRoutesScreen extends ConsumerWidget {
  final String careerId;
  const AltRoutesScreen({super.key, required this.careerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careerAsync = ref.watch(careerByIdProvider(careerId));
    final routes = [
      _RouteItem(AppColors.primary, '🎓', 'University Route', '3-4 years',
        ['Deep knowledge', 'Graduate network', 'Research opportunities'],
        ['Student debt', 'Longer time to work']),
      _RouteItem(AppColors.accentGreen, '🔨', 'Apprenticeship Route', '3-5 years',
        ['No student debt', 'Earn while you learn', 'Industry experience'],
        ['Fewer places', 'Less flexibility']),
      _RouteItem(AppColors.accentOrange, '⚡', 'Bootcamp Route', '3-12 months',
        ['Fast-track skills', 'Portfolio-focused', 'No entry requirements'],
        ['Less recognition', 'Self-funded']),
    ];
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: const Text('Alternative Routes'),
        leading: GestureDetector(onTap: () => context.pop(), child: const BackBtn()),
        actions: [IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Dashboard', onPressed: () => context.go(AppConstants.routeHome))]),
      body: careerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (career) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Alternative Routes to\n${career?.displayName ?? "Career"}',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            ...routes.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(color: r.color, width: 4))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(r.title, style: const TextStyle(fontFamily: 'Nunito',
                      fontSize: 15, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    TagBadge(label: r.duration),
                  ]),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Pros', style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentGreen)),
                      const SizedBox(height: 4),
                      ...r.pros.map((p) => Text('• $p', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid))),
                    ])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Cons', style: TextStyle(fontFamily: 'Nunito',
                        fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accentOrange)),
                      const SizedBox(height: 4),
                      ...r.cons.map((c) => Text('• $c', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid))),
                    ])),
                  ]),
                ])))),
            const SizedBox(height: 20),
            PrimaryBtn(label: 'Compare All Routes ⚖️',
              onPressed: () {
                final isPrem = ref.read(isPremiumProvider).valueOrNull ?? false;
                if (isPrem) { context.push('${AppConstants.routeCompare}?career=$careerId'); }
                else { context.push(AppConstants.routePricing); }
              }),
          ]),
        ),
      ),
    );
  }
}

// Per-career route comparison facts, computed from the live catalogue
// (user request, item 5): how many university courses vs apprenticeships
// this career actually has in EduPaths, its typical salary, and its
// required qualifications.
final _compareFactsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, careerId) async {
    final sb = Supabase.instance.client;
    final result = <String, dynamic>{};
    try {
      final career = await sb.from('careers')
          .select('name, avg_salary').eq('id', careerId).maybeSingle();
      result['name'] = career?['name'];
      result['salary'] = career?['avg_salary'];

      final linked = await sb.from('career_course')
          .select('courses(title)').eq('career_id', careerId);
      int uni = 0, app = 0;
      for (final row in (linked as List)) {
        final c = row['courses'] as Map<String, dynamic>?;
        if (c == null) continue;
        final t = (c['title'] ?? '').toString().toLowerCase();
        (t.contains('apprenticeship') || t.contains('bootcamp')) ? app++ : uni++;
      }
      result['uni'] = uni;
      result['app'] = app;

      final quals = await sb.from('career_preclass')
          .select('importance, preclass!inner(title, type)')
          .eq('career_id', careerId).eq('importance', 'required').limit(4);
      result['required'] = (quals as List)
          .map((q) => (q['preclass'] as Map)['title'] as String)
          .toList();
    } catch (_) {}
    return result;
  });

class CompareScreen extends ConsumerWidget {
  final String? careerId;
  const CompareScreen({super.key, this.careerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = careerId != null && careerId!.isNotEmpty
        ? ref.watch(_compareFactsProvider(careerId!)).valueOrNull
        : null;
    final careerName = facts?['name'] as String?;
    final salary = facts?['salary'];
    final uniCount = facts?['uni'] as int? ?? 0;
    final appCount = facts?['app'] as int? ?? 0;
    final required = (facts?['required'] as List?)?.cast<String>() ?? const [];

    final rows = [
      ['Duration',    '3-4 yrs',    '3-5 yrs',        '3-12 mo'],
      ['Cost',        '£28k-45k',   'Employer funded', '£3k-10k'],
      ['Earn salary', 'No',         'Yes',             'No'],
      ['Entry req.',  'A-levels',   '3 GCSEs+',        'None'],
      ['Time to job', 'Longer',     'Medium',          'Shorter'],
      // Career-specific rows (only when opened from a career page)
      if (facts != null)
        ['In EduPaths', '$uniCount option${uniCount == 1 ? '' : 's'}',
          '$appCount option${appCount == 1 ? '' : 's'}', '—'],
    ];
    final headers = [
      _CompareHeader('🎓', 'University', AppColors.primary),
      _CompareHeader('🔨', 'Apprenticeship', AppColors.accentGreen),
      _CompareHeader('⚡', 'Bootcamp', AppColors.accentOrange),
    ];
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: Text(careerName != null ? 'Routes: $careerName ⚖️' : 'Compare Routes ⚖️'),
        leading: GestureDetector(onTap: () => context.pop(), child: const BackBtn()),
        actions: [IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Dashboard', onPressed: () => context.go(AppConstants.routeHome))]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          if (careerName != null) ...[
            EduCard(
              color: AppColors.primaryPale,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Routes into $careerName', style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                if (salary != null)
                  Text('Typical salary: £$salary', style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
                if (required.isNotEmpty)
                  Text('Usually required: ${required.join(', ')}',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                      color: AppColors.textMid)),
              ])),
            const SizedBox(height: 16),
          ],
          Row(children: [
            const SizedBox(width: 90),
            ...headers.map((h) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: h.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text(h.emoji, style: const TextStyle(fontSize: 20)),
                  Text(h.name, textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                      fontWeight: FontWeight.w800, color: h.color)),
                ]))))),
          ]),
          const SizedBox(height: 12),
          ...rows.asMap().entries.map((e) => Container(
            color: e.key.isEven ? AppColors.bgGrey.withOpacity(0.5) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              SizedBox(width: 90, child: Text(e.value[0],
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                  fontWeight: FontWeight.w700, color: AppColors.textMid))),
              ...e.value.skip(1).map((v) => Expanded(child: Text(v,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                  fontWeight: FontWeight.w600)))),
            ]))),
          const SizedBox(height: 24),
          OutlineBtn(label: 'Back', onPressed: () => context.pop()),
        ]),
      ),
    );
  }
}

class WhyMatchScreen extends ConsumerWidget {
  final String careerId;
  const WhyMatchScreen({super.key, required this.careerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careerAsync = ref.watch(careerByIdProvider(careerId));
    final matchesAsync = ref.watch(matchesProvider);

    // Get the actual match reason from the database
    final myMatch = matchesAsync.valueOrNull?.firstWhere(
      (m) => (m as AppMatch).careerId == careerId,
      orElse: () => null as dynamic,
    );
    final AppMatch? match = myMatch as AppMatch?;
    final matchScore = match?.matchScore ?? 0;
    final matchReason = match?.matchReason ?? '';

    // Parse matched interests and traits from match_reason
    final List<_MatchReason> reasons = [];
    if (matchReason.contains('Matched on:') || matchReason.contains('Matched on your interests')) {
      final interestPart = matchReason.replaceAll('Matched on:', '').replaceAll('Matched on your interests in:', '').split('·').first.trim();
      final traitPart = matchReason.contains('Strengths:') ? matchReason.split('Strengths:').last.trim() : '';

      if (interestPart.isNotEmpty) {
        for (final interest in interestPart.split(', ')) {
          if (interest.trim().isNotEmpty) {
            reasons.add(_MatchReason('🎯', 'You selected "${interest.trim()}" as an interest', AppColors.primary));
          }
        }
      }
      if (traitPart.isNotEmpty) {
        for (final trait in traitPart.split(', ')) {
          if (trait.trim().isNotEmpty) {
            reasons.add(_MatchReason('⭐', trait.trim(), AppColors.accentGreen));
          }
        }
      }
    }

    // Fallback generic reasons if no match data
    if (reasons.isEmpty) {
      reasons.addAll([
        _MatchReason('🎯', 'Your interests align with this career pathway', AppColors.primary),
        _MatchReason('⭐', 'Your strengths match skills needed in this field', AppColors.accentGreen),
        _MatchReason('📚', 'Relevant courses are available to you', AppColors.accentBlue),
        _MatchReason('💼', 'Strong job demand in this sector', AppColors.accentYellow),
      ]);
    }
    // reasons list built above
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: const Text('Why This Matches You'),
        leading: GestureDetector(onTap: () => context.pop(), child: const BackBtn()),
        actions: [IconButton(icon: const Icon(Icons.home_rounded), tooltip: 'Dashboard', onPressed: () => context.go(AppConstants.routeHome))]),
      body: careerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (career) {
          // match already computed above
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(20),
                decoration: gradientBox(radius: 20,
                  colors: [AppColors.accentPink, AppColors.primary]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Why This Matches You', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 11, color: Colors.white70,
                    fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(career?.displayName ?? '', style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900,
                    color: Colors.white)),
                  if (match != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      MatchRing(pct: match.matchScore, size: 40),
                      const SizedBox(width: 10),
                      Text('${match.matchScore}% Match', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 16,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ],
                ])),
              const SizedBox(height: 20),
              const Text('Top reasons this suits you:', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 16,
                fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 12),
              ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EduCard(padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Text(r.emoji), const SizedBox(width: 12),
                    Expanded(child: Text(r.text, style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700))),
                  ])))),
              const SizedBox(height: 20),
              PrimaryBtn(label: 'Explore This Pathway',
                onPressed: () => context.push('/pathway/$careerId')),
            ]),
          );
        },
      ),
    );
  }
}

// ── Career roadmap provider ───────────────────
final _careerRoadmapProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, careerId) async {
    if (careerId.isEmpty) return [];
    try {
      final res = await Supabase.instance.client
          .from('career_preclass')
          .select('importance, target_grade, notes, preclass!inner(id, title, type, level)')
          .eq('career_id', careerId);
      final list = (res as List).map((e) {
        final p = e['preclass'] as Map<String, dynamic>;
        return {
          'id': p['id'],
          'title': p['title'],
          'type': p['type'],
          'level': p['level'] ?? '',
          'importance': e['importance'] ?? 'recommended',
          'target_grade': e['target_grade'] ?? '',
          'notes': e['notes'] ?? '',
        };
      }).toList();
      const typeOrder = ['GCSE', 'A-Level', 'BTEC', 'T-Level'];
      list.sort((a, b) {
        final ai = typeOrder.indexOf(a['type'] as String);
        final bi = typeOrder.indexOf(b['type'] as String);
        return ai.compareTo(bi);
      });
      return list;
    } catch (e) {
      return [];
    }
  });

// ══════════════════════════════════════════════
// ROADMAP SHEET — shown from View Full Pathway
// ══════════════════════════════════════════════
class _RoadmapSheet extends ConsumerWidget {
  final String careerId;
  final String careerName;
  final ScrollController scrollController;
  const _RoadmapSheet({
    required this.careerId,
    required this.careerName,
    required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmapAsync = ref.watch(_careerRoadmapProvider(careerId));
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;

    return roadmapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: ErrorView(message: e.toString())),
      data: (qualifications) {
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final q in qualifications) {
          grouped.putIfAbsent(q['type'] as String, () => []).add(q);
        }
        const typeOrder = ['GCSE', 'A-Level', 'BTEC', 'T-Level'];

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: gradientBox(radius: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(careerName, style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 20,
                  fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Recommended qualification pathway',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: Colors.white70)),
              ])),
            const SizedBox(height: 20),
            if (qualifications.isEmpty)
              const EmptyState(emoji: '📚',
                title: 'No qualifications data yet',
                subtitle: 'Check back soon')
            else ...[
              ...typeOrder.where((t) => grouped.containsKey(t)).map((type) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Row(children: [
                      Text(_typeEmoji(type),
                        style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(type, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 15,
                        fontWeight: FontWeight.w900)),
                    ])),
                  ...grouped[type]!.map((q) {
                    final isRequired = q['importance'] == 'required';
                    final grade = q['target_grade'] as String?;
                    final isLocked = !isPremium && type == 'GCSE';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EduCard(
                        color: isLocked
                            ? AppColors.bgGrey
                            : isRequired
                                ? const Color(0xFFFFF8F8) : null,
                        child: Row(children: [
                          Container(width: 6, height: 40,
                            decoration: BoxDecoration(
                              color: isLocked ? AppColors.border
                                  : isRequired ? AppColors.error
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            if (isLocked)
                              Row(children: [
                                const Icon(Icons.lock_rounded,
                                  size: 14, color: AppColors.textLight),
                                const SizedBox(width: 6),
                                Text(q['title'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito', fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textLight)),
                              ])
                            else ...[
                              Text(q['title'] as String,
                                style: const TextStyle(fontFamily: 'Nunito',
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                              if (grade != null && grade.isNotEmpty)
                                Text('Target: $grade',
                                  style: const TextStyle(fontFamily: 'Nunito',
                                    fontSize: 11, color: AppColors.textMid)),
                            ],
                          ])),
                          if (isLocked)
                            GestureDetector(
                              onTap: () => context.push(AppConstants.routePricing),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(999)),
                                child: const Text('Unlock',
                                  style: TextStyle(fontFamily: 'Nunito',
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: Colors.white))))
                          else ...[
                            TagBadge(
                              label: q['level'] as String? ?? '',
                              bg: AppColors.primaryPale,
                              fg: AppColors.primaryDark),
                            if (isRequired) ...[
                              const SizedBox(width: 4),
                              const TagBadge(label: 'Required',
                                bg: Color(0xFFFFE5E5),
                                fg: AppColors.error),
                            ],
                          ],
                        ])));
                  }),
                ])),
              if (!isPremium) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push(AppConstants.routePricing),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: gradientBox(radius: 14),
                    child: const Row(children: [
                      Text('🔒', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text('Unlock Full GCSE Details',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                            fontWeight: FontWeight.w900, color: Colors.white)),
                        Text('Upgrade to Premium to see all target grades.',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                            color: Colors.white70)),
                      ])),
                    ])),
                ),
              ],
            ],
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'GCSE': return '📚';
      case 'A-Level': return '✏️';
      case 'BTEC': return '📋';
      case 'T-Level': return '🔧';
      default: return '📄';
    }
  }
}


// ══════════════════════════════════════════════
// CAREERS BY CATEGORY SCREEN
// ══════════════════════════════════════════════
class CareersByCategoryScreen extends ConsumerWidget {
  final String category;
  const CareersByCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careersAsync = ref.watch(allCareersProvider);
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: Text(category, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900))),
      body: careersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (careers) {
          final filtered = careers.where((c) =>
              c.category == category).toList();
          if (filtered.isEmpty) {
            // Try partial match
            final partial = careers.where((c) =>
                c.category?.contains(category.split(' ').first) == true ||
                category.contains(c.category?.split(' ').first ?? '')).toList();
            return _buildList(context, partial, isPremium);
          }
          return _buildList(context, filtered, isPremium);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Career> careers, bool isPremium) {
    if (careers.isEmpty) return const EmptyState(emoji: '💼',
      title: 'No careers found', subtitle: 'Try browsing all careers');

    // Free users see first 5, rest locked
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: careers.length + (isPremium ? 0 : 1),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        // Premium upsell card at end for free users
        if (!isPremium && i == 5) {
          return GestureDetector(
            onTap: () => context.push(AppConstants.routePricing),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: gradientBox(radius: 14),
              child: Row(children: [
                const Text('🔒', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${careers.length - 5} more careers in $category',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
                      fontWeight: FontWeight.w900, color: Colors.white)),
                  const Text('Upgrade to Premium to see all careers.',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                      color: Colors.white70)),
                ])),
              ])));
        }
        if (!isPremium && i >= 5) return const SizedBox();
        final career = careers[i];
        return EduCard(
          onTap: () => context.push('/pathway/${career.id}'),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.work_outline_rounded,
                color: AppColors.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(career.displayName, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 14,
                fontWeight: FontWeight.w800)),
              Text(career.salaryDisplay, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12,
                color: AppColors.textMid)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ]));
      });
  }
}
