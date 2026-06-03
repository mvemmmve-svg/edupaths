// lib/features/roadmap/screens/roadmap_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

// Provider for career-specific roadmap qualifications
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
      // Sort: required first, then by type order
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
  },
);

final _preclassTypeProvider = StateProvider<String>((ref) => 'GCSE');

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchesProvider);
    final userAsync = ref.watch(appUserProvider);
    final topMatch = matchAsync.valueOrNull?.isNotEmpty == true
        ? matchAsync.value!.first : null;
    // Roadmap always shows user's top career match - never overridden by career browsing
    final topCareerId = topMatch?.careerId ?? '';
    final topCareerName = topMatch?.careerName ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Roadmap 🗺️', style: Theme.of(context).textTheme.displayMedium),
              if (topCareerName.isNotEmpty)
                Text('Your path to: $topCareerName',
                  style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 13, color: AppColors.textMid)),
            ])),
          ]),

          const SizedBox(height: 20),

          // ── Career-specific qualification guide ──────────
          if (topCareerId.isNotEmpty) ...[
            const SectionHeader(title: 'Recommended Qualifications'),
            const SizedBox(height: 4),
            Text('Based on your top match: $topCareerName',
              style: const TextStyle(fontFamily: 'Nunito',
                fontSize: 12, color: AppColors.textMid)),
            const SizedBox(height: 12),
            _CareerQualificationGuide(careerId: topCareerId, careerName: topCareerName),
            const SizedBox(height: 24),
          ],

          // ── Journey Timeline ──────────────────────────────
          const SectionHeader(title: 'Your Learning Journey'),
          const SizedBox(height: 16),
          _TimelineItem(color: AppColors.accentGreen, emoji: '📚',
            year: 'Now', title: 'GCSE Preparation',
            desc: 'Focus on core subjects relevant to your career goal. Target grade 4+ in Maths and English.',
            done: true),
          _TimelineItem(color: AppColors.primary, emoji: '✏️',
            year: '2025', title: 'A-Levels / BTECs / T-Levels',
            desc: 'Choose subjects aligned with your pathway. Apply via UCAS or direct apprenticeship.',
            done: true),
          _TimelineItem(color: AppColors.primaryLight, emoji: '🎓',
            year: '2026', title: 'University or Apprenticeship',
            desc: 'Start your degree, degree apprenticeship or higher apprenticeship.',
            done: false),
          _TimelineItem(color: AppColors.accentYellow, emoji: '💼',
            year: '2028+', title: 'Career Goal',
            desc: 'Graduate and enter your chosen field. Build experience and grow.',
            done: false),

          const SizedBox(height: 24),

          // ── Full qualification browser ────────────────────
          const SectionHeader(title: 'All Qualifications 📋'),
          const SizedBox(height: 8),
          const Text('Browse all qualifications by type.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
          const SizedBox(height: 12),
          _QualificationBrowser(),

          const SizedBox(height: 24),

          // ── Notifications ─────────────────────────────────
          EduCard(
            color: AppColors.primaryPale,
            onTap: () => context.push(AppConstants.routeNotifications),
            child: const Row(children: [
              Text('🔔', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Upcoming Deadlines', style: TextStyle(fontFamily: 'Nunito',
                  fontSize: 14, fontWeight: FontWeight.w800)),
                Text('UCAS deadline — 25 Jan | Apprenticeship applications open',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                    color: AppColors.textMid)),
              ])),
              Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ]),
          ),
          const SizedBox(height: 80),
        ]),
      )),
    );
  }
}

// Shows qualifications specifically for the user's top career match
class _CareerQualificationGuide extends ConsumerStatefulWidget {
  final String careerId;
  final String careerName;
  const _CareerQualificationGuide({required this.careerId, required this.careerName});
  @override
  ConsumerState<_CareerQualificationGuide> createState() => _CareerQualificationGuideState();
}

