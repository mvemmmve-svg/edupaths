// lib/features/explore/screens/explore_screen.dart
// Issue 2 fix: careers sorted alphabetically within each category
// Issue 3 fix: courses tab split into University / Apprenticeship sub-tabs

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
    final query = ref.watch(searchQueryProvider);
    final selectedCourseCat = ref.watch(_selectedCategoryProvider);
    final selectedCareerCat = ref.watch(_selectedCareerCatProvider);
    final courseType = ref.watch(_courseTypeProvider);

    final allCourseCats = coursesAsync.valueOrNull != null
        ? (coursesAsync.value!.map((c) => c.category ?? 'Other').toSet().toList()..sort())
        : <String>[];

    // Issue 2: career categories sorted, careers within each sorted alphabetically
    final allCareerCats = careersAsync.valueOrNull != null
        ? (careersAsync.value!.map((c) => c.category ?? 'Other').toSet().toList()..sort())
        : <String>[];

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

    final groupedCourses = <String, List<Course>>{};
    for (final c in filteredCourses) {
      groupedCourses.putIfAbsent(c.category ?? 'Other', () => []).add(c);
    }
    // Sort courses within each category alphabetically
    for (final key in groupedCourses.keys) {
      groupedCourses[key]!.sort((a, b) => a.trimmed.compareTo(b.trimmed));
    }

    final filteredCareers = careersAsync.valueOrNull?.where((c) {
      final matchCat = selectedCareerCat == null || c.category == selectedCareerCat;
      final matchQ = query.isEmpty ||
          c.displayName.toLowerCase().contains(query.toLowerCase());
      return matchCat && matchQ;
    }).toList() ?? [];

    // Issue 2: sort careers alphabetically within each category
    final groupedCareers = <String, List<Career>>{};
    for (final c in filteredCareers) {
      groupedCareers.putIfAbsent(c.category ?? 'Other', () => []).add(c);
    }
    for (final key in groupedCareers.keys) {
      groupedCareers[key]!.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
    // Sort category keys alphabetically too
    final sortedCareerCats = groupedCareers.keys.toList()..sort();
    final sortedCourseCats = groupedCourses.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Explore 🔍', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            const Text('Search careers, courses and more...',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
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
          tabs: const [Tab(text: 'Careers'), Tab(text: 'Courses')],
        ),

        Expanded(child: TabBarView(controller: _tabs, children: [

          // ── CAREERS TAB ──────────────────────────────────────────────────
          Column(children: [
            if (allCareerCats.isNotEmpty)
              SizedBox(height: 52,
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
                      itemCount: sortedCareerCats.length,
                      itemBuilder: (_, i) {
                        final cat = sortedCareerCats[i];
                        final items = groupedCareers[cat]!;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(cat, style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14,
                                fontWeight: FontWeight.w900, color: AppColors.textDark))),
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
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                              ]),
                            ))),
                        ]);
                      }),
            )),
          ]),

          // ── COURSES TAB — Issue 3: University / Apprenticeship tabs ──────
          Column(children: [
            // Type tabs — University | Apprenticeship | All
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(children: [
                for (final t in ['All', 'University', 'Apprenticeship'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
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
                          if (t == 'University')
                            const Text('🎓 ', style: TextStyle(fontSize: 12))
                          else if (t == 'Apprenticeship')
                            const Text('🔧 ', style: TextStyle(fontSize: 12)),
                          Text(t, style: TextStyle(
                              fontFamily: 'Nunito', fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: courseType == t ? Colors.white : AppColors.textMid)),
                        ]),
                      ),
                    )),
              ]),
            ),

            // Category chips
            if (allCourseCats.isNotEmpty)
              SizedBox(height: 46,
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

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Text('${filteredCourses.length} course${filteredCourses.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 12, color: AppColors.textLight)),
              ]),
            ),

            Expanded(child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (_) => groupedCourses.isEmpty
                  ? EmptyState(
                      emoji: courseType == 'University' ? '🎓' : courseType == 'Apprenticeship' ? '🔧' : '📚',
                      title: 'No ${courseType == 'All' ? '' : courseType.toLowerCase() + ' '}courses found',
                      subtitle: 'Try a different filter or search')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: sortedCourseCats.length,
                      itemBuilder: (_, i) {
                        final cat = sortedCourseCats[i];
                        final courses = groupedCourses[cat]!;
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(cat, style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14,
                                fontWeight: FontWeight.w800, color: AppColors.textDark))),
                          ...courses.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EduCard(
                              onTap: () => context.push('/course/${c.id}'),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  // Issue 3: clear University vs Apprenticeship badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.isApprenticeship
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      c.isApprenticeship ? '🔧 Apprenticeship' : '🎓 University',
                                      style: TextStyle(
                                          fontFamily: 'Nunito', fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: c.isApprenticeship
                                              ? const Color(0xFF1D4ED8)
                                              : const Color(0xFF6C63FF)))),
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
