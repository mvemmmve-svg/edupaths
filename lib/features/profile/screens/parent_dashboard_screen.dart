import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final meRes = await _supabase
          .from('users')
          .select('id')
          .eq('supabase_uid', user.id)
          .single();
      final parentId = meRes['id'];
      final res = await _supabase
          .from('parent_child')
          .select('child_id, users!parent_child_child_id_fkey(id, name, school_year, supabase_uid)')
          .eq('parent_id', parentId);
      setState(() {
        _children = List<Map<String, dynamic>>.from(res);
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FE9)),
            child: const Text('Sign out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _supabase.auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () {
            // Safe back navigation — go to home if no previous route
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(
              color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF5B4FE9)),
            tooltip: 'Home',
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFAA3333)),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? _buildNoChildren()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Your Children',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 12),
                    ..._children.map((c) {
                      final child = c['users'] as Map<String, dynamic>? ?? {};
                      return _ChildCard(
                        child: child,
                        onTap: () => _showChildDetail(child),
                      );
                    }),
                  ],
                ),
    );
  }

  Widget _buildNoChildren() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom,
                size: 64, color: Color(0xFF5B4FE9)),
            const SizedBox(height: 16),
            const Text(
              'No children linked yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your child to share their profile link with you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888AAA)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChildDetail(Map<String, dynamic> child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChildDetailScreen(child: child),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onTap;

  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = child['name'] ?? 'Student';
    final year = child['school_year'] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5B4FE9),
          radius: 24,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
        title: Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        subtitle: Text(year,
            style: const TextStyle(color: Color(0xFF888AAA))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF5B4FE9)),
        onTap: onTap,
      ),
    );
  }
}

// ─── Child detail screen ──────────────────────────────────────────────────────

class _ChildDetailScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  const _ChildDetailScreen({required this.child});

  @override
  State<_ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<_ChildDetailScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final uid = widget.child['supabase_uid']?.toString() ?? '';
      if (uid.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final res = await _supabase
          .from('matches')
          .select('match_score, match_reason, careers(id, name, description, avg_salary, salary_min, salary_max, category)')
          .eq('firebase_uid', uid)
          .order('match_score', ascending: false)
          .limit(10);
      setState(() {
        _matches = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.child['name'] ?? 'Student';
    final year = widget.child['school_year'] ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => context.pop(),
        ),
        title: Text(name,
            style: const TextStyle(
                color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4FE9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 28,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text(year,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Career Matches',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap a career to see universities, apprenticeships and more.',
                  style: TextStyle(color: Color(0xFF888AAA), fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_matches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No career matches yet. Ask your child to complete their profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF888AAA)),
                    ),
                  )
                else
                  ..._matches.map((m) {
                    final career = m['careers'] as Map<String, dynamic>? ?? {};
                    final score = m['match_score'] as int? ?? 0;
                    final reason = m['match_reason'] as String? ?? '';
                    return _CareerMatchTile(
                      career: career,
                      score: score,
                      reason: reason,
                    );
                  }),
              ],
            ),
    );
  }
}

// ─── Career match tile with popup ────────────────────────────────────────────

class _CareerMatchTile extends StatelessWidget {
  final Map<String, dynamic> career;
  final int score;
  final String reason;

