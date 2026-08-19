// lib/features/profile/screens/admin_screen.dart
// Full admin dashboard — NOT a normal user screen.
// Tabs: Overview · Users · Quiz Editor · Support · Test Lab
// Upload to: lib/features/profile/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/admin/screens/admin_view_as_screen.dart';
import '../../../features/admin/screens/admin_support_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late final TabController _tabs;
  Map<String, dynamic> _stats = {};
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadStats();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final r = await _supabase.rpc('admin_dashboard_stats');
      setState(() { _stats = Map<String, dynamic>.from(r as Map); _statsLoading = false; });
    } catch (_) { setState(() => _statsLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Text('🛡️', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: _loadStats),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () async {
                await _supabase.auth.signOut();
                if (context.mounted) context.go('/');
              }),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFF6C63FF),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Quiz Editor'),
            Tab(text: 'Support'),
            Tab(text: 'Test Lab'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _OverviewTab(stats: _stats, loading: _statsLoading, onRefresh: _loadStats),
        const _UsersTab(),
        const _QuizEditorTab(),
        const _SupportTab(),
        const _TestLabTab(),
      ]),
    );
  }
}

// ── OVERVIEW TAB ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool loading;
  final VoidCallback onRefresh;
  const _OverviewTab({required this.stats, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (loading)
          const Center(child: Padding(padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF6C63FF))))
        else ...[
          _SectionHead('📊 Live Stats'),
          GridView.count(crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
            children: [
              _StatTile('👤', 'Total Users', '${stats['total_users'] ?? 0}', const Color(0xFF4F46E5)),
              _StatTile('✅', 'Onboarded', '${stats['onboarded'] ?? 0}', const Color(0xFF059669)),
              _StatTile('💎', 'Premium', '${stats['premium'] ?? 0}', const Color(0xFFD97706)),
              _StatTile('📬', 'Unread Support', '${stats['unread_support'] ?? 0}',
                  (stats['unread_support'] ?? 0) > 0 ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                  highlight: (stats['unread_support'] ?? 0) > 0),
              _StatTile('🎯', 'Careers', '${stats['total_careers'] ?? 0}', const Color(0xFF7C3AED)),
              _StatTile('🧠', 'Quiz Careers', '${stats['total_quizzes'] ?? 0}', const Color(0xFF0891B2)),
              _StatTile('📅', 'Signups Today', '${stats['signups_today'] ?? 0}', const Color(0xFFDB2777)),
              _StatTile('📈', 'This Week', '${stats['signups_week'] ?? 0}', const Color(0xFF059669)),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHead('⚡ Quick Actions'),
          const SizedBox(height: 8),
          _QuickAction('👁️ View as User', 'See the app through any user\'s eyes',
              () => context.go('/admin-view-as')),
          _QuickAction('📬 Support Inbox', 'Reply to user messages',
              () => context.go('/admin-support')),
          _QuickAction('🧪 Test Onboarding', 'Run onboarding flow without saving',
              () => context.go('/admin-test-onboarding')),
          _QuickAction('🏠 Test Home Screen', 'Preview what students see',
              () => context.go('/admin-test-home')),
          const SizedBox(height: 24),
          _SectionHead('🔧 System'),
          const SizedBox(height: 8),
          _QuickAction('📋 Full Legacy Dashboard', 'Old 8-tab admin (careers CRUD, schools, etc.)',
              () => _showLegacyNote(context)),
        ],
      ]),
    );
  }

  void _showLegacyNote(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Legacy Dashboard'),
      content: const Text('The old admin dashboard with Careers CRUD, Schools, Institutions, Broadcast etc. is still accessible via the /admin route in your router. Add a GoRoute for /admin-legacy pointing to your existing AdminDashboardScreen.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ));
  }
}

class _StatTile extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  final bool highlight;
  const _StatTile(this.emoji, this.label, this.value, this.color, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: highlight ? color.withOpacity(0.15) : const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: highlight ? color.withOpacity(0.5) : Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ]),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback onTap;
  const _QuickAction(this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold,
              color: Colors.white, fontSize: 14)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      ]),
    ),
  );
}

class _SectionHead extends StatelessWidget {
  final String text;
  const _SectionHead(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold,
        color: Colors.white70, fontSize: 13, letterSpacing: 0.5)));
}

