// lib/features/admin/screens/admin_home_screen.dart
// Fixed admin home — dark theme, stats load correctly, clear layout.
// Upload to: lib/features/admin/screens/admin_home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _supabase.rpc('admin_dashboard_stats');
      setState(() {
        _stats = Map<String, dynamic>.from(r as Map);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('🛡️ Admin',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 13))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
                  onPressed: _load),
              ]),
              const SizedBox(height: 12),
              const Text('EduPaths Admin',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(
                'Good ${_greeting()}.',
                style: const TextStyle(fontSize: 14, color: Colors.white54)),
              const SizedBox(height: 24),

              // Stats grid
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF))))
              else
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _Stat('👤', 'Total Users',
                        '${_stats['total_users'] ?? 0}', const Color(0xFF4F46E5)),
                    _Stat('✅', 'Onboarded',
                        '${_stats['onboarded'] ?? 0}', const Color(0xFF059669)),
                    _Stat('💎', 'Premium',
                        '${_stats['premium'] ?? 0}', const Color(0xFFD97706)),
                    _Stat('📬', 'Unread Support',
                        '${_stats['unread_support'] ?? 0}',
                        (_stats['unread_support'] ?? 0) > 0
                            ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                        highlight: (_stats['unread_support'] ?? 0) > 0),
                    _Stat('📅', 'Today',
                        '${_stats['signups_today'] ?? 0}', const Color(0xFFDB2777)),
                    _Stat('📈', 'This Week',
                        '${_stats['signups_week'] ?? 0}', const Color(0xFF0891B2)),
                  ]),

              const SizedBox(height: 28),

              // Action tiles
              _label('Quick access'),
              const SizedBox(height: 10),
              _Tile('🗂️', 'Admin Dashboard',
                  'Users, quiz editor, support, test lab',
                  const Color(0xFF4F46E5), () => context.go('/admin')),
              _Tile('📬', 'Support Inbox',
                  'Reply to user messages',
                  const Color(0xFFDC2626), () => context.go('/admin-support'),
                  badge: (_stats['unread_support'] ?? 0) > 0
                      ? '${_stats['unread_support']}' : null),
              _Tile('👁️', 'View as User',
                  'See the app through any user\'s eyes',
                  const Color(0xFF0891B2), () => context.go('/admin-view-as')),
              _Tile('🧪', 'Test Onboarding',
                  'Run onboarding without saving data',
                  const Color(0xFF7C3AED), () => context.go('/admin-test-onboarding')),
              _Tile('🧠', 'Career IQ Quizzes',
                  'Edit and add quiz questions',
                  const Color(0xFFD97706), () => context.go('/admin')),

              const SizedBox(height: 28),
              Center(child: TextButton.icon(
                onPressed: () async {
                  await _supabase.auth.signOut();
                  if (context.mounted) context.go('/');
                },
                icon: const Icon(Icons.logout, size: 16, color: Colors.white38),
                label: const Text('Sign out',
                    style: TextStyle(color: Colors.white38)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(color: Colors.white54, fontSize: 12,
          fontWeight: FontWeight.w700, letterSpacing: 0.8));

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _Stat extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  final bool highlight;
  const _Stat(this.emoji, this.label, this.value, this.color, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: highlight ? color.withOpacity(0.15) : const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: highlight ? color.withOpacity(0.5) : Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 26,
            fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ]),
    ]),
  );
}

class _Tile extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  const _Tile(this.emoji, this.title, this.subtitle, this.color, this.onTap, {this.badge});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(emoji,
              style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(10)),
            child: Text(badge!, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))
        else
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      ]),
    ),
  );
}
