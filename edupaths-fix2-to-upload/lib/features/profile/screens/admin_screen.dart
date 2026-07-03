// lib/features/profile/screens/admin_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/external_link.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _sb = Supabase.instance.client;

// ── Providers ─────────────────────────────────
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Use view that safely joins users + subscriptions without FK requirement
  final res = await _sb
      .from('admin_users_view')
      .select()
      .order('created_at', ascending: false);
  return (res as List).cast<Map<String, dynamic>>();
});

final adminSchoolsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('schools').select().order('created_at', ascending: false);
  return (res as List).cast<Map<String, dynamic>>();
});

final adminCoursesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('courses')
      .select('id, title, url, category, course_type, institutions(name)')
      .order('title');
  return (res as List).cast<Map<String, dynamic>>();
});

final _adminSearchProvider = StateProvider<String>((ref) => '');
final _adminTabProvider = StateProvider<int>((ref) => 0);

// ══════════════════════════════════════════════
// ADMIN SCREEN
// ══════════════════════════════════════════════
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminState();
}

class _AdminState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0A3C),
        title: const Row(children: [
          Icon(Icons.admin_panel_settings_rounded,
            color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Admin Dashboard', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 16,
            fontWeight: FontWeight.w900, color: Colors.white)),
        ]),
        leading: GestureDetector(
          onTap: () => context.pop(), child: const BackBtn()),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontFamily: 'Nunito',
            fontSize: 11, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: '👥 Users'),
            Tab(text: '🏫 Schools'),
            Tab(text: '🎓 Courses'),
            Tab(text: '📊 Stats'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _UsersTab(),
        _SchoolsTab(),
        _CoursesTab(),
        _StatsTab(),
      ]),
    );
  }
}

// ══════════════════════════════════════════════
// USERS TAB
// ══════════════════════════════════════════════
class _UsersTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  String _search = '';
  String _filter = 'All'; // All, Free, Premium, Advisor, Admin

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (users) {
        final filtered = users.where((u) {
          final matchSearch = _search.isEmpty ||
              (u['email'] as String? ?? '').toLowerCase().contains(_search.toLowerCase()) ||
              (u['full_name'] as String? ?? '').toLowerCase().contains(_search.toLowerCase());
          final matchFilter = _filter == 'All' ||
              (_filter == 'Admin' && u['is_admin'] == true) ||
              (_filter == 'Advisor' && u['role_type'] == 'advisor') ||
              (_filter == 'Premium' && (u['subscriptions'] as List?)?.isNotEmpty == true) ||
              (_filter == 'Free' && (u['subscriptions'] as List?)?.isEmpty != false);
          return matchSearch && matchFilter;
        }).toList();

        return Column(children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                contentPadding: EdgeInsets.symmetric(vertical: 10)))),
          // Filter chips
          SizedBox(height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All','Free','Premium','Advisor','Admin'].map((f) =>
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filter == f
                            ? const Color(0xFF1E0A3C) : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _filter == f
                              ? const Color(0xFF1E0A3C) : AppColors.border)),
                      child: Text(f, style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _filter == f
                            ? Colors.white : AppColors.textMid)))))).toList())),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('${filtered.length} users',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                  color: AppColors.textMid)),
            ])),
          // User list
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _UserCard(
              user: filtered[i],
              onChanged: () => ref.invalidate(adminUsersProvider)))),
        ]);
      },
    );
  }
}