// ── USERS TAB ────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _supabase = Supabase.instance.client;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load([String? q]) async {
    setState(() => _loading = true);
    try {
      final r = await _supabase.rpc('admin_list_users', params: {
        'p_limit': 100, 'p_offset': 0,
        'p_search': q?.isEmpty == true ? null : q});
      setState(() { _users = List<Map<String, dynamic>>.from(r as List); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        controller: _search,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search name or email…',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
          filled: true, fillColor: const Color(0xFF1A1A2E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        onChanged: _load)),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Text('${_users.length} users',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ])),
    Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _users.length,
            itemBuilder: (ctx, i) {
              final u = _users[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AdminUserProfileView(
                        userId: u['id'] as String,
                        userName: u['name'] as String? ?? 'Unknown'))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10)),
                  child: Row(children: [
                    CircleAvatar(radius: 18,
                      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                      child: Text((u['name'] as String? ?? '?').characters.first.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u['name'] as String? ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(u['email'] as String? ?? '',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (u['subscription_tier'] == 'premium')
                        const Text('💎', style: TextStyle(fontSize: 14)),
                      if (u['is_admin'] == true)
                        const Text('🛡️', style: TextStyle(fontSize: 14)),
                      Text('${u['match_count']} matches',
                          style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ]),
                  ]),
                ),
              );
            })),
  ]);
}

// ── QUIZ EDITOR TAB ──────────────────────────────────────────────────────────

class _QuizEditorTab extends StatefulWidget {
  const _QuizEditorTab();
  @override State<_QuizEditorTab> createState() => _QuizEditorTabState();
}

class _QuizEditorTabState extends State<_QuizEditorTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _careers = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final qr = await _supabase.from('career_quizzes')
          .select().order('career_name').order('sort_order');
      final cr = await _supabase.from('careers').select('id, name, category').order('name');
      setState(() {
        _quizzes = List<Map<String, dynamic>>.from(qr as List);
        _careers = List<Map<String, dynamic>>.from(cr as List);
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  // Group by career
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final q in _quizzes) {
      m.putIfAbsent(q['career_name'] as String, () => []).add(q);
    }
    return m;
  }

  Future<void> _toggleActive(String id, bool current) async {
    await _supabase.from('career_quizzes').update({'is_active': !current}).eq('id', id);
    _load();
  }

  Future<void> _deleteQuestion(String id) async {
    await _supabase.from('career_quizzes').delete().eq('id', id);
    _load();
  }

  void _openAddQuestion() {
    showModalBottomSheet(context: context, isScrollControlled: true,
        backgroundColor: const Color(0xFF1A1A2E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _AddQuestionSheet(careers: _careers, onSaved: _load));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
    final grouped = _grouped;
    final careerNames = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: _openAddQuestion,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Question', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), children: [
        ...careerNames.map((career) {
          final qs = grouped[career]!;
          return ExpansionTile(
            collapsedBackgroundColor: const Color(0xFF1A1A2E),
            backgroundColor: const Color(0xFF12122A),
            collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white10)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white10)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            title: Text(career, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${qs.length} question${qs.length != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            children: qs.map((q) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(q['question'] as String? ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                  Switch(
                    value: q['is_active'] as bool? ?? true,
                    activeColor: const Color(0xFF059669),
                    onChanged: (_) => _toggleActive(q['id'] as String, q['is_active'] as bool? ?? true)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    onPressed: () => showDialog(context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          title: const Text('Delete question?', style: TextStyle(color: Colors.white)),
                          content: const Text('This cannot be undone.',
                              style: TextStyle(color: Colors.white54)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel')),
                            TextButton(onPressed: () {
                              Navigator.pop(context);
                              _deleteQuestion(q['id'] as String);
                            }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ))),
                ]),
                const Divider(color: Colors.white10),
                _AnswerRow('A', q['option_a'], q['correct_answer'] == 'a'),
                _AnswerRow('B', q['option_b'], q['correct_answer'] == 'b'),
                _AnswerRow('C', q['option_c'], q['correct_answer'] == 'c'),
              ]),
            )).toList(),
          );
        }),
      ]),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label, text;
  final bool correct;
  const _AnswerRow(this.label, this.text, this.correct);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Container(width: 20, height: 20,
        decoration: BoxDecoration(
            color: correct ? const Color(0xFF059669) : Colors.white10,
            shape: BoxShape.circle),
        child: Center(child: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 8),
      Expanded(child: Text(text as String? ?? '',
          style: TextStyle(color: correct ? const Color(0xFF6EE7B7) : Colors.white54, fontSize: 11))),
    ]),
  );
}

