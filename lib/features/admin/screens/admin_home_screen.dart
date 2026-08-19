import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin home — replaces the normal home screen for is_admin users.
/// Shows: quick stats, support inbox (with unread badge), and shortcuts
/// to the full admin dashboard, View-As, onboarding test, and support inbox.
///
/// Upload to: lib/features/admin/screens/admin_home_screen.dart
///
/// ROUTING: in your go_router, redirect is_admin users from /home → /admin-home
/// OR add a check at the top of home_screen.dart:
///   if (isAdmin) return const AdminHomeScreen();

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
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Total users
      final usersResp = await _supabase
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('is_child_account', false);

      // Unread support messages
      final supportResp = await _supabase
          .from('support_messages')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('sender', 'user')
          .eq('read_by_admin', false);

      // Onboarded users
      final onboardedResp = await _supabase
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('onboarding_complete', true);

      // Premium users
      final premiumResp = await _supabase
          .from('users')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('subscription_tier', 'premium');

      setState(() {
        _stats = {
          'total_users': usersResp.count ?? 0,
          'unread_support': supportResp.count ?? 0,
          'onboarded': onboardedResp.count ?? 0,
          'premium': premiumResp.count ?? 0,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('🛡️ Admin',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadStats,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('EduPaths Admin',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Good ${_greeting()}, here\'s what\'s happening.',
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 24),

              // ── Stats row ────────────────────────────────────────────
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      emoji: '👤',
                      label: 'Total users',
                      value: _stats['total_users'].toString(),
                      color: const Color(0xFF4F46E5),
                    ),
                    _StatCard(
                      emoji: '✅',
                      label: 'Onboarded',
                      value: _stats['onboarded'].toString(),
                      color: const Color(0xFF059669),
                    ),
                    _StatCard(
                      emoji: '💎',
                      label: 'Premium',
                      value: _stats['premium'].toString(),
                      color: const Color(0xFFD97706),
                    ),
                    _StatCard(
                      emoji: '📬',
                      label: 'Unread support',
                      value: _stats['unread_support'].toString(),
                      color: _stats['unread_support'] > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF6B7280),
                      highlight: _stats['unread_support'] > 0,
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              // ── Main actions ─────────────────────────────────────────
              const Text('Quick access',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              _ActionTile(
                emoji: '🗂️',
                title: 'Admin Dashboard',
                subtitle: 'Users, careers, schools, courses, stats',
                color: const Color(0xFF4F46E5),
                onTap: () => context.go('/admin'),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                emoji: '📬',
                title: 'Support Inbox',
                subtitle: 'Reply to user messages',
                color: const Color(0xFFDC2626),
                badge: _stats['unread_support'] > 0
                    ? _stats['unread_support'].toString()
                    : null,
                onTap: () => context.go('/admin-support'),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                emoji: '👁️',
                title: 'View as User',
                subtitle: 'See the app through any user\'s eyes',
                color: const Color(0xFF0891B2),
                onTap: () => context.go('/admin-view-as'),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                emoji: '🧪',
                title: 'Test Onboarding',
                subtitle: 'Run the full onboarding flow as admin',
                color: const Color(0xFF7C3AED),
                onTap: () => context.go('/admin-test-onboarding'),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                emoji: '🏠',
                title: 'View Student Home',
                subtitle: 'See the home screen as a student would',
                color: const Color(0xFF059669),
                onTap: () => context.go('/admin-test-home'),
              ),

              const SizedBox(height: 32),

              // ── Sign out ─────────────────────────────────────────────
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await _supabase.auth.signOut();
                    if (context.mounted) context.go('/');
                  },
                  icon: const Icon(Icons.logout, size: 16,
                      color: Colors.black38),
                  label: const Text('Sign out',
                      style: TextStyle(color: Colors.black38)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  final bool highlight;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: color.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