class _UserCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onChanged;
  const _UserCard({required this.user, required this.onChanged});
  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _expanded = false;
  bool _saving = false;

  String get _plan {
    return widget.user['subscription_plan'] as String? ?? 'free';
  }

  Color get _planColor {
    switch (_plan) {
      case 'premium': return AppColors.accentGreen;
      case 'premium_plus': return Colors.amber;
      default: return AppColors.textLight;
    }
  }

  Future<void> _updateRole(String newRole) async {
    setState(() => _saving = true);
    try {
      await _sb.from('users').update({
        'role_type': newRole,
        'is_admin': newRole == 'admin',
      }).eq('id', widget.user['id']);
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateTier(String tier) async {
    setState(() => _saving = true);
    try {
      final uid = widget.user['supabase_uid'] as String;
      await _sb.from('subscriptions').upsert({
        'firebase_uid': uid,
        'plan': tier,
        'status': tier == 'free' ? 'inactive' : 'active',
      }, onConflict: 'firebase_uid');
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password', style: TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'New password (min 6 chars)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Reset')),
        ]));
    if (confirmed == null || confirmed.length < 6) return;
    setState(() => _saving = true);
    try {
      await _sb.auth.admin.updateUserById(
        widget.user['supabase_uid'] as String,
        attributes: AdminUserAttributes(password: confirmed));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password updated!'),
        backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _viewAsUser() async {
    // Copy user UID to clipboard for reference
    await Clipboard.setData(ClipboardData(
        text: widget.user['supabase_uid'] as String? ?? ''));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('User UID copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user['email'] as String? ?? 'Unknown';
    final name = widget.user['full_name'] as String? ?? email.split('@').first;
    final roleType = widget.user['role_type'] as String? ?? 'student';
    final isAdmin = widget.user['is_admin'] == true;
    final onboarded = widget.user['onboarding_complete'] == true;
    final schoolYear = widget.user['school_year'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EduCard(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isAdmin
                  ? const Color(0xFF1E0A3C)
                  : AppColors.primaryPale,
              child: Text(name[0].toUpperCase(), style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w900,
                fontSize: 14,
                color: isAdmin ? Colors.white : AppColors.primary))),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontFamily: 'Nunito',
                fontSize: 13, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
              Text(email, style: const TextStyle(fontFamily: 'Nunito',
                fontSize: 11, color: AppColors.textMid),
                overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              TagBadge(label: _plan.toUpperCase(),
                bg: _planColor.withOpacity(0.15),
                fg: _planColor),
              if (isAdmin) const TagBadge(label: 'ADMIN',
                bg: Color(0xFF1E0A3C), fg: Colors.white),
              if (roleType == 'advisor') const TagBadge(label: 'ADVISOR',
                bg: AppColors.primaryPale, fg: AppColors.primaryDark),
            ]),
          ]),

          // Expanded controls
          if (_expanded) ...[
            const Divider(height: 16),
            // Info
            _InfoRow('School Year', schoolYear.isEmpty ? 'Not set' : schoolYear),
            _InfoRow('Role', roleType),
            _InfoRow('Onboarding', onboarded ? '✅ Complete' : '⏳ Pending'),
            const SizedBox(height: 10),
            // Actions
            const Text('Change Tier', style: TextStyle(fontFamily: 'Nunito',
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMid)),
            const SizedBox(height: 6),
            Row(children: ['free','premium','premium_plus'].map((t) =>
              Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _updateTier(t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _plan == t
                        ? AppColors.primary : AppColors.bgGrey,
                    foregroundColor: _plan == t
                        ? Colors.white : AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 10,
                      fontWeight: FontWeight.w700)),
                  child: Text(t == 'premium_plus' ? 'Premium+' : _cap(t)))))).toList()),
            const SizedBox(height: 6),
            const Text('Change Role', style: TextStyle(fontFamily: 'Nunito',
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMid)),
            const SizedBox(height: 6),
            Row(children: ['student','parent','advisor','admin'].map((r) =>
              Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _updateRole(r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roleType == r
                        ? const Color(0xFF1E0A3C) : AppColors.bgGrey,
                    foregroundColor: roleType == r
                        ? Colors.white : AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 9,
                      fontWeight: FontWeight.w700)),
                  child: Text(_cap(r)))))).toList()),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlineBtn(
                label: '🔑 Reset Password',
                onPressed: () => _resetPassword(context))),
              const SizedBox(width: 8),
              Expanded(child: OutlineBtn(
                label: '📋 Copy UID',
                onPressed: _viewAsUser)),
            ]),
          ],

          // Expand indicator
          Center(child: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textLight, size: 20)),
        ])));
  }

  String _cap(String s) => s[0].toUpperCase() + s.substring(1);
}

