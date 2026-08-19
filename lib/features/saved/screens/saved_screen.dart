// lib/features/saved/screens/saved_screen.dart
// Issue 4: removed 'pathway' filter chip and pathway item_type
// Only shows careers and courses

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedItemsProvider);
    final filter = ref.watch(savedFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text('Saved 🔖', style: Theme.of(context).textTheme.displayMedium)),

        // Filter chips — Issue 4: removed 'pathway'
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (final f in ['all', 'career', 'course'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ref.read(savedFilterProvider.notifier).state = f,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: filter == f ? AppColors.primary : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: filter == f ? AppColors.primary : AppColors.border)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (f == 'career') const Text('💼 ', style: TextStyle(fontSize: 13))
                      else if (f == 'course') const Text('🎓 ', style: TextStyle(fontSize: 13)),
                      Text(
                        f == 'all' ? 'All' : f == 'career' ? 'Careers' : 'Courses',
                        style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: filter == f ? Colors.white : AppColors.textMid)),
                    ]),
                  ))),
          ])),

        const SizedBox(height: 12),

        Expanded(child: savedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (items) {
            // Issue 4: filter out pathway type entirely
            final nonPathway = items.where((i) => i.itemType != 'pathway').toList();
            final filtered = filter == 'all'
                ? nonPathway
                : nonPathway.where((i) => i.itemType == filter).toList();

            if (filtered.isEmpty) {
              return EmptyState(
                emoji: filter == 'career' ? '💼' : filter == 'course' ? '🎓' : '🔖',
                title: 'Nothing saved yet',
                subtitle: filter == 'career'
                    ? 'Save careers you\'re interested in'
                    : filter == 'course'
                        ? 'Save courses to compare later'
                        : 'Save careers and courses to find them here',
                actionLabel: 'Explore Careers',
                onAction: () => context.go(AppConstants.routeExplore));
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = filtered[i];
                final isCareer = item.itemType == 'career';
                final color = isCareer ? AppColors.primary : AppColors.accentBlue;

                return EduCard(
                  onTap: isCareer
                      ? () => context.push('/pathway/${item.itemId}')
                      : () => context.push('/course/${item.itemId}'),
                  child: Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(
                        isCareer ? '💼' : '🎓',
                        style: const TextStyle(fontSize: 22)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.itemTitle ?? 'Saved item',
                            style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        Text(item.itemSubtitle ?? (isCareer ? 'Career' : 'Course'),
                            style: const TextStyle(
                                fontFamily: 'Nunito', fontSize: 12,
                                color: AppColors.textMid)),
                      ])),
                    GestureDetector(
                      onTap: () async {
                        await DbService.unsaveItem(item.itemId);
                        ref.invalidate(savedItemsProvider);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.favorite_rounded,
                            color: Colors.red, size: 18))),
                  ]));
              });
          },
        )),
      ])),
    );
  }
}
