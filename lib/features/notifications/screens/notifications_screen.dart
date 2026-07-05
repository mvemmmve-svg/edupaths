// lib/features/notifications/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _notifCategoryProvider = StateProvider<String>((ref) => 'All');
final _notifBoardProvider = StateProvider<String>((ref) => 'All');

final _notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await Supabase.instance.client
      .from('notifications')
      .select()
      .order('event_date', ascending: true);
  return (res as List).cast<Map<String, dynamic>>();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(_notificationsProvider);
    final category = ref.watch(_notifCategoryProvider);
    final board = ref.watch(_notifBoardProvider);

    final now = DateTime.now();
    final categories = ['All', 'GCSE', 'UCAS', 'Apprenticeship', 'Roadmap'];
    final boards = ['All', 'AQA', 'OCR', 'Edexcel'];

    final catEmojis = {
      'All': '🔔', 'GCSE': '📝', 'UCAS': '🎓',
      'Apprenticeship': '🔨', 'Roadmap': '🗺️'
    };
    final catColors = {
      'gcse': AppColors.primary,
      'ucas': AppColors.accentGreen,
      'apprenticeship': AppColors.accentOrange,
      'roadmap': AppColors.accentBlue,
      'general': AppColors.textLight,
    };

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Notifications 🔔'),
        leading: GestureDetector(
          onTap: () => context.pop(), child: const BackBtn()),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Dashboard',
            onPressed: () => context.go('/home')),
        ],
      ),
      body: Column(children: [
        // Support reply alert — tapping opens the conversation
        Consumer(builder: (c, r, _) {
          final n = r.watch(unreadSupportProvider).valueOrNull ?? 0;
          if (n == 0) return const SizedBox();
          final isAdmin =
              r.watch(appUserProvider).valueOrNull?.isAdmin == true;
          return GestureDetector(
            onTap: () async {
              await context.push(isAdmin ? '/admin-inbox' : '/support');
              r.invalidate(unreadSupportProvider);
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.35))),
              child: Row(children: [
                const Text('💬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  isAdmin
                    ? (n == 1 ? 'A user has messaged support'
                              : '$n unread support messages from users')
                    : (n == 1 ? 'Support has replied to your message'
                              : 'Support has sent you $n replies'),
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 13.5,
                    fontWeight: FontWeight.w800, color: AppColors.textDark))),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ])));
        }),
        // Category filter
        SizedBox(height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final sel = category == cat;
              return GestureDetector(
                onTap: () => ref.read(_notifCategoryProvider.notifier).state = cat,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border)),
                  child: Text('${catEmojis[cat]} $cat', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textMid))));
            },
          )),

        // Exam board filter (only when GCSE selected)
        if (category == 'GCSE' || category == 'All')
          SizedBox(height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: boards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final b = boards[i];
                final sel = board == b;
                return GestureDetector(
                  onTap: () => ref.read(_notifBoardProvider.notifier).state = b,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryDark : AppColors.bgGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? AppColors.primaryDark : AppColors.border)),
                    child: Text(b, style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textMid))));
              },
            )),

        // Notifications list
        Expanded(child: notifAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (notifs) {
            // Filter
            final filtered = notifs.where((n) {
              final cat = (n['category'] as String).toLowerCase();
              final nb = n['exam_board'] as String?;
              final matchCat = category == 'All' ||
                  cat == category.toLowerCase();
              final matchBoard = board == 'All' || nb == null || nb == board;
              return matchCat && matchBoard;
            }).toList();

            if (filtered.isEmpty) {
              return const EmptyState(emoji: '🔔',
                title: 'No notifications',
                subtitle: 'Try a different filter');
            }

            // Separate upcoming vs past
            final upcoming = filtered.where((n) {
              final d = n['event_date'] != null
                  ? DateTime.tryParse(n['event_date']) : null;
              return d == null || d.isAfter(now.subtract(const Duration(days: 1)));
            }).toList();

            final past = filtered.where((n) {
              final d = n['event_date'] != null
                  ? DateTime.tryParse(n['event_date']) : null;
              return d != null && d.isBefore(now.subtract(const Duration(days: 1)));
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const Text('Upcoming', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 13,
                    fontWeight: FontWeight.w800, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  ...upcoming.map((n) => _NotifCard(n: n, colors: catColors)),
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Past', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 13,
                    fontWeight: FontWeight.w800, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  ...past.map((n) => _NotifCard(n: n, colors: catColors, past: true)),
                ],
              ],
            );
          },
        )),
      ]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> n;
  final Map<String, Color> colors;
  final bool past;
  const _NotifCard({required this.n, required this.colors, this.past = false});

  @override
  Widget build(BuildContext context) {
    final cat = n['category'] as String;
    final color = colors[cat] ?? AppColors.textLight;
    final date = n['event_date'] != null
        ? DateTime.tryParse(n['event_date']) : null;
    final board = n['exam_board'] as String?;
    final daysUntil = date != null
        ? date.difference(DateTime.now()).inDays : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: past ? 0.55 : 1.0,
        child: EduCard(
          color: past ? AppColors.bgGrey : null,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 4, height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(n['title'], style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w800))),
                if (board != null) TagBadge(label: board,
                  bg: AppColors.bgGrey, fg: AppColors.textMid),
              ]),
              const SizedBox(height: 2),
              Text(n['body'], style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid,
                height: 1.4)),
              if (date != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                    size: 11, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '${date.day}/${date.month}/${date.year}${daysUntil != null && daysUntil >= 0 ? ' · ${daysUntil == 0 ? "Today!" : daysUntil == 1 ? "Tomorrow" : "$daysUntil days away"}' : ''}',
                    style: TextStyle(fontFamily: 'Nunito',
                      fontSize: 11, color: color,
                      fontWeight: FontWeight.w700)),
                ]),
              ],
            ])),
          ]),
        ),
      ),
    );
  }
}
