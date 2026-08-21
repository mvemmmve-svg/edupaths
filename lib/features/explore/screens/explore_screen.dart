// lib/features/explore/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);
final _selectedCareerCatProvider = StateProvider<String?>((ref) => null);
final _courseTypeProvider = StateProvider<String>((ref) => 'All');
final _qualTypeProvider = StateProvider<String>((ref) => 'All');
// FIXED #9: location filter provider
final _locationProvider = StateProvider<String?>((ref) => null);

final _qualsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await Supabase.instance.client
      .from('preclass')
      .select('id, title, type, level')
      .order('type')
      .order('title');
  return List<Map<String, dynamic>>.from(res as List);
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchCtrl.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final careersAsync = ref.watch(filteredCareersProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final qualsAsync = ref.watch(_qualsProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedCourseCat = ref.watch(_selectedCategoryProvider);
    final selectedCareerCat = ref.watch(_selectedCareerCatProvider);
    final courseType = ref.watch(_courseTypeProvider);
    final qualType = ref.watch(_qualTypeProvider);
    final selectedLocation = ref.watch(_locationProvider); // FIXED #9

    final allCourseCats = coursesAsync.valueOrNull != null
        ? (coursesAsync.value!.map((c) => c.category ?? 'Other').toSet().toList()..sort())
        : <String>[];

    final allCareerCats = careersAsync.valueOrNull != null
        ? (careersAsync.value!.map((c) => c.category ?? 'Other').toSet().toList()..sort())
        : <String>[];

    // FIXED #9: collect unique locations from courses (excluding null/empty)
    final allLocations = coursesAsync.valueOrNull != null
        ? (coursesAsync.value!
            .map((c) => c.location)
            .where((l) => l != null && l.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()..sort())
        : <String>[];

    // Filter courses — now includes location filter
    final filteredCourses = coursesAsync.valueOrNull?.where((c) {
      final matchCat = selectedCourseCat == null || c.category == selectedCourseCat;
      final matchType = courseType == 'All' ||
          (courseType == 'Apprenticeship' && c.isApprenticeship) ||
          (courseType == 'University' && !c.isApprenticeship);
      final matchQ = query.isEmpty ||
          c.trimmed.toLowerCase().contains(query.toLowerCase()) ||
          (c.institution?.trimmed.toLowerCase().contains(query.toLowerCase()) ?? false);
      // FIXED #9: location filter
      final matchLocation = selectedLocation == null ||
          (c.location?.toLowerCase().contains(selectedLocation.toLowerCase()) ?? false);
      return matchCat && matchType && matchQ && matchLocation;
    }).toList() ?? [];

    final groupedCourses = <String, List<Course>>{};
    for (final c in filteredCourses) {
      groupedCourses.putIfAbsent(c.category ?? 'Other', () => []).add(c);
    }
    for (final key in groupedCourses.keys) {
      groupedCourses[key]!.sort((a, b) => a.trimmed.compareTo(b.trimmed));
    }
    final sortedCourseCats = groupedCourses.keys.toList()..sort();

    // Filter careers
    final filteredCareers = careersAsync.valueOrNull?.where((c) {
      final matchCat = selectedCareerCat == null || c.category == selectedCareerCat;
      final matchQ = query.isEmpty ||
          c.displayName.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList() ?? [];

    final groupedCareers = <String, List<Career>>{};
    for (final c in filteredCareers) {
      groupedCareers.putIfAbsent(c.category ?? 'Other', () => []).add(c);
    }
    for (final key in groupedCareers.keys) {
      groupedCareers[key]!.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
    final sortedCareerCats = groupedCareers.keys.toList()..sort();

    // Filter qualifications
    final allQuals = qualsAsync.valueOrNull ?? [];
    const qualTypes = ['GCSE', 'A-Level', 'BTEC', 'T-Level'];
    final filteredQuals = allQuals.where((q) {
      final matchType = qualType == 'All' || q['type'] == qualType;
      final matchQ = query.isEmpty ||
          (q['title'] as String).toLowerCase().contains(query.toLowerCase());
      return matchType && matchQ;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Explore 🔍', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('Search careers, courses and qualifications...',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: AppColors.textMid)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search anything...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                        child: const Icon(Icons.clear_rounded, size: 20))
                    : null),
            ),
          ]),
        ),

        TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'Careers'),
            Tab(text: 'Courses'),
            Tab(text: 'Qualifications'),
          ],
        ),

        Expanded(child: TabBarView(controller: _tabs, children: [

          // ── CAREERS TAB ───────────────────────────────────────────────
          Column(children: [
            if (allCareerCats.isNotEmpty)
              SizedBox(height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allCareerCats.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == 0) return _CatChip(label: 'All',
                        selected: selectedCareerCat == null,
                        onTap: () => ref.read(_selectedCareerCatProvider.notifier).state = null);
                    final cat = allCareerCats[i - 1];
                    final sel = selectedCareerCat == cat;
                    return _CatChip(label: cat, selected: sel,
                        onTap: () => ref.read(_selectedCareerCatProvider.notifier).state =
                            sel ? null : cat);
                  },
                )),
            Expanded(child: careersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (_) => groupedCareers.isEmpty
                  ? const EmptyState(emoji: '💼', title: 'No careers found',
                      subtitle: 'Try a different search or category')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: sortedCareerCats.length,
                      itemBuilder: (_, i) {
                        final cat = sortedCareerCats[i];
                        final items = groupedCareers[cat]!;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(cat, style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14,
                                fontWeight: FontWeight.w900, color: AppColors.textDark))),
                          ...items.map((career) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EduCard(
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
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textLight),
                              ]),
                            ))),
                        ]);
                      }),
            )),
          ]),

          // ── COURSES TAB — FIXED #9: location filter added ─────────────
          Column(children: [
            // Type filter row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(children: [
                for (final t in ['All', 'University', 'Apprenticeship'])
                  Padding(padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref.read(_courseTypeProvider.notifier).state = t,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: courseType == t ? AppColors.primary : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: courseType == t ? AppColors.primary : AppColors.border)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (t == 'University') const Text('🎓 ', style: TextStyle(fontSize: 12))
                          else if (t == 'Apprenticeship') const Text('🔧 ', style: TextStyle(fontSize: 12)),
                          Text(t, style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: courseType == t ? Colors.white : AppColors.textMid)),
                        ]),
                      ),
                    )),
              ]),
            ),

            // FIXED #9: Location filter row
            if (allLocations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: allLocations.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return GestureDetector(
                              onTap: () =>
                                  ref.read(_locationProvider.notifier).state = null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedLocation == null
                                      ? AppColors.primary : AppColors.bgCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: selectedLocation == null
                                          ? AppColors.primary : AppColors.border)),
                                child: Text('Anywhere',
                                    style: TextStyle(
                                        fontFamily: 'Nunito', fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: selectedLocation == null
                                            ? Colors.white : AppColors.textMid)),
                              ));
                          }
                          final loc = allLocations[i - 1];
                          final sel = selectedLocation == loc;
                          return GestureDetector(
                            onTap: () => ref.read(_locationProvider.notifier).state =
                                sel ? null : loc,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.bgCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: sel ? AppColors.primary : AppColors.border)),
                              child: Text(loc,
                                  style: TextStyle(
                                      fontFamily: 'Nunito', fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : AppColors.textMid)),
                            ));
                        },
                      ),
                    ),
                  ),
                ]),
              ),

            // Category filter
            if (allCourseCats.isNotEmpty)
              SizedBox(height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: allCourseCats.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == 0) return _CatChip(label: 'All',
                        selected: selectedCourseCat == null,
                        onTap: () =>
                            ref.read(_selectedCategoryProvider.notifier).state = null);
                    final cat = allCourseCats[i - 1];
                    final sel = selectedCourseCat == cat;
                    return _CatChip(label: cat, selected: sel,
                        onTap: () => ref
                            .read(_selectedCategoryProvider.notifier)
                            .state = sel ? null : cat);
                  },
                )),

            // Count + active location indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Text('${filteredCourses.length} course${filteredCourses.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                        color: AppColors.textLight)),
                if (selectedLocation != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        ref.read(_locationProvider.notifier).state = null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('📍 $selectedLocation',
                            style: const TextStyle(fontFamily: 'Nunito',
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                        const SizedBox(width: 4),
                        const Icon(Icons.close, size: 12, color: AppColors.primaryDark),
                      ]),
                    )),
                ],
              ]),
            ),

            Expanded(child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (_) => groupedCourses.isEmpty
                  ? EmptyState(
                      emoji: courseType == 'University'
                          ? '🎓' : courseType == 'Apprenticeship' ? '🔧' : '📚',
                      title: selectedLocation != null
                          ? 'No courses in $selectedLocation'
                          : 'No courses found',
                      subtitle: selectedLocation != null
                          ? 'Try a different location or remove the filter'
                          : 'Try a different filter or search')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: sortedCourseCats.length,
                      itemBuilder: (_, i) {
                        final cat = sortedCourseCats[i];
                        final courses = groupedCourses[cat]!;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(cat, style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14,
                                fontWeight: FontWeight.w800, color: AppColors.textDark))),
                          ...courses.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EduCard(
                              onTap: () => context.push('/course/${c.id}'),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.isApprenticeship
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      c.isApprenticeship
                                          ? '🔧 Apprenticeship' : '🎓 University',
                                      style: TextStyle(fontFamily: 'Nunito', fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: c.isApprenticeship
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF6C63FF)))),
                                  // FIXED #9: show location badge if present
                                  if (c.location != null && c.location!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgGrey,
                                        borderRadius: BorderRadius.circular(6)),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 10, color: AppColors.textLight),
                                        const SizedBox(width: 2),
                                        Text(c.location!,
                                            style: const TextStyle(
                                                fontFamily: 'Nunito', fontSize: 10,
                                                color: AppColors.textMid)),
                                      ])),
                                  ],
                                ]),
                                const SizedBox(height: 6),
                                Text(c.trimmed, style: const TextStyle(
                                    fontFamily: 'Nunito', fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                                if (c.institution != null) ...[
                                  const SizedBox(height: 3),
                                  Text(c.institution!.trimmed, style: const TextStyle(
                                      fontFamily: 'Nunito', fontSize: 12,
                                      color: AppColors.textMid)),
                                ],
                                if (c.duration != null) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.schedule_outlined,
                                        size: 12, color: AppColors.textLight),
                                    const SizedBox(width: 4),
                                    Text(c.duration!, style: const TextStyle(
                                        fontFamily: 'Nunito', fontSize: 11,
                                        color: AppColors.textMid)),
                                  ]),
                                ],
                              ]),
                            ))),
                        ]);
                      }),
            )),
          ]),

          // ── QUALIFICATIONS TAB ────────────────────────────────────────
          Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final t in ['All', ...qualTypes])
                    Padding(padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref.read(_qualTypeProvider.notifier).state = t,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: qualType == t ? _qualColor(t) : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: qualType == t ? _qualColor(t) : AppColors.border)),
                          child: Text(t, style: TextStyle(fontFamily: 'Nunito',
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: qualType == t ? Colors.white : AppColors.textMid)),
                        ),
                      )),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Text('💡', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Tap any qualification to see which courses it leads to.',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                        color: AppColors.primaryDark, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
            Expanded(child: qualsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (_) {
                if (filteredQuals.isEmpty) {
                  return const EmptyState(emoji: '📚',
                      title: 'No qualifications found',
                      subtitle: 'Try adjusting your filters or search');
                }
                final grouped = <String, List<Map<String, dynamic>>>{};
                for (final q in filteredQuals) {
                  grouped.putIfAbsent(q['type'] as String, () => []).add(q);
                }
                final types = grouped.keys.toList()
                  ..sort((a, b) =>
                      qualTypes.indexOf(a).compareTo(qualTypes.indexOf(b)));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: types.length,
                  itemBuilder: (_, i) {
                    final type = types[i];
                    final quals = grouped[type]!;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Row(children: [
                          Text(_qualEmoji(type), style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(type, style: TextStyle(fontFamily: 'Nunito',
                              fontSize: 15, fontWeight: FontWeight.w900,
                              color: _qualColor(type))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _qualColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                            child: Text('${quals.length}', style: TextStyle(
                                fontFamily: 'Nunito', fontSize: 11,
                                fontWeight: FontWeight.w700, color: _qualColor(type)))),
                        ])),
                      ...quals.map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: EduCard(
                          onTap: () => _showQualDetail(context, q),
                          child: Row(children: [
                            Container(width: 6, height: 40,
                              decoration: BoxDecoration(
                                color: _qualColor(type),
                                borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(q['title'] as String, style: const TextStyle(
                                  fontFamily: 'Nunito', fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                              if ((q['level'] as String?)?.isNotEmpty == true)
                                Text('Level ${q['level']}', style: const TextStyle(
                                    fontFamily: 'Nunito', fontSize: 11,
                                    color: AppColors.textMid)),
                            ])),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textLight),
                          ]),
                        ))),
                    ]);
                  });
              },
            )),
          ]),
        ])),
      ])),
    );
  }

  Color _qualColor(String type) {
    switch (type) {
      case 'GCSE': return const Color(0xFF0891B2);
      case 'A-Level': return const Color(0xFF4F46E5);
      case 'BTEC': return const Color(0xFF059669);
      case 'T-Level': return const Color(0xFFD97706);
      default: return AppColors.primary;
    }
  }

  String _qualEmoji(String type) {
    switch (type) {
      case 'GCSE': return '📚';
      case 'A-Level': return '✏️';
      case 'BTEC': return '📋';
      case 'T-Level': return '🔧';
      default: return '📄';
    }
  }

  void _showQualDetail(BuildContext context, Map<String, dynamic> qual) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QualDetailSheet(
          qualId: qual['id'] as String,
          qualTitle: qual['title'] as String,
          qualType: qual['type'] as String));
  }
}