class _CareerQualificationGuideState extends ConsumerState<_CareerQualificationGuide> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final roadmapAsync = ref.watch(_careerRoadmapProvider(widget.careerId));
    final selectedType = ref.watch(_preclassTypeProvider);
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;
    final types = ['GCSE', 'A-Level', 'BTEC', 'T-Level'];
    final typeEmojis = {'GCSE': '📗', 'A-Level': '📘', 'BTEC': '📙', 'T-Level': '📕'};

    return roadmapAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (qualifications) {
        // Filter by type
        var filtered = qualifications
            .where((q) => q['type'] == selectedType)
            .toList();
        // Deduplicate by title
        final seen = <String>{};
        filtered = filtered.where((q) {
          final title = q['title'] as String;
          if (seen.contains(title)) return false;
          seen.add(title);
          return true;
        }).toList();
        // Sort alphabetically
        filtered.sort((a, b) =>
            (a['title'] as String).compareTo(b['title'] as String));
        // Apply search filter
        if (_search.isNotEmpty) {
          filtered = filtered.where((q) =>
              (q['title'] as String).toLowerCase()
                  .contains(_search.toLowerCase())).toList();
        }

        return Column(children: [
          // Type selector tabs
          SizedBox(height: 44,
            child: ListView(scrollDirection: Axis.horizontal, children: types.map((t) {
              final sel = selectedType == t;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ref.read(_preclassTypeProvider.notifier).state = t,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border)),
                    child: Text('${typeEmojis[t]} $t',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.textMid)))));
            }).toList())),
          const SizedBox(height: 12),
          // Search bar
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search ${selectedType}s...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10))),
          const SizedBox(height: 12),
          // Results count
          Text('${filtered.length} ${selectedType}s found',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
              color: AppColors.textMid)),
          const SizedBox(height: 8),
          // Qualification list
          ...filtered.map((q) {
            final isRequired = q['importance'] == 'required';
            final grade = q['target_grade'] as String? ?? '';
            final isLocked = !isPremium && selectedType == 'GCSE';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EduCard(
                color: isLocked ? AppColors.bgGrey
                    : isRequired ? const Color(0xFFFFF8F8) : null,
                child: Row(children: [
                  Container(width: 5, height: 44,
                    decoration: BoxDecoration(
                      color: isLocked ? AppColors.border
                          : isRequired ? AppColors.error : AppColors.primary,
                      borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (isLocked)
                      Row(children: [
                        const Icon(Icons.lock_rounded, size: 13, color: AppColors.textLight),
                        const SizedBox(width: 6),
                        Expanded(child: Text(q['title'] as String,
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                            fontWeight: FontWeight.w700, color: AppColors.textLight))),
                      ])
                    else ...[
                      Text(q['title'] as String, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700)),
                      if (grade.isNotEmpty)
                        Text('Target: $grade', style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 11, color: AppColors.textMid)),
                    ],
                  ])),
                  if (isLocked)
                    GestureDetector(
                      onTap: () => context.push(AppConstants.routePricing),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999)),
                        child: const Text('Unlock', style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 11,
                          fontWeight: FontWeight.w700, color: Colors.white))))
                  else
                    TagBadge(label: q['level'] as String? ?? '',
                      bg: AppColors.primaryPale, fg: AppColors.primaryDark),
                ])));
          }),
        ]);
      },
    );
  }
}