class _AddQuestionSheet extends StatefulWidget {
  final List<Map<String, dynamic>> careers;
  final VoidCallback onSaved;
  const _AddQuestionSheet({required this.careers, required this.onSaved});
  @override State<_AddQuestionSheet> createState() => _AddQuestionSheetState();
}

class _AddQuestionSheetState extends State<_AddQuestionSheet> {
  final _supabase = Supabase.instance.client;
  final _qCtrl = TextEditingController();
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  final _factCtrl = TextEditingController();
  String _correct = 'a';
  String? _selectedCareerId;
  String? _selectedCareerName;
  bool _saving = false;

  @override
  void dispose() {
    _qCtrl.dispose(); _aCtrl.dispose(); _bCtrl.dispose();
    _cCtrl.dispose(); _factCtrl.dispose(); super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCareerId == null || _qCtrl.text.isEmpty ||
        _aCtrl.text.isEmpty || _bCtrl.text.isEmpty || _cCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in all fields')));
      return;
    }
    setState(() => _saving = true);
    try {
      // Get sort order
      final existing = await _supabase.from('career_quizzes')
          .select('sort_order').eq('career_id', _selectedCareerId!)
          .order('sort_order', ascending: false).limit(1);
      final nextSort = ((List<Map<String,dynamic>>.from(existing as List)
          .firstOrNull?['sort_order'] as int?) ?? 0) + 1;

      await _supabase.from('career_quizzes').insert({
        'career_id': _selectedCareerId,
        'career_name': _selectedCareerName,
        'question': _qCtrl.text.trim(),
        'option_a': _aCtrl.text.trim(),
        'option_b': _bCtrl.text.trim(),
        'option_c': _cCtrl.text.trim(),
        'correct_answer': _correct,
        'explanation': _factCtrl.text.trim(),
        'sort_order': nextSort,
        'is_active': true,
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.92, maxChildSize: 0.98,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Quiz Question', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),

          const Text('Career', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDec('Select a career'),
            value: _selectedCareerId,
            items: widget.careers.map((c) => DropdownMenuItem(
              value: c['id'] as String,
              child: Text(c['name'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedCareerId = v;
                _selectedCareerName = widget.careers
                    .firstWhere((c) => c['id'] == v)['name'] as String;
              });
            },
          ),
          const SizedBox(height: 14),

          _Field('Question', _qCtrl, maxLines: 3),
          const SizedBox(height: 14),
          _Field('Option A', _aCtrl),
          const SizedBox(height: 10),
          _Field('Option B', _bCtrl),
          const SizedBox(height: 10),
          _Field('Option C', _cCtrl),
          const SizedBox(height: 14),

          const Text('Correct answer', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Row(children: ['a', 'b', 'c'].map((opt) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _correct = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: _correct == opt ? const Color(0xFF059669) : const Color(0xFF0F0F1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _correct == opt
                        ? const Color(0xFF059669) : Colors.white24)),
                child: Text(opt.toUpperCase(), style: TextStyle(
                    color: _correct == opt ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold)),
              ),
            ),
          )).toList()),
          const SizedBox(height: 14),

          _Field('Fun fact / Myth busted (shown after answering)', _factCtrl, maxLines: 3),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Question', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 16)),
          )),
        ]),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
    filled: true, fillColor: const Color(0xFF0F0F1A),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white10)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF6C63FF))));

  Widget _Field(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDec(label)),
      ]);
}

// ── SUPPORT TAB ───────────────────────────────────────────────────────────────