  const _CareerMatchTile({
    required this.career,
    required this.score,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final name = career['name'] ?? 'Career';
    final salary = career['avg_salary'] ?? '';
    final category = career['category'] ?? '';

    Color scoreColor = score >= 80
        ? Colors.green
        : score >= 60
            ? const Color(0xFF5B4FE9)
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showCareerInsight(context, career, score, reason),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                      strokeWidth: 4,
                    ),
                    Text(
                      '$score%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scoreColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E))),
                    if (salary.isNotEmpty)
                      Text(salary,
                          style: const TextStyle(
                              color: Color(0xFF888AAA), fontSize: 12)),
                    if (category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEECFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(category,
                            style: const TextStyle(
                                color: Color(0xFF5B4FE9), fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.info_outline,
                  color: Color(0xFF5B4FE9), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCareerInsight(
    BuildContext context,
    Map<String, dynamic> career,
    int score,
    String reason,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CareerInsightSheet(
        career: career,
        score: score,
        reason: reason,
      ),
    );
  }
}

// ─── Career insight bottom sheet with courses ─────────────────────────────────

class _CareerInsightSheet extends StatefulWidget {
  final Map<String, dynamic> career;
  final int score;
  final String reason;

  const _CareerInsightSheet({
    required this.career,
    required this.score,
    required this.reason,
  });

  @override
  State<_CareerInsightSheet> createState() => _CareerInsightSheetState();
}

class _CareerInsightSheetState extends State<_CareerInsightSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _uniCourses = [];
  List<Map<String, dynamic>> _apprenticeships = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final careerId = widget.career['id']?.toString() ?? '';
      if (careerId.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final res = await _supabase
          .from('career_course')
          .select('courses(id, title, institution, course_type, duration, entry_requirements, url)')
          .eq('career_id', careerId)
          .limit(20);

      final allCourses = (res as List)
          .map((r) => r['courses'] as Map<String, dynamic>? ?? {})
          .where((c) => c.isNotEmpty)
          .toList();

      setState(() {
        _uniCourses = allCourses
            .where((c) =>
                (c['course_type'] ?? '').toString().toLowerCase() ==
                'university')
            .toList();
        _apprenticeships = allCourses
            .where((c) =>
                (c['course_type'] ?? '').toString().toLowerCase() ==
                    'apprenticeship' ||
                (c['course_type'] ?? '').toString().toLowerCase() ==
                    'Apprenticeship')
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.career['name'] ?? 'Career';
    final desc = widget.career['description'] ?? '';
    final salary = widget.career['avg_salary'] ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4FE9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.score}% match',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (salary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '💰 $salary',
                      style: const TextStyle(
                          color: Color(0xFF5B4FE9),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (widget.reason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEECFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Color(0xFF5B4FE9), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.reason,
                              style: const TextStyle(
                                  color: Color(0xFF5B4FE9), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: const TextStyle(
                          color: Color(0xFF555577), fontSize: 13, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Tabs
                  TabBar(
                    controller: _tab,
                    labelColor: const Color(0xFF5B4FE9),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF5B4FE9),
                    tabs: [
                      Tab(
                          text:
                              '🎓 University (${_loading ? '…' : _uniCourses.length})'),
                      Tab(
                          text:
                              '🔧 Apprenticeships (${_loading ? '…' : _apprenticeships.length})'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tab content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _CourseList(courses: _uniCourses, type: 'university'),
                        _CourseList(
                            courses: _apprenticeships,
                            type: 'apprenticeship'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final String type;

  const _CourseList({required this.courses, required this.type});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == 'university' ? Icons.school_outlined : Icons.work_outline,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                type == 'university'
                    ? 'No university courses linked yet'
                    : 'No apprenticeships linked yet',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Color(0xFF888AAA), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (_, i) {
        final c = courses[i];
        final title = c['title'] ?? 'Course';
        final institution = c['institution'] ?? '';
        final duration = c['duration'] ?? '';
        final entry = c['entry_requirements'] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                if (institution.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF888AAA)),
                      const SizedBox(width: 4),
                      Text(institution,
                          style: const TextStyle(
                              color: Color(0xFF888AAA), fontSize: 12)),
                    ],
                  ),
                ],
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 14, color: Color(0xFF888AAA)),
                      const SizedBox(width: 4),
                      Text(duration,
                          style: const TextStyle(
                              color: Color(0xFF888AAA), fontSize: 12)),
                    ],
                  ),
                ],
                if (entry.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📋 ',
                            style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            'Entry: $entry',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF885500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