class _DynamicTimeline extends ConsumerWidget {
  final String careerId;
  final String careerName;
  final AsyncValue userAsync;
  const _DynamicTimeline({
    required this.careerId, required this.careerName, required this.userAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = userAsync.valueOrNull;
    final schoolYear = (user?.schoolYear ?? 'Year 11').trim();
    
    // Calculate years based on school year
    final now = DateTime.now().year;
    final int gcseYear, aLevelYear, uniYear, careerYear;
    
    if (schoolYear.contains('9')) {
      gcseYear = now + 2; aLevelYear = now + 4;
      uniYear = now + 6; careerYear = now + 9;
    } else if (schoolYear.contains('10')) {
      gcseYear = now + 1; aLevelYear = now + 3;
      uniYear = now + 5; careerYear = now + 8;
    } else if (schoolYear.contains('11')) {
      gcseYear = now; aLevelYear = now + 2;
      uniYear = now + 4; careerYear = now + 7;
    } else if (schoolYear.contains('12')) {
      gcseYear = now - 1; aLevelYear = now + 1;
      uniYear = now + 3; careerYear = now + 6;
    } else if (schoolYear.contains('13') || schoolYear.contains('Sixth')) {
      gcseYear = now - 2; aLevelYear = now;
      uniYear = now + 2; careerYear = now + 5;
    } else {
      gcseYear = now; aLevelYear = now + 2;
      uniYear = now + 4; careerYear = now + 7;
    }

    // Career-specific GCSE guidance
    final gcseDesc = _gcseDesc(careerName);
    final aLevelDesc = _aLevelDesc(careerName);
    final uniDesc = _uniDesc(careerName);

    final gcseComplete = gcseYear <= now;
    final aLevelComplete = aLevelYear <= now;

    return Column(children: [
      _TimelineItem(color: AppColors.accentGreen, emoji: '📚',
        year: gcseComplete ? 'Completed' : '$gcseYear',
        title: 'GCSE Preparation',
        desc: gcseDesc,
        done: gcseComplete),
      _TimelineItem(color: AppColors.primary, emoji: '✏️',
        year: aLevelComplete ? 'Completed' : '$aLevelYear',
        title: 'A-Levels / BTECs / T-Levels',
        desc: aLevelDesc,
        done: aLevelComplete),
      _TimelineItem(color: AppColors.primaryLight, emoji: '🎓',
        year: '$uniYear',
        title: 'University or Apprenticeship',
        desc: uniDesc,
        done: false),
      _TimelineItem(color: AppColors.accentYellow, emoji: '💼',
        year: '$careerYear+',
        title: careerName.isNotEmpty ? 'Become a $careerName' : 'Career Goal',
        desc: 'Enter your chosen field, gain experience and grow professionally.',
        done: false),
    ]);
  }

  String _gcseDesc(String career) {
    if (career.isEmpty) return 'Focus on core subjects. Target Grade 5+ in Maths and English.';
    final c = career.toLowerCase();
    if (c.contains('nurs') || c.contains('midwi'))
      return '• Biology — Grade 6+ (required)\n• Mathematics — Grade 5+ (required)\n• English Language — Grade 5+ (required)\n• Health & Social Care — Grade 5+ (recommended)';
    if (c.contains('paramedic'))
      return '• Biology — Grade 5+ (required)\n• Mathematics — Grade 5+ (required)\n• English Language — Grade 5+ (required)\n• Health & Social Care — Grade 4+ (recommended)';
    if (c.contains('doctor'))
      return '• Biology — Grade 7+ (required)\n• Chemistry — Grade 7+ (required)\n• Mathematics — Grade 6+ (required)\n• English Language — Grade 5+ (required)';
    if (c.contains('dentist'))
      return '• Biology — Grade 7+ (required)\n• Chemistry — Grade 7+ (required)\n• Mathematics — Grade 6+ (required)\n• English Language — Grade 5+ (required)';
    if (c.contains('physio'))
      return '• Biology — Grade 6+ (required)\n• Mathematics — Grade 5+ (required)\n• Physical Education — Grade 5+ (recommended)\n• English Language — Grade 5+ (required)';
    if (c.contains('software') || c.contains('developer'))
      return '• Mathematics — Grade 6+ (required)\n• Computer Science — Grade 6+ (required)\n• English Language — Grade 5+ (required)\n• Physics — Grade 5+ (recommended)';
    if (c.contains('cyber'))
      return '• Mathematics — Grade 6+ (required)\n• Computer Science — Grade 6+ (required)\n• English Language — Grade 5+ (required)';
    if (c.contains('data') || c.contains('ai engineer'))
      return '• Mathematics — Grade 7+ (required)\n• Computer Science — Grade 6+ (recommended)\n• Statistics — Grade 6+ (recommended)\n• English Language — Grade 5+ (required)';
    if (c.contains('law') || c.contains('solicit'))
      return '• English Language — Grade 6+ (required)\n• Mathematics — Grade 5+ (required)\n• History — Grade 5+ (recommended)\n• English Literature — Grade 5+ (recommended)';
    if (c.contains('civil eng') || c.contains('mechanical') || c.contains('electrical') || c.contains('aerospace'))
      return '• Mathematics — Grade 7+ (required)\n• Physics — Grade 6+ (required)\n• Design & Technology — Grade 5+ (recommended)\n• English Language — Grade 5+ (required)';
    if (c.contains('architect') || c.contains('urban plan'))
      return '• Mathematics — Grade 6+ (required)\n• Art & Design — Grade 6+ (required)\n• Geography — Grade 5+ (recommended)\n• English Language — Grade 5+ (required)';
    if (c.contains('environ'))
      return '• Biology — Grade 6+ (required)\n• Geography — Grade 6+ (required)\n• Chemistry — Grade 5+ (recommended)\n• Mathematics — Grade 5+ (required)';
    if (c.contains('psycholog') || c.contains('social work'))
      return '• Mathematics — Grade 5+ (required)\n• English Language — Grade 5+ (required)\n• Biology — Grade 5+ (recommended)\n• Psychology or Sociology — Grade 4+ (recommended)';
    if (c.contains('teacher'))
      return '• Mathematics — Grade 5+ (required for QTS)\n• English Language — Grade 5+ (required for QTS)\n• Specialist subject — Grade 6+ (required)';
    if (c.contains('journal') || c.contains('media') || c.contains('radio'))
      return '• English Language — Grade 6+ (required)\n• Media Studies — Grade 5+ (recommended)\n• Drama — Grade 5+ (recommended)\n• English Literature — Grade 5+ (recommended)';
    if (c.contains('account') || c.contains('financial') || c.contains('actuar'))
      return '• Mathematics — Grade 6+ (required)\n• English Language — Grade 5+ (required)\n• Business Studies — Grade 5+ (recommended)';
    if (c.contains('photo') || c.contains('graphic') || c.contains('design'))
      return '• Art & Design — Grade 6+ (required)\n• Mathematics — Grade 5+ (required)\n• English Language — Grade 4+ (required)';
    if (c.contains('sound') || c.contains('actor') || c.contains('musician'))
      return '• Music — Grade 5+ (required)\n• Drama — Grade 5+ (recommended)\n• English Language — Grade 4+ (required)';
    return '• Mathematics — Grade 5+ (required)\n• English Language — Grade 5+ (required)\n• Relevant specialist subject — Grade 5+ (required)';
  }

  String _aLevelDesc(String career) {
    if (career.isEmpty) return 'Choose subjects aligned with your pathway. Apply via UCAS.';
    final c = career.toLowerCase();
    if (c.contains('nurs') || c.contains('midwi'))
      return 'Biology is highly recommended (B+ target). Chemistry or Psychology are strong second choices. Apply to nursing degree programmes via UCAS.';
    if (c.contains('physio'))
      return 'Take Biology and PE or Sport Science (B+ target). Apply to BSc Physiotherapy via UCAS — competitive with AAB typical offer.';
    if (c.contains('doctor') || c.contains('dentist'))
      return 'Biology and Chemistry are both required (A-A target). Third A-Level in Maths or Physics. Apply via UCAS with UKCAT/BMAT.';
    if (c.contains('software') || c.contains('cyber') || c.contains('ai'))
      return 'Maths is essential (B+ target). Computer Science and Physics are strong additions. Consider degree apprenticeships as an alternative route.';
    if (c.contains('law') || c.contains('solicit'))
      return 'Any 3 A-Levels at AAB. English, History, or Government & Politics are respected. Apply via UCAS for LLB Law.';
    if (c.contains('engineer'))
      return 'Maths and Physics are both essential (B+ target). Further Maths is an advantage. Apply via UCAS or degree apprenticeship.';
    if (c.contains('data') || c.contains('actuar'))
      return 'Maths (A target) is essential. Further Maths, Statistics, or Computer Science complement well.';
    if (c.contains('psycholog') || c.contains('social work') || c.contains('teacher'))
      return 'Psychology, Sociology, or Biology at B+ target. Any 3 strong A-Levels considered for most programmes.';
    return 'Choose 3 subjects relevant to your career pathway. Research specific university entry requirements on UCAS.';
  }

  String _uniDesc(String career) {
    if (career.isEmpty) return 'Start your degree or apprenticeship.';
    final c = career.toLowerCase();
    if (c.contains('nurs')) return 'Start BSc Nursing (3 years). Includes clinical placements in NHS settings.';
    if (c.contains('physio')) return 'Start BSc Physiotherapy (3 years). Includes practice placements across NHS and private settings.';
    if (c.contains('doctor')) return 'Start Medicine (5-6 years). Includes clinical rotations from Year 3.';
    if (c.contains('dentist')) return 'Start BDS Dentistry (5 years). Includes clinical dental training.';
    if (c.contains('software') || c.contains('cyber') || c.contains('ai'))
      return 'Start BSc Computer Science or Degree Apprenticeship (3-4 years). Build real projects from day one.';
    if (c.contains('law') || c.contains('solicit'))
      return 'Start LLB Law (3 years), then LPC (1 year) or SQE training. Training contract follows.';
    if (c.contains('engineer'))
      return 'Start MEng Engineering (4 years) or Degree Apprenticeship. Gain professional experience through placements.';
    return 'Begin your undergraduate degree or degree apprenticeship. Build practical skills and professional network.';
  }
}

class _TimelineItem extends StatelessWidget {
  final Color color; final String emoji, year, title, desc; final bool done;
  const _TimelineItem({required this.color, required this.emoji,
    required this.year, required this.title, required this.desc, required this.done});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withOpacity(0.15),
          shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16)))),
      Container(width: 2, height: 60, color: color.withOpacity(0.2)),
    ]),
    const SizedBox(width: 14),
    Expanded(child: Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(year, style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
            fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
          if (done) ...[
            const SizedBox(width: 8),
            const TagBadge(label: '✓ On track',
              bg: Color(0xFFECFDF5), fg: Color(0xFF065F46)),
          ],
        ]),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(desc.replaceAll('\\n', '\n'), style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 12, color: AppColors.textMid, height: 1.7)),
      ]),
    )),
  ]);
}