// ══════════════════════════════════════════════
// SCHOOLS TAB
// ══════════════════════════════════════════════
class _SchoolsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsAsync = ref.watch(adminSchoolsProvider);
    return schoolsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (schools) => schools.isEmpty
          ? const EmptyState(emoji: '🏫', title: 'No schools yet',
              subtitle: 'Schools appear here once registered')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: schools.length,
              itemBuilder: (_, i) {
                final s = schools[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EduCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('🏫', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s['name'] ?? 'Unknown School',
                        style: const TextStyle(fontFamily: 'Nunito',
                          fontSize: 14, fontWeight: FontWeight.w800))),
                      TagBadge(
                        label: s['membership_status'] == 'active'
                            ? '✅ Active' : '⏳ Trial',
                        bg: s['membership_status'] == 'active'
                            ? const Color(0xFFECFDF5) : AppColors.bgGrey,
                        fg: s['membership_status'] == 'active'
                            ? const Color(0xFF065F46) : AppColors.textMid),
                    ]),
                    const SizedBox(height: 6),
                    _InfoRow('Plan', s['membership_tier'] == 'cohort_300'
                        ? '£300/yr - 300 students' : '£120/yr - 120 students'),
                    _InfoRow('Contact', s['contact_email'] ?? 'N/A'),
                    _InfoRow('Postcode', s['postcode'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: ElevatedButton(
                        onPressed: () => _activateSchool(context, ref, s['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('✅ Set Active',
                          style: TextStyle(fontFamily: 'Nunito',
                            fontSize: 12, fontWeight: FontWeight.w800)))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(
                        onPressed: () => _setTrial(context, ref, s['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bgGrey,
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                        child: const Text('⏳ Set Trial',
                          style: TextStyle(fontFamily: 'Nunito',
                            fontSize: 12, fontWeight: FontWeight.w800)))),
                    ]),
                  ])));
              }),
    );
  }

  Future<void> _activateSchool(BuildContext ctx, WidgetRef ref, String id) async {
    await _sb.from('schools').update({
      'membership_status': 'active',
      'membership_expires_at': DateTime.now()
          .add(const Duration(days: 365)).toIso8601String(),
    }).eq('id', id);
    ref.invalidate(adminSchoolsProvider);
    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('School activated!'), backgroundColor: AppColors.success));
  }

  Future<void> _setTrial(BuildContext ctx, WidgetRef ref, String id) async {
    await _sb.from('schools').update({
      'membership_status': 'trial'}).eq('id', id);
    ref.invalidate(adminSchoolsProvider);
  }
}

// ══════════════════════════════════════════════
// COURSES TAB
// ══════════════════════════════════════════════
class _CoursesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<_CoursesTab> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(adminCoursesProvider);
    return coursesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (courses) {
        final filtered = _search.isEmpty ? courses
            : courses.where((c) =>
                (c['title'] as String).toLowerCase().contains(_search.toLowerCase()))
                .toList();
        return Column(children: [
          Padding(padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                contentPadding: EdgeInsets.symmetric(vertical: 10)))),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _CourseAdminCard(
              course: filtered[i],
              onChanged: () => ref.invalidate(adminCoursesProvider)))),
        ]);
      },
    );
  }
}

class _CourseAdminCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> course;
  final VoidCallback onChanged;
  const _CourseAdminCard({required this.course, required this.onChanged});
  @override
  ConsumerState<_CourseAdminCard> createState() => _CourseAdminCardState();
}

