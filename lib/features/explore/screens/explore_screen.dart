// lib/features/explore/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);
final _selectedCareerCatProvider = StateProvider<String?>((ref) => null);
final _courseTypeProvider = StateProvider<String>((ref) => 'All');

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
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Explore is FREE to browse — search, career summaries and course
    // listings hook users in. Premium gates the deeper features instead:
    // route comparison, unlimited saves, detailed roadmaps.
    final careersAsync = ref.watch(filteredCareersProvider);
    final coursesAsync = ref.watch(coursesProvider);
    final query = ref.watch(searchQueryProvider);
    final selectedCourseCat = ref.watch(_selectedCategoryProvider);
    final selectedCareerCat = ref.watch(_selectedCareerCatProvider);
    final courseType = ref.watch(_courseTypeProvider);

    // Course categories
    final allCourseCats = coursesAsync.valueOrNull != null
        ? (coursesAsync.value!.map((c) => c.category ?? 'Other').toSet().toList()..sort())
        : <String>[];

    // Career categories
    final allCareerCats = careersAsync.valueOrNull != null
        ? (careersAsync.value!.map((c) => c.category ?? 'Other').toSet().toList()..sort())
        : <String>[];

    // Filter courses
    final filteredCourses = coursesAsync.valueOrNull?.where((c) {
      final matchCat = selectedCourseCat == null || c.category == selectedCourseCat;
      final matchType = courseType == 'All' ||
          (courseType == 'Apprenticeship' && c.isApprenticeship) ||
          (courseType == 'University' && !c.isApprenticeship);
      final matchQ = query.isEmpty ||
          c.trimmed.toLowerCase().contains(query.toLowerCase()) ||
          (c.institution?.trimmed.toLowerCase().contains(query.toLowerCase()) ?? false);
      return matchCat && matchType && matchQ;
    }).toList() ?? [];

    // Group courses
    final groupedCourses = <String, List<Course>>{};
    for (final c in filteredCourses) {
      groupedCourses.putIfAbsent(c.category ?? 'Other', () => []).add(c);
    }

    // Filter careers
    final filteredCareers = careersAsync.valueOrNull?.where((c) {
      final matchCat = selectedCareerCat == null || c.category == selectedCareerCat;
      final matchQ = query.isEmpty ||
          c.displayName.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList() ?? [];

    // Group careers
    final groupedCareers = <String, List<Career>>{};
    for (final c in filteredCareers) {
      groupedCareers.putIfAbsent(c.category ?? 'Other', () => []).add(c);
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Column(children: [
        // Header + Search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Explore 🔍', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('Search careers, courses and more...',
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

        // Tabs
        TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontFamily: 'Nunito',
            fontSize: 13, fontWeight: FontWeight.w800),
          tabs: const [Tab(text: 'Careers'), Tab(text: 'Courses')],
        ),

        Expanded(child: TabBarView(controller: _tabs, children: [

          // ── CAREERS TAB ──────────────────────────────
          Column(children: [
            if (allCareerCats.isNotEmpty) SizedBox(height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: allCareerCats.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _CatChip(label: 'All',
                      selected: selectedCareerCat == null,
                      onTap: () => ref.read(_selectedCareerCatProvider.notifier).state = null);
                  }
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
                      itemCount: groupedCareers.length,
                      itemBuilder: (_, i) {
                        final cat = groupedCareers.keys.elementAt(i);
                        final items = groupedCareers[cat]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(cat, style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark))),
                          ...items.map((career) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EduCard(
                              onTap: () => context.push('/pathway/${career.id}'),
                              child: Row(children: [
                                Container(width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPale,
                                    borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.work_outline_rounded,
                                    color: AppColors.primary, size: 22)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                      },
                    ),
            )),
          ]),

          // ── COURSES TAB ──────────────────────────────
          Column(children: [
            // Course type toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: ['All', 'University', 'Apprenticeship'].map((t) =>
                Padding(padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ref.read(_courseTypeProvider.notifier).state = t,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: courseType == t ? AppColors.primary : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: courseType == t ? AppColors.primary : AppColors.border)),
                      child: Text(t, style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                        color: courseType == t ? Colors.white : AppColors.textMid)),
                    ),
                  ))).toList()),
            ),
            // Category chips
            if (allCourseCats.isNotEmpty) SizedBox(height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: allCourseCats.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _CatChip(label: 'All',
                      selected: selectedCourseCat == null,
                      onTap: () => ref.read(_selectedCategoryProvider.notifier).state = null);
                  }
                  final cat = allCourseCats[i - 1];
                  final sel = selectedCourseCat == cat;
                  return _CatChip(label: cat, selected: sel,
                    onTap: () => ref.read(_selectedCategoryProvider.notifier).state =
                        sel ? null : cat);
                },
              )),
            Expanded(child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (_) => groupedCourses.isEmpty
                  ? const EmptyState(emoji: '🎓', title: 'No courses found',
                      subtitle: 'Try a different search or category')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: groupedCourses.length,
                      itemBuilder: (_, i) {
                        final cat = groupedCourses.keys.elementAt(i);
                        final courses = groupedCourses[cat]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(cat, style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark))),
                          ...courses.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EduCard(
                              onTap: () => context.push('/course/${c.id}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Row(children: [
                                  Expanded(child: Text(c.trimmed,
                                    style: const TextStyle(fontFamily: 'Nunito',
                                      fontSize: 13, fontWeight: FontWeight.w800))),
                                  TagBadge(label: c.isApprenticeship
                                      ? '🔨 Apprenticeship' : '🎓 University'),
                                ]),
                                if (c.institution != null) ...[
                                  const SizedBox(height: 3),
                                  Text(c.institution!.trimmed,
                                    style: const TextStyle(fontFamily: 'Nunito',
                                      fontSize: 12, color: AppColors.textMid)),
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
                      },
                    ),
            )),
          ]),
        ])),
      ])),
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
      child: Text(label, style: TextStyle(
        fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.textMid)),
    ),
  );
}