class _QualificationBrowser extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FullQualBrowser();
  }
}

class _FullQualBrowser extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FullQualBrowser> createState() => _FullQualBrowserState();
}

class _FullQualBrowserState extends ConsumerState<_FullQualBrowser> {
  String _type = 'GCSE';
  List<Map<String, dynamic>>? _preclasses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await Supabase.instance.client
        .from('preclass').select().order('type').order('title');
    if (mounted) setState(() => _preclasses = (res as List).cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    final types = ['GCSE', 'A-Level', 'BTEC', 'T-Level'];
    final typeEmojis = {'GCSE': '📗', 'A-Level': '📘', 'BTEC': '📙', 'T-Level': '📕'};
    final filtered = _preclasses?.where((p) => p['type'] == _type).toList() ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: types.map((t) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _type = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _type == t ? AppColors.primary : AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _type == t ? AppColors.primary : AppColors.border)),
              child: Text('${typeEmojis[t]} $t', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                color: _type == t ? Colors.white : AppColors.textMid)),
            ),
          ),
        )).toList()),
      ),
      const SizedBox(height: 12),
      if (_preclasses == null)
        const Center(child: CircularProgressIndicator())
      else
        ...filtered.map((p) => _PreclassTile(p)),
    ]);
  }
}

class _PreclassTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> preclass;
  const _PreclassTile(this.preclass);
  @override
  ConsumerState<_PreclassTile> createState() => _PreclassTileState();
}

