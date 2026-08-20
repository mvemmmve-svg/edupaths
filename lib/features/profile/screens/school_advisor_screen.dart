import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class SchoolAdvisorScreen extends StatefulWidget {
  const SchoolAdvisorScreen({super.key});

  @override
  State<SchoolAdvisorScreen> createState() => _SchoolAdvisorScreenState();
}

class _SchoolAdvisorScreenState extends State<SchoolAdvisorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  Map<String, dynamic>? _school;
  List<Map<String, dynamic>> _cohorts = [];
  List<Map<String, dynamic>> _careerOverview = [];
  String _tier = 'free'; // free | cohort | premium

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get advisor's school
      final advisorRes = await _supabase
          .from('school_advisors')
          .select('school_id, schools(id, name, invite_code)')
          .eq('user_id',
              (await _supabase.from('users').select('id').eq('supabase_uid', user.id).single())['id'])
          .maybeSingle();

      if (advisorRes == null) {
        setState(() => _loading = false);
        return;
      }

      final school = advisorRes['schools'] as Map<String, dynamic>? ?? {};
      final schoolId = school['id']?.toString() ?? '';

      // Check subscription tier
      final tierRes = await _supabase
          .from('school_membership_tiers')
          .select('tier')
          .eq('school_id', schoolId)
          .maybeSingle();
      final tier = tierRes?['tier']?.toString() ?? 'free';

      // Get cohorts
      final cohortsRes = await _supabase
          .from('school_cohorts')
          .select('id, name, year_group')
          .eq('school_id', schoolId);

      // Get career overview (uses our new RPC)
      List<Map<String, dynamic>> careerData = [];
      try {
        final overviewRes = await _supabase
            .rpc('school_career_overview', params: {'p_school_id': schoolId});
        careerData = List<Map<String, dynamic>>.from(overviewRes);
      } catch (_) {}

      setState(() {
        _school = school;
        _cohorts = List<Map<String, dynamic>>.from(cohortsRes);
        _careerOverview = careerData;
        _tier = tier;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('School Advisor Portal',
            style: TextStyle(
                color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF5B4FE9)),
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF5B4FE9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF5B4FE9),
          tabs: const [Tab(text: 'Cohorts'), Tab(text: 'Overview')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _school == null
              ? _buildNoSchool()
              : TabBarView(
                  controller: _tab,
                  children: [
                    _CohortsTab(
                      school: _school!,
                      cohorts: _cohorts,
                      tier: _tier,
                    ),
                    _OverviewTab(
                      school: _school!,
                      careerData: _careerOverview,
                      tier: _tier,
                    ),
                  ],
                ),
    );
  }

  Widget _buildNoSchool() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: Color(0xFF5B4FE9)),
            const SizedBox(height: 16),
            const Text(
              'No school linked',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contact EduPaths to set up your school account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888AAA)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FE9),
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cohorts tab ──────────────────────────────────────────────────────────────

class _CohortsTab extends StatelessWidget {
  final Map<String, dynamic> school;
  final List<Map<String, dynamic>> cohorts;
  final String tier;

  const _CohortsTab(
      {required this.school, required this.cohorts, required this.tier});