// ── Qualification detail sheet ────────────────────────────────────────────────

class _QualDetailSheet extends StatefulWidget {
  final String qualId, qualTitle, qualType;
  const _QualDetailSheet({
      required this.qualId, required this.qualTitle, required this.qualType});
  @override
  State<_QualDetailSheet> createState() => _QualDetailSheetState();
}

class _QualDetailSheetState extends State<_QualDetailSheet> {
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadCourses(); }

  Future<void> _loadCourses() async {
    try {
      final links = await Supabase.instance.client
          .from('preclass_course')
          .select('to_course')
          .eq('from_preclass', widget.qualId);
      final ids = (links as List).map((e) => e['to_course'] as String).toList();
      if (ids.isEmpty) { setState(() => _loading = false); return; }
      final courses = await Supabase.instance.client
          .from('courses')
          .select('id, title, course_type, category, duration, location')
          .in_('id', ids)
          .order('title');
      setState(() {
        _courses = List<Map<String, dynamic>>.from(courses as List);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (widget.qualType) {
      case 'GCSE': color = const Color(0xFF0891B2); break;
      case 'A-Level': color = const Color(0xFF4F46E5); break;
      case 'BTEC': color = const Color(0xFF059669); break;
      case 'T-Level': color = const Color(0xFFD97706); break;
      default: color = AppColors.primary;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(widget.qualType, style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 12,
                    fontWeight: FontWeight.w700, color: color))),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.qualTitle,
                style: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 17, fontWeight: FontWeight.w900))),
            ])),
          const Divider(height: 1),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _courses.isEmpty
                  ? const Center(child: EmptyState(emoji: '🎓',
                      title: 'No linked courses yet',
                      subtitle: 'Courses that accept this qualification will appear here'))
                  : ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _courses.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Courses that accept ${widget.qualTitle}:',
                            style: const TextStyle(fontFamily: 'Nunito',
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: AppColors.textMid)));
                        final c = _courses[i - 1];
                        final isApp = (c['course_type'] as String?) == 'Apprenticeship';
                        final loc = c['location'] as String?;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: EduCard(
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/course/${c['id']}');
                            },
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isApp
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(6)),
                                child: Text(isApp ? '🔧' : '🎓',
                                    style: const TextStyle(fontSize: 12))),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c['title'] as String, style: const TextStyle(
                                    fontFamily: 'Nunito', fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                                if (c['duration'] != null)
                                  Text(c['duration'] as String, style: const TextStyle(
                                      fontFamily: 'Nunito', fontSize: 11,
                                      color: AppColors.textMid)),
                                // Location shown in qual detail too
                                if (loc != null && loc.isNotEmpty)
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 11, color: AppColors.textLight),
                                    const SizedBox(width: 2),
                                    Text(loc, style: const TextStyle(
                                        fontFamily: 'Nunito', fontSize: 11,
                                        color: AppColors.textMid)),
                                  ]),
                              ])),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textLight, size: 18),
                            ]),
                          ));
                      })),
        ]),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 0 : 1.5)),
      child: Text(label, style: TextStyle(fontFamily: 'Nunito',
          fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textMid)),
    ),
  );
}