class _PreclassTileState extends ConsumerState<_PreclassTile> {
  bool _expanded = false;
  List<Map<String, dynamic>>? _linkedCourses;

  Future<void> _loadCourses() async {
    if (_linkedCourses != null) return;
    final res = await Supabase.instance.client
        .from('preclass_course')
        .select('to_course, courses(id, title, institutions(name))')
        .eq('from_preclass', widget.preclass['id']);
    // Deduplicate courses
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final e in (res as List)) {
      final course = e['courses'] as Map<String, dynamic>;
      final id = course['id'] as String;
      if (!seen.contains(id)) {
        seen.add(id);
        unique.add(course);
      }
    }
    if (mounted) setState(() => _linkedCourses = unique);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EduCard(
        onTap: () async {
          setState(() => _expanded = !_expanded);
          if (_expanded) await _loadCourses();
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.preclass['title'] ?? '',
              style: const TextStyle(fontFamily: 'Nunito',
                fontSize: 13, fontWeight: FontWeight.w700))),
            TagBadge(label: widget.preclass['level'] ?? '',
              bg: AppColors.primaryPale, fg: AppColors.primaryDark),
            const SizedBox(width: 6),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more,
              size: 18, color: AppColors.textLight),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 10),
            const Text('Leads to these courses:',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                color: AppColors.textMid, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (_linkedCourses == null)
              const Center(child: CircularProgressIndicator())
            else if (_linkedCourses!.isEmpty)
              const Text('No direct course links yet.',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                  color: AppColors.textLight))
            else ..._linkedCourses!.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => context.push('/course/${c['id']}'),
                child: Row(children: [
                  const Text('→ ', style: TextStyle(color: AppColors.primary,
                    fontSize: 12, fontWeight: FontWeight.w700)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(c['title'] ?? '', style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 12,
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
                    if (c['institutions'] != null)
                      Text((c['institutions'] as Map)['name'] ?? '',
                        style: const TextStyle(fontFamily: 'Nunito',
                          fontSize: 11, color: AppColors.textMid)),
                  ])),
                ]),
              ),
            )),
          ],
        ]),
      ),
    );
  }
}

class RoadmapPlanScreen extends StatelessWidget {
  const RoadmapPlanScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPage,
    appBar: AppBar(
      title: const Text('My Learning Roadmap'),
      leading: GestureDetector(onTap: () => context.pop(), child: const BackBtn()),
      actions: [IconButton(
        icon: const Icon(Icons.home_rounded),
        tooltip: 'Dashboard',
        onPressed: () => context.go('/home'))]),
    body: const Center(child: Text('Roadmap editor coming soon! 🚀',
      style: TextStyle(fontFamily: 'Nunito', fontSize: 16))));
}