class _CourseAdminCardState extends ConsumerState<_CourseAdminCard> {
  bool _editing = false;
  late TextEditingController _urlCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.course['url'] as String? ?? '');
  }

  Future<void> _saveUrl() async {
    setState(() => _saving = true);
    try {
      await _sb.from('courses').update({'url': _urlCtrl.text.trim()})
          .eq('id', widget.course['id']);
      setState(() => _editing = false);
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inst = widget.course['institutions'] as Map?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: EduCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.course['title'] as String,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
              fontWeight: FontWeight.w800))),
          TagBadge(
            label: widget.course['course_type'] == 'Apprenticeship'
                ? '🔨' : '🎓',
            bg: AppColors.primaryPale, fg: AppColors.primaryDark),
        ]),
        if (inst != null) Text(inst['name'] as String,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
            color: AppColors.textMid)),
        const SizedBox(height: 6),
        if (!_editing) ...[
          Text(widget.course['url'] as String? ?? 'No URL',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
              color: AppColors.primary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _editing = true),
            child: const Text('✏️ Edit URL', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              color: AppColors.primary, fontWeight: FontWeight.w700))),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              final url = widget.course['url'] as String? ?? '';
              if (url.isNotEmpty) launchExternal(url); // F4 — normalized, new tab
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(8)),
              child: const Text('Go →', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 12,
                fontWeight: FontWeight.w800, color: Colors.white)))),
        ] else ...[
          TextField(
            controller: _urlCtrl,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'https://...',
              contentPadding: EdgeInsets.all(8))),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: _saving ? null : _saveUrl,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6)),
              child: _saving
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Text('Save'))),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: const Text('Cancel')),
          ]),
        ],
      ])));
  }
}

// ══════════════════════════════════════════════
// STATS TAB
// ══════════════════════════════════════════════
class _StatsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final schoolsAsync = ref.watch(adminSchoolsProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (users) {
        final total = users.length;
        final onboarded = users.where((u) =>
            u['onboarding_complete'] == true).length;
        final premium = users.where((u) =>
            u['subscription_plan'] != null &&
            u['subscription_plan'] != 'free').length;
        final advisors = users.where((u) =>
            u['role_type'] == 'advisor').length;
        final parents = users.where((u) =>
            u['role_type'] == 'parent').length;
        final schools = schoolsAsync.valueOrNull?.length ?? 0;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E0A3C),
                borderRadius: BorderRadius.all(Radius.circular(16))),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Platform Overview', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 20,
                  fontWeight: FontWeight.w900, color: Colors.white)),
                Text('Real-time statistics', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 13, color: Colors.white54)),
              ])),
            const SizedBox(height: 16),
            _StatCard('👥 Total Users', '$total', AppColors.primary),
            const SizedBox(height: 8),
            _StatCard('✅ Onboarded', '$onboarded / $total',
              AppColors.accentGreen),
            const SizedBox(height: 8),
            _StatCard('⭐ Premium Users', '$premium', Colors.amber),
            const SizedBox(height: 8),
            _StatCard('👨‍👩‍👧 Parents', '$parents', AppColors.accentBlue),
            const SizedBox(height: 8),
            _StatCard('🏫 School Advisors', '$advisors', AppColors.accentOrange),
            const SizedBox(height: 8),
            _StatCard('🏫 Schools', '$schools', const Color(0xFF1E0A3C)),
            const SizedBox(height: 20),
            const Text('Conversion Rate', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _ProgressBar('Onboarding', onboarded, total, AppColors.accentGreen),
            const SizedBox(height: 6),
            _ProgressBar('Premium', premium, total, Colors.amber),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => EduCard(
    child: Row(children: [
      Container(width: 4, height: 44,
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700))),
      Text(value, style: TextStyle(fontFamily: 'Nunito',
        fontSize: 22, fontWeight: FontWeight.w900, color: color)),
    ]));
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final int value, total;
  final Color color;
  const _ProgressBar(this.label, this.value, this.total, this.color);
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 12, color: AppColors.textMid)),
        const Spacer(),
        Text('${(pct * 100).toStringAsFixed(1)}%',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
            fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct, minHeight: 8,
          backgroundColor: AppColors.bgGrey,
          valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }
}

// ══════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════
class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 11, color: AppColors.textMid)),
      Text(value, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 11, fontWeight: FontWeight.w700)),
    ]));
}