  @override
  Widget build(BuildContext context) {
    final isPremium = tier == 'premium';
    final maxCohorts = isPremium ? 999 : 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Subscription banner
        _TierBanner(tier: tier),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Class Groups',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const Spacer(),
            if (cohorts.length < maxCohorts)
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5B4FE9)),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Upgrade for more',
                  style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (cohorts.isEmpty)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.group_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No class groups yet',
                      style: TextStyle(color: Color(0xFF888AAA))),
                ],
              ),
            ),
          )
        else
          ...cohorts.map((c) => _CohortCard(cohort: c, school: school)),
        const SizedBox(height: 24),
        // Invite code
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student Invite Code',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        school['invite_code'] ?? '—',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Color(0xFF5B4FE9)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF5B4FE9)),
                        onPressed: () {},
                        tooltip: 'Copy code',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this code with students — they enter it in the app under Profile → Join your school.',
                  style: TextStyle(color: Color(0xFF888AAA), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CohortCard extends StatelessWidget {
  final Map<String, dynamic> cohort;
  final Map<String, dynamic> school;

  const _CohortCard({required this.cohort, required this.school});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _CohortStudentsScreen(
              cohort: cohort,
              school: school,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEECFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group, color: Color(0xFF5B4FE9)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cohort['name'] ?? 'Class',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                    Text(cohort['year_group'] ?? '',
                        style: const TextStyle(
                            color: Color(0xFF888AAA), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF5B4FE9)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> school;
  final List<Map<String, dynamic>> careerData;
  final String tier;

  const _OverviewTab(
      {required this.school, required this.careerData, required this.tier});

  @override
  Widget build(BuildContext context) {
    final isPremium = tier == 'premium';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // School card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B4FE9), Color(0xFF8B7FF5)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('School Overview',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                school['name'] ?? 'School',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(label: tier == 'premium' ? 'Premium' : tier == 'cohort' ? '1 Cohort Plan' : 'Free Trial'),
                  const SizedBox(width: 8),
                  _InfoChip(label: isPremium ? 'Max 300 students' : 'Max 120 students'),
                  const SizedBox(width: 8),
                  if (tier == 'free') const _InfoChip(label: '14-day Trial'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Top Career Paths Across School',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        const Text(
          "Based on students' top career matches",
          style: TextStyle(color: Color(0xFF888AAA), fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (careerData.isEmpty)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Career data will appear here once students complete their profiles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF888AAA)),
                  ),
                ],
              ),
            ),
          )
        else
          ...careerData.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            final count = d['student_count'] as int? ?? 0;
            final maxCount = (careerData.first['student_count'] as int?) ?? 1;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? const Color(0xFFFFD700)
                            : i == 1
                                ? Colors.grey.shade300
                                : const Color(0xFFCD7F32),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['career_name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: count / maxCount,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF5B4FE9)),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$count student${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Color(0xFF888AAA), fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (!isPremium) ...[
          const SizedBox(height: 20),
          Card(
            color: const Color(0xFFFFF8EC),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('⭐ ', style: TextStyle(fontSize: 18)),
                      Text('Unlock Premium Analytics',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF885500))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Multiple class group cohorts\n• Advanced overview dashboard\n• Export reports\n• Top careers analytics by year group\n• Priority support',
                    style: TextStyle(color: Color(0xFF885500), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/pricing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4FE9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Plans'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

// ─── Cohort students screen ───────────────────────────────────────────────────

class _CohortStudentsScreen extends StatefulWidget {
  final Map<String, dynamic> cohort;
  final Map<String, dynamic> school;

  const _CohortStudentsScreen(
      {required this.cohort, required this.school});

  @override
  State<_CohortStudentsScreen> createState() => _CohortStudentsScreenState();
}

class _CohortStudentsScreenState extends State<_CohortStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _supabase
          .from('school_students')
          .select('id, student_name, year_group, status, user_id, users(id, name, supabase_uid)')
          .eq('cohort_id', widget.cohort['id'])
          .order('student_name');
      setState(() {
        _students = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.cohort['name'] ?? 'Class',
          style: const TextStyle(
              color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${_students.length} students',
                  style: const TextStyle(
                      color: Color(0xFF888AAA), fontSize: 13),
                ),
                const SizedBox(height: 12),
                ..._students.map((s) {
                  final name = s['student_name'] ?? 'Student';
                  final user = s['users'] as Map<String, dynamic>?;
                  // Status: if user_id is set AND status = 'active' → Joined
                  // If user_id set but status ≠ 'active' → Pending
                  // If no user_id → Not joined
                  final hasUser = s['user_id'] != null && user != null;
                  final rawStatus = s['status']?.toString() ?? '';
                  final isActive = rawStatus == 'active';
                  final displayStatus = !hasUser
                      ? 'Not joined'
                      : isActive
                          ? 'Joined'
                          : 'Pending';
                  final statusColor = !hasUser
                      ? Colors.grey
                      : isActive
                          ? Colors.green
                          : Colors.orange;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: hasUser && isActive
                            ? const Color(0xFF5B4FE9)
                            : Colors.grey.shade200,
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                              color: hasUser && isActive
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                      subtitle: Text(s['year_group'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      onTap: hasUser && isActive
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _StudentDetailScreen(
                                    student: s,
                                    user: user!,
                                  ),
                                ),
                              )
                          : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

// ─── Student detail screen (advisor view) ─────────────────────────────────────

class _StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic> user;

  const _StudentDetailScreen(
      {required this.student, required this.user});

  @override
  State<_StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<_StudentDetailScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _supabase.rpc('advisor_student_matches',
          params: {'p_roster_id': widget.student['id']});
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
    final name = widget.student['student_name'] ?? 'Student';
    final email = widget.user['name'] ?? '';
    final year = widget.student['year_group'] ?? '';

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF5B4FE9),
                        radius: 24,
                        child: Text(name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A2E))),
                          Text(year,
                              style: const TextStyle(
                                  color: Color(0xFF888AAA))),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Text('Joined',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Top Career Matches',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_matches.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No matches yet — student needs to complete their profile.',
                  style: TextStyle(color: Color(0xFF888AAA)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._matches.map((m) {
              final score = m['match_score'] as int? ?? 0;
              final careerName = m['career_name'] as String? ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF5B4FE9)),
                          strokeWidth: 4,
                        ),
                        Text('$score%',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B4FE9))),
                      ],
                    ),
                  ),
                  title: Text(careerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Tier banner ──────────────────────────────────────────────────────────────

class _TierBanner extends StatelessWidget {
  final String tier;
  const _TierBanner({required this.tier});

  @override
  Widget build(BuildContext context) {
    if (tier == 'premium') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tier == 'free'
            ? Colors.amber.shade50
            : const Color(0xFFEEECFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: tier == 'free'
                ? Colors.amber.shade200
                : const Color(0xFF5B4FE9).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            tier == 'free' ? Icons.info_outline : Icons.star_outline,
            color: tier == 'free'
                ? Colors.amber.shade700
                : const Color(0xFF5B4FE9),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tier == 'free'
                  ? '14-day free trial active. Upgrade to keep access.'
                  : 'Cohort Plan — upgrade to Premium for multiple year groups.',
              style: TextStyle(
                  color: tier == 'free'
                      ? Colors.amber.shade800
                      : const Color(0xFF5B4FE9),
                  fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/pricing'),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