class _SupportTab extends StatefulWidget {
  const _SupportTab();
  @override State<_SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<_SupportTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _supabase.rpc('admin_support_inbox');
      setState(() { _threads = List<Map<String, dynamic>>.from(r as List); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  String _fmt(DateTime dt) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (diff < 7) return wd[dt.weekday - 1];
    return '${dt.day} ${mo[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final unreadTotal = _threads.fold<int>(0, (s, t) => s + (t['unread_count'] as int? ?? 0));
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(preferredSize: const Size.fromHeight(40),
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            const Text('Inbox', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            if (unreadTotal > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$unreadTotal', style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 18),
                onPressed: _load),
          ]))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _threads.isEmpty
              ? const Center(child: Text('📭  No messages yet',
                  style: TextStyle(color: Colors.white38)))
              : RefreshIndicator(onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _threads.length,
                    itemBuilder: (ctx, i) {
                      final t = _threads[i];
                      final unread = t['unread_count'] as int? ?? 0;
                      final lastAt = t['last_message_at'] != null
                          ? DateTime.tryParse(t['last_message_at'].toString()) : null;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AdminSupportThreadScreen(
                                userId: t['user_id'] as String,
                                userName: t['user_name'] as String? ?? 'Unknown',
                                userEmail: t['user_email'] as String? ?? '')))
                            .then((_) => _load()),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: unread > 0 ? const Color(0xFF2A1A1A) : const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: unread > 0
                                ? const Color(0xFFDC2626).withOpacity(0.4) : Colors.white10)),
                          child: Row(children: [
                            CircleAvatar(radius: 20,
                              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                              child: Text((t['user_name'] as String? ?? '?').characters.first.toUpperCase(),
                                  style: const TextStyle(color: Color(0xFF6C63FF),
                                      fontWeight: FontWeight.bold))),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(t['user_name'] as String? ?? 'Unknown',
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13))),
                                if (lastAt != null) Text(_fmt(lastAt),
                                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ]),
                              const SizedBox(height: 2),
                              Text(t['last_message'] as String? ?? '',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12,
                                      color: unread > 0 ? Colors.white70 : Colors.white38,
                                      fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal)),
                            ])),
                            if (unread > 0) Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626), shape: BoxShape.circle),
                              child: Text('$unread', style: const TextStyle(
                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          ]),
                        ),
                      );
                    })),
    );
  }
}

// ── TEST LAB TAB ──────────────────────────────────────────────────────────────

class _TestLabTab extends StatelessWidget {
  const _TestLabTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const _SectionHead('🧪 Test user-facing screens'),
      const SizedBox(height: 8),
      _LabTile('🎯 Test Onboarding', 'Run full slider quiz — no data saved',
          const Color(0xFF7C3AED), () => context.go('/admin-test-onboarding')),
      _LabTile('🏠 Test Home Screen', 'Preview student home with your account',
          const Color(0xFF059669), () => context.go('/admin-test-home')),
      _LabTile('👁️ View as Any User', 'Pick a user and see their matches/interests',
          const Color(0xFF0891B2), () => context.go('/admin-view-as')),
      _LabTile('🎓 Test Career IQ Quiz', 'Take a quiz as a normal user',
          const Color(0xFFD97706), () => context.go('/career-quiz')),
      _LabTile('🗺️ Test Roadmap', 'View roadmap screen as student',
          const Color(0xFFDB2777), () => context.go('/roadmap')),
      _LabTile('🔍 Test Explore / Courses', 'Browse careers and courses with filters',
          const Color(0xFF4F46E5), () => context.go('/explore')),
      const SizedBox(height: 24),
      const _SectionHead('⚙️ System actions'),
      const SizedBox(height: 8),
      _LabTile('📋 Copy Admin User ID', 'Copy your Supabase UID to clipboard',
          const Color(0xFF6B7280), () async {
            final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
            await Clipboard.setData(ClipboardData(text: uid));
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('UID copied to clipboard')));
          }),
    ],
  );
}

class _LabTile extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _LabTile(this.title, this.subtitle, this.color, this.onTap, [this.emoji = '']);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold, fontSize: 13)),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 14),
      ]),
    ),
  );
}

// ── Re-export screens used internally ────────────────────────────────────────

// These are defined in their own files but referenced here:
// AdminUserProfileView  → admin_view_as_screen.dart
// AdminSupportThreadScreen → admin_support_screen.dart
// Import both at the top of this file in your project:
// import 'package:edupaths/features/admin/screens/admin_view_as_screen.dart';
// import 'package:edupaths/features/admin/screens/admin_support_screen.dart';
