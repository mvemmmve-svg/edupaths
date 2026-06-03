// lib/features/saved/screens/saved_screen.dart
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
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (final f in ['all', 'career', 'course', 'pathway'])
              Padding(padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ref.read(savedFilterProvider.notifier).state = f,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: filter == f ? AppColors.primary : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: filter == f ? AppColors.primary : AppColors.border)),
                    child: Text(
                      f[0].toUpperCase() + f.substring(1) + (f == 'all' ? '' : 's'),
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: filter == f ? Colors.white : AppColors.textMid)),
                  ))),
          ])),
        const SizedBox(height: 12),
        Expanded(child: savedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (items) {
            final filtered = filter == 'all' ? items
                : items.where((i) => i.itemType == filter).toList();
            if (filtered.isEmpty) return EmptyState(
              emoji: '🔖', title: 'Nothing saved yet',
              subtitle: 'Save careers and courses to find them here',
              actionLabel: 'Explore Careers',
              onAction: () => context.go(AppConstants.routeExplore));
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final item = filtered[i];
                return EduCard(
                  onTap: item.itemType == 'career'
                      ? () => context.push('/pathway/${item.itemId}')
                      : item.itemType == 'course'
                          ? () => context.push('/course/${item.itemId}')
                          : null,
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _typeColor(item.itemType).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(_typeEmoji(item.itemType),
                        style: const TextStyle(fontSize: 22)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(item.itemTitle ?? 'Saved item', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800)),
                      Text(item.itemSubtitle ?? item.itemType, style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
                    ])),
                    GestureDetector(
                      onTap: () async {
                        await DbService.unsaveItem(item.itemId);
                        ref.invalidate(savedItemsProvider);
                      },
                      child: Container(padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2),
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

  Color _typeColor(String type) {
    switch (type) {
      case 'career': return AppColors.primary;
      case 'course': return AppColors.accentBlue;
      default: return AppColors.accentGreen;
    }
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'career': return '💼';
      case 'course': return '🎓';
      default: return '🗺️';
    }
  }
}
