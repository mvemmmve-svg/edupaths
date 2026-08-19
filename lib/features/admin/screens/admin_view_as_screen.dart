import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin "View as" — pick any user and see their full profile:
/// matches, interests, account details.
///
/// Upload to: lib/features/admin/screens/admin_view_as_screen.dart
/// Route:     /admin-view-as

class AdminViewAsScreen extends StatefulWidget {
  const AdminViewAsScreen({super.key});

  @override
  State<AdminViewAsScreen> createState() => _AdminViewAsScreenState();
}

class _AdminViewAsScreenState extends State<AdminViewAsScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers([String? search]) async {
    setState(() => _loading = true);
    try {
      final resp = await _supabase.rpc('admin_list_users', params: {
        'p_limit': 100,
        'p_offset': 0,
        'p_search': search?.isEmpty == true ? null : search,
      });
      setState(() {
        _users = List<Map<String, dynamic>>.from(resp as List);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/admin-home'),
        ),
        title: const Text('View as User',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => _loadUsers(v),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${_users.length} users',
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 13)),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final u = _users[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUserProfileView(
                                userId: u['id'] as String,
                                userName:
                                    u['name'] as String? ?? 'Unknown',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6)
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: _roleColor(
                                        u['role_type'] as String?)
                                    .withOpacity(0.15),
                                child: Text(
                                  (u['name'] as String? ?? '?')
                                      .characters
                                      .first
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _roleColor(
                                          u['role_type'] as String?)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          u['name'] as String? ??
                                              'Unknown',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(width: 6),
                                        if (u['is_admin'] == true)
                                          _Badge(
                                              '🛡️ Admin',
                                              const Color(0xFF6C63FF)),
                                        if (u['subscription_tier'] ==
                                            'premium')
                                          _Badge('💎 Premium',
                                              const Color(0xFFD97706)),
                                      ],
                                    ),
                                    Text(
                                      u['email'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${u['match_count']} matches',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black38),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: u['onboarding_complete'] ==
                                              true
                                          ? const Color(0xFF059669)
                                              .withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      u['onboarding_complete'] == true
                                          ? 'Onboarded'
                                          : 'Pending',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: u['onboarding_complete'] ==
                                                  true
                                              ? const Color(0xFF059669)
                                              : Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Colors.black26, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'student':
        return const Color(0xFF4F46E5);
      case 'parent':
        return const Color(0xFF059669);
      case 'advisor':
        return const Color(0xFF0891B2);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── User profile view ─────────────────────────────────────────────────────────

class AdminUserProfileView extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserProfileView(
      {super.key, required this.userId, required this.userName});

  @override
  State<AdminUserProfileView> createState() => _AdminUserProfileViewState();
}

class _AdminUserProfileViewState extends State<AdminUserProfileView>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final resp = await _supabase.rpc('admin_user_full_profile',
          params: {'p_user_id': widget.userId});
      setState(() {
        _profile = Map<String, dynamic>.from(resp as Map);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _profile?['user'] as Map<String, dynamic>?;
    final matches =
        (_profile?['matches'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final interests =
        (_profile?['interests'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Viewing as admin',
                style: TextStyle(fontSize: 11, color: Color(0xFF6C63FF))),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF6C63FF),
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Matches'),
            Tab(text: 'Interests'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── Profile tab ──────────────────────────────────────
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ProfileCard(
                      label: 'Account details',
                      rows: [
                        _Row('Name', user?['name'] ?? '—'),
                        _Row('Email', user?['email'] ?? '—'),
                        _Row('Role', user?['role_type'] ?? '—'),
                        _Row('Year group', user?['school_year'] ?? '—'),
                        _Row('Subscription',
                            user?['subscription_tier'] ?? 'free'),
                        _Row('Onboarded',
                            user?['onboarding_complete'] == true
                                ? '✅ Yes'
                                : '❌ No'),
                        _Row('Joined',
                            _fmtDate(user?['created_at']?.toString())),
                        _Row('Last login',
                            _fmtDate(user?['last_login']?.toString())),
                      ],
                    ),
                    if (user?['admin_notes'] != null) ...[
                      const SizedBox(height: 12),
                      _ProfileCard(
                        label: 'Admin notes',
                        rows: [
                          _Row('Notes', user!['admin_notes'] as String),
                        ],
                      ),
                    ],
                  ],
                ),

                // ── Matches tab ──────────────────────────────────────
                matches.isEmpty
                    ? const Center(
                        child: Text('No matches yet',
                            style: TextStyle(color: Colors.black45)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: matches.length,
                        itemBuilder: (ctx, i) {
                          final m = matches[i];
                          final score = m['score'] as int? ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m['career'] as String? ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        m['category'] as String? ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45),
                                      ),
                                      if (m['reason'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          m['reason'] as String,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black38),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _scoreColor(score)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$score%',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _scoreColor(score),
                                        fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                // ── Interests tab ────────────────────────────────────
                interests.isEmpty
                    ? const Center(
                        child: Text('No interests saved',
                            style: TextStyle(color: Colors.black45)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: interests.length,
                        itemBuilder: (ctx, i) {
                          final interest = interests[i];
                          final score =
                              interest['score'] as int? ?? 3;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        interest['name'] as String? ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        interest['category'] as String? ??
                                            '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (s) {
                                    return Icon(
                                      s < score
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 16,
                                      color: s < score
                                          ? const Color(0xFFD97706)
                                          : Colors.black12,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return const Color(0xFF059669);
    if (score >= 50) return const Color(0xFF0891B2);
    return const Color(0xFFD97706);
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ProfileCard extends StatelessWidget {
  final String label;
  final List<_Row> rows;
  const _ProfileCard({required this.label, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black45)),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(r.label,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black45)),
                    ),
                    Expanded(
                      child: Text(r.value,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}
