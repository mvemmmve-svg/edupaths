import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _interests = [];
  List<Map<String, dynamic>> _traits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        setState(() => _loading = false);
        return;
      }

      final userRes = await _supabase
          .from('users')
          .select(
              'id, name, email, school_year, role, is_admin, onboarding_complete, created_at, supabase_uid')
          .eq('supabase_uid', authUser.id)
          .single();

      final userId = userRes['id'];

      final interestRes = await _supabase
          .from('user_interest')
          .select('interests(name, category)')
          .eq('user_id', userId);

      final traitRes = await _supabase
          .from('user_trait')
          .select('trait(name)')
          .eq('user_id', userId);

      setState(() {
        _user = userRes;
        _interests = (interestRes as List)
            .map((r) => r['interests'] as Map<String, dynamic>? ?? {})
            .where((i) => i.isNotEmpty)
            .toList();
        _traits = (traitRes as List)
            .map((r) => r['trait'] as Map<String, dynamic>? ?? {})
            .where((t) => t.isNotEmpty)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FE9)),
            child: const Text('Sign out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _supabase.auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  void _openEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: _user!,
        onSaved: _load,
      ),
    );
  }

  void _openEditInterests() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditInterestsSheet(
        userId: _user!['id'],
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _user?['name'] ?? 'Student';
    final year = _user?['school_year'] ?? '';
    final email = _user?['email'] ?? '';
    final isAdmin = _user?['is_admin'] == true;
    final isOnboarded = _user?['onboarding_complete'] == true;
    final joinedAt = _user?['created_at'] != null
        ? _formatDate(_user!['created_at'])
        : '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(
                color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B4FE9), Color(0xFF8B7FF5)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 32,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      if (year.isNotEmpty)
                        Text(year,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnboarded
                                  ? Icons.check_box
                                  : Icons.pending_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOnboarded
                                  ? 'Profile Complete'
                                  : 'Profile In Progress',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: _user != null ? _openEditProfile : null,
                  tooltip: 'Edit profile',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Account details ────────────────────────────────────────────
          _SectionCard(
            title: 'Account Details',
            child: Column(
              children: [
                _DetailRow(label: 'Name', value: name),
                _DetailRow(label: 'Email', value: email),
                _DetailRow(label: 'School year', value: year),
                _DetailRow(
                    label: 'Profile',
                    value: isOnboarded ? 'Complete' : 'In progress'),
                _DetailRow(label: 'Joined', value: joinedAt),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Interests & Strengths ──────────────────────────────────────
          _SectionCard(
            title: 'Interests & Strengths',
            trailing: TextButton(
              onPressed: _openEditInterests,
              child: const Text('Edit',
                  style: TextStyle(color: Color(0xFF5B4FE9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_interests.isEmpty && _traits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Complete your profile to see your interests and strengths.',
                      style: TextStyle(color: Color(0xFF888AAA)),
                    ),
                  )
                else ...[
                  if (_interests.isNotEmpty) ...[
                    const _SubHeading(icon: Icons.interests, label: 'Interests'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _interests
                          .map((i) => _Chip(label: i['name'] ?? ''))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_traits.isNotEmpty) ...[
                    const _SubHeading(
                        icon: Icons.star_border, label: 'Strengths'),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _traits
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 16,
                                        color: Color(0xFF5B4FE9)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        t['name'] ?? '',
                                        style: const TextStyle(
                                            color: Color(0xFF1A1A2E),
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Settings ───────────────────────────────────────────────────
          _SectionCard(
            title: 'Settings',
            child: Column(
              children: [
                if (!isOnboarded)
                  _SettingsTile(
                    icon: Icons.rocket_launch_outlined,
                    label: 'Complete your profile',
                    color: const Color(0xFF5B4FE9),
                    onTap: () => context.go('/onboarding/start'),
                  ),
                _SettingsTile(
                  icon: Icons.school_outlined,
                  label: 'Join your school',
                  onTap: () => context.push('/join-school'),
                ),
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'School advisor portal',
                  onTap: () => context.push('/school-advisor'),
                ),
                if (isAdmin)
                  _SettingsTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin panel',
                    color: Colors.deepOrange,
                    onTap: () => context.push('/admin'),
                  ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  label: 'About EduPaths',
                  onTap: () => context.push('/about'),
                ),
                _SettingsTile(
                  icon: Icons.support_agent_outlined,
                  label: 'Help & support',
                  onTap: () => context.push('/support'),
                ),
                _SettingsTile(
                  icon: Icons.logout,
                  label: 'Sign out',
                  color: Colors.red,
                  onTap: _signOut,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Edit profile sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSaved;

  const _EditProfileSheet({required this.user, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  String? _selectedYear;
  bool _saving = false;

  final _years = [
    'Year 7', 'Year 8', 'Year 9', 'Year 10', 'Year 11',
    'Year 12', 'Year 13', 'College', 'University', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.user['name']?.toString() ?? '');
    _selectedYear = widget.user['school_year']?.toString();
    if (_selectedYear != null && !_years.contains(_selectedYear)) {
      _selectedYear = null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _supabase.rpc('update_my_profile', params: {
        'p_name': _nameCtrl.text.trim(),
        'p_school_year': _selectedYear ?? '',
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save — try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Profile',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save',
                          style: TextStyle(
                              color: Color(0xFF5B4FE9),
                              fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Name',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Your name',
                filled: true,
                fillColor: const Color(0xFFF0EFFF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            const Text('School Year',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _years.map((y) {
                final selected = _selectedYear == y;
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = y),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF5B4FE9)
                          : const Color(0xFFF0EFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      y,
                      style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Interests & Strengths sheet ────────────────────────────────────────

class _EditInterestsSheet extends StatefulWidget {
  final String userId;
  final VoidCallback onSaved;

  const _EditInterestsSheet({required this.userId, required this.onSaved});

  @override
  State<_EditInterestsSheet> createState() => _EditInterestsSheetState();
}

class _EditInterestsSheetState extends State<_EditInterestsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _allInterests = [];
  List<Map<String, dynamic>> _allTraits = [];
  Set<String> _selectedInterestIds = {};
  Set<String> _selectedTraitIds = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final interestsRes =
        await _supabase.from('interests').select('id, name, category').order('category').order('name');
    final traitsRes =
        await _supabase.from('trait').select('id, name, category').order('category').order('name');
    final userInterestsRes = await _supabase
        .from('user_interest')
        .select('interest_id')
        .eq('user_id', widget.userId);
    final userTraitsRes = await _supabase
        .from('user_trait')
        .select('trait_id')
        .eq('user_id', widget.userId);

    setState(() {
      _allInterests = List<Map<String, dynamic>>.from(interestsRes);
      _allTraits = List<Map<String, dynamic>>.from(traitsRes);
      _selectedInterestIds = {
        for (final r in userInterestsRes as List)
          r['interest_id']?.toString() ?? ''
      }..remove('');
      _selectedTraitIds = {
        for (final r in userTraitsRes as List)
          r['trait_id']?.toString() ?? ''
      }..remove('');
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Save interests
      await _supabase
          .from('user_interest')
          .delete()
          .eq('user_id', widget.userId);
      if (_selectedInterestIds.isNotEmpty) {
        await _supabase.from('user_interest').insert(
          _selectedInterestIds
              .map((id) => {'user_id': widget.userId, 'interest_id': id, 'score': 3})
              .toList(),
        );
      }
      // Save traits
      await _supabase
          .from('user_trait')
          .delete()
          .eq('user_id', widget.userId);
      if (_selectedTraitIds.isNotEmpty) {
        await _supabase.from('user_trait').insert(
          _selectedTraitIds
              .map((id) => {'user_id': widget.userId, 'trait_id': id})
              .toList(),
        );
      }
      // Regenerate matches
      final authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        await _supabase.rpc('generate_smart_matches',
            params: {'p_user_uid': authUser.id});
      }
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Interests updated! Matches refreshed.'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save — try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Edit Interests & Strengths',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedInterestIds.clear();
                      _selectedTraitIds.clear();
                    }),
                    child: const Text('Clear All',
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save',
                            style: TextStyle(
                                color: Color(0xFF5B4FE9),
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tab,
              labelColor: const Color(0xFF5B4FE9),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF5B4FE9),
              tabs: [
                Tab(text: 'Interests (${_selectedInterestIds.length})'),
                Tab(text: 'Strengths (${_selectedTraitIds.length})'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _InterestPicker(
                          items: _allInterests,
                          selected: _selectedInterestIds,
                          onToggle: (id) => setState(() {
                            if (_selectedInterestIds.contains(id)) {
                              _selectedInterestIds.remove(id);
                            } else {
                              _selectedInterestIds.add(id);
                            }
                          }),
                        ),
                        _TraitPicker(
                          items: _allTraits,
                          selected: _selectedTraitIds,
                          onToggle: (id) => setState(() {
                            if (_selectedTraitIds.contains(id)) {
                              _selectedTraitIds.remove(id);
                            } else {
                              _selectedTraitIds.add(id);
                            }
                          }),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestPicker extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _InterestPicker(
      {required this.items, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    // Group by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final i in items) {
      final cat = i['category']?.toString() ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(e.key.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF888AAA),
                      letterSpacing: 1)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: e.value.map((item) {
                final id = item['id']?.toString() ?? '';
                final isSelected = selected.contains(id);
                return GestureDetector(
                  onTap: () => onToggle(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5B4FE9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5B4FE9)
                              : Colors.grey.shade300),
                    ),
                    child: Text(
                      item['name'] ?? '',
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                          fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
          ],
        );
      }).toList(),
    );
  }
}

class _TraitPicker extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _TraitPicker(
      {required this.items, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in items) {
      final cat = t['category']?.toString() ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(t);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(e.key.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF888AAA),
                      letterSpacing: 1)),
            ),
            ...e.value.map((item) {
              final id = item['id']?.toString() ?? '';
              final isSelected = selected.contains(id);
              return GestureDetector(
                onTap: () => onToggle(id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEEECFF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5B4FE9)
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] ?? '',
                          style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF5B4FE9)
                                  : const Color(0xFF1A1A2E),
                              fontSize: 14),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF5B4FE9), size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard(
      {required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF888AAA), fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF1A1A2E), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SubHeading({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF5B4FE9)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEECFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFF5B4FE9), fontSize: 12)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1A1A2E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: c, fontSize: 14)),
            ),
            Icon(Icons.chevron_right,
                color: c.withOpacity(0.4), size: 18),
          ],
        ),
      ),
    );
  }
}
