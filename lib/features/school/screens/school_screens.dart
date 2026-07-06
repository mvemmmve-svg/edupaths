// lib/features/school/screens/school_screens.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _sb = Supabase.instance.client;

// Providers
final schoolProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Watch the UID VALUE, not the raw auth event stream — on web the
  // stream fires on every session-restore/token-refresh event, which
  // restarted this load in a loop and left the page on an infinite
  // spinner (especially on desktop browsers with long-lived sessions).
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  try {
    final user = await DbService.getUserByUid(uid)
        .timeout(const Duration(seconds: 12));
    if (user == null) return null;
    final res = await _sb.from('school_advisors')
        .select('id, role, school_id, schools(*)')
        .eq('user_id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 12));
    return res;
  } on Exception {
    // Surface a real error state instead of hanging forever
    rethrow;
  }
});

final cohortsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final school = await ref.watch(schoolProvider.future);
  if (school == null) return [];
  final schoolsMap = school['schools'];
  if (schoolsMap == null) return [];
  final schoolId = (schoolsMap as Map)['id'];
  final res = await _sb.from('school_cohorts')
      .select().eq('school_id', schoolId)
      .order('created_at', ascending: false);
  return (res as List).cast<Map<String, dynamic>>();
});

final studentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, cohortId) async {
    final res = await _sb.from('school_students')
        .select('*, users(full_name, school_year, onboarding_complete)')
        .eq('cohort_id', cohortId).order('student_name');
    return (res as List).cast<Map<String, dynamic>>();
  });

// ══════════════════════════════════════════════
// MAIN ENTRY: routes to setup or dashboard
// ══════════════════════════════════════════════
class SchoolAdvisorScreen extends ConsumerWidget {
  const SchoolAdvisorScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(schoolProvider);
    return schoolAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏫', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          const Text('Couldn\'t load the advisor portal',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Nunito', fontSize: 17,
              fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text('$e', textAlign: TextAlign.center, maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
              color: AppColors.textMid)),
          const SizedBox(height: 16),
          PrimaryBtn(label: 'Try again',
            onPressed: () => ref.invalidate(schoolProvider)),
        ])))),
      data: (school) => school == null
          ? const SchoolSetupScreen()
          : SchoolDashboard(school: school),
    );
  }
}

// ══════════════════════════════════════════════
// SETUP SCREEN — pricing + registration
// ══════════════════════════════════════════════
class SchoolSetupScreen extends ConsumerStatefulWidget {
  const SchoolSetupScreen({super.key});
  @override
  ConsumerState<SchoolSetupScreen> createState() => _SchoolSetupState();
}

class _SchoolSetupState extends ConsumerState<SchoolSetupScreen> {
  int _step = 0;
  String _tier = 'cohort_120';
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPage,
    appBar: AppBar(
      title: const Text('School Advisor Portal'),
      leading: GestureDetector(onTap: () => context.go('/home'), child: const BackBtn())),
    body: _step == 0 ? _buildPricing() : _buildRegister(),
  );

  Widget _buildPricing() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: gradientBox(radius: 16),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("\U0001F3EB School Advisor Portal", style: TextStyle(
            fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900,
            color: Colors.white)),
          SizedBox(height: 8),
          Text('Give every student personalised career guidance. Track their progress '
            'and insights all in one place.', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14, color: Colors.white70, height: 1.4)),
        ])),
      const SizedBox(height: 24),
      const Text('Choose Your Plan', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      _buildPlanCard(
        id: 'cohort_120', name: 'School Cohort Plan', price: '£120/year',
        students: 120, badge: null,
        features: ['Up to 120 students', 'Full career matching', 'Cohort dashboard',
          'CSV student upload', 'Advisor notes', 'Invite code for students', 'Email support']),
      const SizedBox(height: 12),
      _buildPlanCard(
        id: 'cohort_300', name: 'School Premium Plan', price: '£300/year',
        students: 300, badge: '⭐ Best Value',
        features: ['Up to 300 students', 'Multiple year group cohorts',
          'Advanced overview dashboard', 'CSV student upload', 'Advisor notes',
          'Top careers analytics', 'Priority support', 'Export reports']),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(12)),
        child: const Text('💡 14-day free trial included. Payment by invoice — '
          'contact schools@edupaths.co.uk to set up billing.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
            color: AppColors.textMid, height: 1.5))),
      const SizedBox(height: 20),
      PrimaryBtn(label: 'Register Your School →',
        onPressed: () => setState(() => _step = 1)),
      const SizedBox(height: 80),
    ]));

  Widget _buildPlanCard({required String id, required String name,
      required String price, required int students,
      String? badge, required List<String> features}) {
    final sel = _tier == id;
    return GestureDetector(
      onTap: () => setState(() => _tier = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryPale : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.border,
            width: sel ? 2 : 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(name, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 16, fontWeight: FontWeight.w900)),
            const Spacer(),
            if (badge != null) TagBadge(label: badge,
              bg: const Color(0xFFFFF3CD), fg: const Color(0xFF856404)),
          ]),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
          Text('Up to $students students per year',
            style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 13, color: AppColors.textMid)),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded,
                color: AppColors.accentGreen, size: 16),
              const SizedBox(width: 8),
              Text(f, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
            ]))),
        ])));
  }

  Widget _buildRegister() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(onTap: () => setState(() => _step = 0),
        child: const Row(children: [
          Icon(Icons.arrow_back_rounded, size: 18),
          SizedBox(width: 6),
          Text('Back to plans', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
        ])),
      const SizedBox(height: 20),
      const Text('Register Your School', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 20),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10)),
          child: Text(_error!, style: const TextStyle(
            color: AppColors.error, fontFamily: 'Nunito', fontSize: 13)))),
      TextFormField(controller: _nameCtrl,
        decoration: const InputDecoration(
          hintText: 'School name e.g. St Mary Academy',
          prefixIcon: Icon(Icons.school_outlined))),
      const SizedBox(height: 12),
      TextFormField(controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'Contact email',
          prefixIcon: Icon(Icons.mail_outline))),
      const SizedBox(height: 12),
      TextFormField(controller: _postcodeCtrl,
        decoration: const InputDecoration(
          hintText: 'School postcode',
          prefixIcon: Icon(Icons.location_on_outlined))),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(12)),
        child: const Text(
          "What happens next:\n1. School account created immediately\n"
          "2. 14 days free trial starts\n3. We contact you to set up billing\n"
          "4. Membership activates after payment",
          style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
            color: AppColors.textMid, height: 1.5))),
      const SizedBox(height: 20),
      PrimaryBtn(label: 'Create School Account',
        isLoading: _saving, onPressed: _saving ? null : _register),
      const SizedBox(height: 80),
    ]));

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your school name'); return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter a contact email'); return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) throw Exception('Not signed in');
      final user = await DbService.getUserByUid(uid);
      if (user == null) throw Exception('User not found');
      final school = await _sb.from('schools').insert({
        'name': _nameCtrl.text.trim(),
        'contact_email': _emailCtrl.text.trim(),
        'postcode': _postcodeCtrl.text.trim(),
        'membership_tier': _tier,
        'membership_status': 'trial',
        'max_students': _tier == 'cohort_300' ? 300 : 120,
        'membership_expires_at': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
      }).select().single();
      await _sb.from('school_advisors').insert({
        'school_id': school['id'], 'user_id': user.id, 'role': 'admin'});
      await _sb.from('users').update(
        {'role_type': 'advisor', 'school_id': school['id']}).eq('id', user.id);
      if (mounted) {
        ref.invalidate(schoolProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('School account created! 14-day trial started.'),
          backgroundColor: AppColors.success));
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _saving = false; });
    }
  }
}

// ══════════════════════════════════════════════
// DASHBOARD — for registered advisors
// ══════════════════════════════════════════════
class SchoolDashboard extends ConsumerStatefulWidget {
  final Map<String, dynamic> school;
  const SchoolDashboard({super.key, required this.school});
  @override
  ConsumerState<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends ConsumerState<SchoolDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }

  @override
  Widget build(BuildContext context) {
    // Guard: if the joined school record is missing (e.g. row-level
    // security or a broken link), fall back to setup rather than crashing.
    final rawSchool = widget.school['schools'];
    if (rawSchool == null) return const SchoolSetupScreen();
    final schoolData = (rawSchool as Map).cast<String, dynamic>();
    final cohortsAsync = ref.watch(cohortsProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(schoolData['name'] ?? 'School Dashboard',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 15,
              fontWeight: FontWeight.w900)),
          Text('${schoolData['membership_status'] == 'trial' ? 'Free Trial' : 'Active'} · '
            '${schoolData['max_students']} students',
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
              color: AppColors.textMid)),
        ]),
        leading: GestureDetector(onTap: () => context.go('/home'), child: const BackBtn()),
        bottom: TabBar(controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
            fontWeight: FontWeight.w800),
          tabs: const [Tab(text: 'Cohorts'), Tab(text: 'Overview'), Tab(text: 'Settings')]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _CohortsTab(school: schoolData, cohortsAsync: cohortsAsync),
        _OverviewTab(school: schoolData, cohortsAsync: cohortsAsync),
        _SettingsTab(school: schoolData),
      ]),
    );
  }
}

// COHORTS TAB
class _CohortsTab extends ConsumerWidget {
  final Map<String, dynamic> school;
  final AsyncValue<List<Map<String, dynamic>>> cohortsAsync;
  const _CohortsTab({required this.school, required this.cohortsAsync});
  @override
  Widget build(BuildContext context, WidgetRef ref) => cohortsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text('$e')),
    data: (cohorts) => Column(children: [
      Expanded(child: cohorts.isEmpty
          ? const EmptyState(emoji: 'U+1F465', title: 'No cohorts yet',
              subtitle: 'Create your first cohort to add students')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cohorts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = cohorts[i];
                return EduCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProviderScope(
                      parent: ProviderScope.containerOf(context),
                      child: CohortDetailScreen(cohort: c)))),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.group_rounded, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['name'], style: const TextStyle(fontFamily: 'Nunito',
                        fontSize: 14, fontWeight: FontWeight.w800)),
                      Text('${c['year_group'] ?? ''} · Code: ${c['invite_code']}',
                        style: const TextStyle(fontFamily: 'Nunito',
                          fontSize: 12, color: AppColors.textMid)),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                  ]));
              })),
      Padding(padding: const EdgeInsets.all(16),
        child: PrimaryBtn(label: '+ Create Cohort',
          onPressed: () => _showCreate(context, ref))),
    ]),
  );

  void _showCreate(BuildContext ctx, WidgetRef ref) => showModalBottomSheet(
    context: ctx, isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _CreateCohortSheet(
      schoolId: school['id'],
      onCreated: () => ref.invalidate(cohortsProvider)));
}

// OVERVIEW TAB
class _OverviewTab extends ConsumerWidget {
  final Map<String, dynamic> school;
  final AsyncValue<List<Map<String, dynamic>>> cohortsAsync;
  const _OverviewTab({required this.school, required this.cohortsAsync});
  @override
  Widget build(BuildContext context, WidgetRef ref) => cohortsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text('$e')),
    data: (cohorts) => ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(20), decoration: gradientBox(radius: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('School Overview', style: TextStyle(fontFamily: 'Nunito',
            fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(school['name'] ?? '', style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
          Row(children: [
            _Chip('${cohorts.length} Cohorts'),
            const SizedBox(width: 8),
            _Chip('Max ${school['max_students']} students'),
            const SizedBox(width: 8),
            _Chip(school['membership_status'] == 'trial' ? '14-day Trial' : 'Active'),
          ]),
        ])),
      const SizedBox(height: 20),
      const SectionHeader(title: 'Top Career Paths Across School'),
      const SizedBox(height: 12),
      FutureBuilder(
        future: _loadTopCareers(school['id']),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final careers = snap.data as List<Map<String, dynamic>>;
          if (careers.isEmpty) return const Text('No career data yet.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid));
          return Column(children: careers.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EduCard(child: Row(children: [
              Expanded(child: Text(c['career_name'],
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w700))),
              TagBadge(label: '${c['count']} students',
                bg: AppColors.primaryPale, fg: AppColors.primaryDark),
            ])))).toList());
        }),
      const SizedBox(height: 80),
    ]),
  );

  Future<List<Map<String, dynamic>>> _loadTopCareers(String schoolId) async {
    try {
      final students = await _sb.from('school_students')
          .select('user_id').eq('school_id', schoolId);
      final ids = (students as List).where((s) => s['user_id'] != null)
          .map((s) => s['user_id'] as String).toList();
      if (ids.isEmpty) return [];
      final matches = await _sb.from('matches')
          .select('career_id, careers(name)').filter('firebase_uid', 'in', '(${ids.join(",")})')
          .gte('match_score', 70);
      final counts = <String, int>{};
      final names = <String, String>{};
      for (final m in (matches as List)) {
        final id = m['career_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
        names[id] = (m['careers'] as Map)['name'] as String;
      }
      final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(5).map((e) => {'career_name': names[e.key]!, 'count': e.value}).toList();
    } catch (_) { return []; }
  }
}

// SETTINGS TAB
class _SettingsTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> school;
  const _SettingsTab({required this.school});
  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _postcodeCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.school['name'] ?? '');
    _emailCtrl = TextEditingController(text: widget.school['contact_email'] ?? '');
    _postcodeCtrl = TextEditingController(text: widget.school['postcode'] ?? '');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _sb.from('schools').update({
        'name': _nameCtrl.text.trim(),
        'contact_email': _emailCtrl.text.trim(),
        'postcode': _postcodeCtrl.text.trim(),
      }).eq('id', widget.school['id']);
      ref.invalidate(schoolProvider);
      setState(() => _editing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('School details updated!'),
        backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('School Details', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800)),
      TextButton(
        onPressed: () => setState(() => _editing = !_editing),
        child: Text(_editing ? 'Cancel' : '✏️ Edit', style: const TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w800,
          color: AppColors.primary))),
    ]),
    const SizedBox(height: 12),
    if (!_editing) EduCard(child: Column(children: [
      _Row('School', widget.school['name'] ?? 'N/A'),
      const Divider(height: 1),
      _Row('Email', widget.school['contact_email'] ?? 'N/A'),
      const Divider(height: 1),
      _Row('Postcode', widget.school['postcode'] ?? 'N/A'),
      const Divider(height: 1),
      _Row('Plan', widget.school['membership_tier'] == 'cohort_300'
          ? 'Premium Plan — 300 students (£300/yr)'
          : 'Cohort Plan — 120 students (£120/yr)'),
      const Divider(height: 1),
      _Row('Status', widget.school['membership_status'] == 'active'
          ? '✅ Active' : '⏳ Trial (14 days)'),
    ]))
    else Column(children: [
      TextFormField(controller: _nameCtrl,
        decoration: const InputDecoration(hintText: 'School name',
          prefixIcon: Icon(Icons.school_outlined))),
      const SizedBox(height: 10),
      TextFormField(controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(hintText: 'Contact email',
          prefixIcon: Icon(Icons.mail_outline))),
      const SizedBox(height: 10),
      TextFormField(controller: _postcodeCtrl,
        decoration: const InputDecoration(hintText: 'Postcode',
          prefixIcon: Icon(Icons.location_on_outlined))),
      const SizedBox(height: 16),
      PrimaryBtn(label: 'Save Changes', isLoading: _saving,
        onPressed: _saving ? null : _save),
    ]),
    const SizedBox(height: 20),
    const SectionHeader(title: 'Membership'),
    const SizedBox(height: 12),
    EduCard(child: Column(children: [
      _Row('Current Plan', widget.school['membership_tier'] == 'cohort_300'
          ? 'School Premium Plan' : 'School Cohort Plan'),
      const Divider(height: 1),
      _Row('Max Students', '${widget.school['max_students'] ?? 120}'),
      const Divider(height: 1),
      _Row('Status', widget.school['membership_status'] ?? 'trial'),
    ])),
    const SizedBox(height: 12),
    EduCard(child: Padding(
      padding: const EdgeInsets.all(4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Need to upgrade or manage billing?',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Contact schools@edupaths.co.uk or billing@edupaths.co.uk',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
      ]))),
    const SizedBox(height: 20),
    const SectionHeader(title: 'Support'),
    const SizedBox(height: 12),
    EduCard(child: Column(children: [
      _Row('School Support', 'schools@edupaths.co.uk'),
      const Divider(height: 1),
      _Row('Technical', 'support@edupaths.co.uk'),
      const Divider(height: 1),
      _Row('Billing', 'billing@edupaths.co.uk'),
    ])),
    const SizedBox(height: 80),
  ]);
}

// ══════════════════════════════════════════════
// COHORT DETAIL SCREEN
// ══════════════════════════════════════════════
class CohortDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> cohort;
  const CohortDetailScreen({super.key, required this.cohort});
  @override
  ConsumerState<CohortDetailScreen> createState() => _CohortDetailState();
}

class _CohortDetailState extends ConsumerState<CohortDetailScreen> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider(widget.cohort['id'] as String));
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(widget.cohort['name'], style: const TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        leading: GestureDetector(onTap: () => Navigator.pop(context), child: const BackBtn()),
        actions: [
          IconButton(icon: const Icon(Icons.upload_file_rounded),
            onPressed: () => _showUpload(context)),
          IconButton(icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAdd(context)),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (students) {
          final active = students.where((s) =>
              s['users']?['onboarding_complete'] == true).length;
          final filtered = students.where((s) => _search.isEmpty ||
              (s['student_name'] as String).toLowerCase()
                  .contains(_search.toLowerCase())).toList();
          return Column(children: [
            Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
              decoration: gradientBox(radius: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _StatItem('Total', '${students.length}'),
                _StatItem('Active', '$active'),
                _StatItem('Invited', '${students.length - active}'),
                _StatItem('Code', widget.cohort['invite_code']),
              ])),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20)))),
            const SizedBox(height: 8),
            Expanded(child: filtered.isEmpty
                ? const EmptyState(emoji: 'U+1F464', title: 'No students yet',
                    subtitle: 'Upload CSV or add manually')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = filtered[i];
                      final hasAccount = s['user_id'] != null;
                      final done = s['users']?['onboarding_complete'] == true;
                      return EduCard(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProviderScope(
                            parent: ProviderScope.containerOf(context),
                            child: StudentDetailScreen(student: s)))),
                        child: Row(children: [
                          CircleAvatar(radius: 18,
                            backgroundColor: done ? AppColors.accentGreen.withOpacity(0.15)
                                : AppColors.bgGrey,
                            child: Text((s['student_name'] as String)[0].toUpperCase(),
                              style: TextStyle(fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                color: done ? AppColors.accentGreen : AppColors.textLight))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s['student_name'], style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700)),
                            Text(s['year_group'] ?? '', style: const TextStyle(
                              fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
                          ])),
                          TagBadge(
                            label: done ? 'Done' : hasAccount ? 'Started' : 'Invited',
                            bg: done ? const Color(0xFFECFDF5)
                                : hasAccount ? AppColors.primaryPale : AppColors.bgGrey,
                            fg: done ? const Color(0xFF065F46)
                                : hasAccount ? AppColors.primary : AppColors.textLight),
                          const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textLight, size: 18),
                        ]));
                    })),
          ]);
        }));
  }
  void _showUpload(BuildContext ctx) => showModalBottomSheet(
    context: ctx, isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => UploadStudentsSheet(
      cohortId: widget.cohort['id'], schoolId: widget.cohort['school_id'],
      onUploaded: () => ref.invalidate(studentsProvider(widget.cohort['id']))));
  void _showAdd(BuildContext ctx) => showModalBottomSheet(
    context: ctx, isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => AddStudentSheet(
      cohortId: widget.cohort['id'], schoolId: widget.cohort['school_id'],
      onAdded: () => ref.invalidate(studentsProvider(widget.cohort['id']))));
}

// ══════════════════════════════════════════════
// STUDENT DETAIL SCREEN
// ══════════════════════════════════════════════
class StudentDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> student;
  const StudentDetailScreen({super.key, required this.student});
  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailState();
}

class _StudentDetailState extends ConsumerState<StudentDetailScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _matches = [];
  final _noteCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final user = await DbService.getUserByUid(uid);
      if (user != null) {
        final adv = await _sb.from('school_advisors')
            .select('id').eq('user_id', user.id).maybeSingle();
        if (adv != null) {
          final n = await _sb.from('advisor_notes').select()
              .eq('student_id', widget.student['id'])
              .eq('advisor_id', adv['id'])
              .order('created_at', ascending: false);
          _notes = (n as List).cast<Map<String, dynamic>>();
        }
      }
      final userId = widget.student['user_id'] as String?;
      if (userId != null) {
        final m = await _sb.from('matches')
            .select('match_score, careers(name)')
            .eq('firebase_uid', userId)
            .order('match_score', ascending: false).limit(5);
        _matches = (m as List).map((e) => {
          'score': e['match_score'],
          'career': (e['careers'] as Map)['name'],
        }).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveNote() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final uid = _sb.auth.currentUser?.id;
      final user = await DbService.getUserByUid(uid!);
      final adv = await _sb.from('school_advisors')
          .select('id').eq('user_id', user!.id).maybeSingle();
      if (adv == null) return;
      await _sb.from('advisor_notes').insert({
        'advisor_id': adv['id'],
        'student_id': widget.student['id'],
        'note': _noteCtrl.text.trim(),
        'is_private': true,
      });
      _noteCtrl.clear();
      await _load();
    } finally { if (mounted) setState(() => _saving = false); }
  }

  String _fmt(String? s) {
    if (s == null) return '';
    final d = DateTime.tryParse(s); if (d == null) return '';
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['student_name'] as String;
    final done = widget.student['users']?['onboarding_complete'] == true;
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: Text(name, style: const TextStyle(
        fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        leading: GestureDetector(onTap: () => Navigator.pop(context), child: const BackBtn())),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        EduCard(color: AppColors.primaryPale, child: Row(children: [
          CircleAvatar(radius: 28, backgroundColor: AppColors.primary,
            child: Text(name[0].toUpperCase(), style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 16, fontWeight: FontWeight.w900)),
            Text(widget.student['year_group'] ?? '', style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid)),
            const SizedBox(height: 4),
            TagBadge(label: done ? 'Profile Complete' : 'Pending',
              bg: done ? const Color(0xFFECFDF5) : AppColors.bgCard,
              fg: done ? const Color(0xFF065F46) : AppColors.textMid),
          ])),
        ])),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Career Matches'),
        const SizedBox(height: 10),
        if (!done)
          const Text('Student has not completed their profile yet.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
              color: AppColors.textMid))
        else if (_matches.isEmpty)
          const Text('No matches yet.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid))
        else ..._matches.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EduCard(child: Row(children: [
            MatchRing(pct: m['score'] as int, size: 36),
            const SizedBox(width: 12),
            Text(m['career'] as String, style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700)),
          ])))),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Advisor Notes'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _noteCtrl, maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Add a note about this student...',
              contentPadding: EdgeInsets.all(12)))),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _saving ? null : _saveNote,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(56, 56), padding: EdgeInsets.zero),
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded)),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_notes.isEmpty)
          const Text('No notes yet.', style: TextStyle(fontFamily: 'Nunito',
            fontSize: 13, color: AppColors.textLight))
        else ..._notes.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EduCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n['note'], style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
            const SizedBox(height: 4),
            Text(_fmt(n['created_at']), style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 11, color: AppColors.textLight)),
          ])))),
        const SizedBox(height: 80),
      ])),
    );
  }
}

// ══════════════════════════════════════════════
// UPLOAD STUDENTS SHEET
// ══════════════════════════════════════════════
class UploadStudentsSheet extends ConsumerStatefulWidget {
  final String cohortId, schoolId;
  final VoidCallback onUploaded;
  const UploadStudentsSheet({super.key,
    required this.cohortId, required this.schoolId, required this.onUploaded});
  @override
  ConsumerState<UploadStudentsSheet> createState() => _UploadState();
}

class _UploadState extends ConsumerState<UploadStudentsSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, String>> _preview = [];
  bool _saving = false;
  String? _error;

  void _parse() {
    final lines = _ctrl.text.trim().split('\n');
    final results = <Map<String, String>>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = _splitCsvLine(line);
      if (parts.isEmpty || parts[0].isEmpty) continue;
      if (parts[0].toLowerCase() == 'name') continue;
      // Find the email field wherever it lands, so a "Surname, First"
      // export with a stray comma doesn't shift the columns.
      final emailIdx =
          parts.indexWhere((p) => p.contains('@') && p.contains('.'));
      String name, email = '', year = '';
      if (emailIdx > 0) {
        name = parts.sublist(0, emailIdx).join(' ')
            .replaceAll(RegExp(r'\s+'), ' ').trim();
        email = parts[emailIdx];
        year = parts.length > emailIdx + 1 ? parts[emailIdx + 1] : '';
      } else {
        name = parts[0];
        email = parts.length > 1 ? parts[1] : '';
        year = parts.length > 2 ? parts[2] : '';
      }
      results.add({'name': name, 'email': email, 'year': year});
    }
    setState(() { _preview = results; _error = results.isEmpty ? 'No valid data found' : null; });
  }

  /// Splits a CSV line but respects "double quotes", so "Smith, John"
  /// stays one field instead of splitting on the comma inside it.
  List<String> _splitCsvLine(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        out.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    out.add(buf.toString().trim());
    return out;
  }

  Future<void> _upload() async {
    if (_preview.isEmpty) return;
    setState(() => _saving = true);
    try {
      // Skip anyone already on this cohort's list (matched by email) so
      // re-pasting the same CSV doesn't create duplicates.
      final existing = await _sb.from('school_students')
          .select('student_email').eq('cohort_id', widget.cohortId);
      final seen = (existing as List)
          .map((e) => (e['student_email'] ?? '').toString().toLowerCase())
          .where((e) => e.isNotEmpty).toSet();
      final toInsert = _preview.where((s) {
        final e = (s['email'] ?? '').toLowerCase();
        return e.isEmpty || !seen.contains(e);
      }).toList();
      final skipped = _preview.length - toInsert.length;
      if (toInsert.isEmpty) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Everyone on this list is already in the cohort.')));
        }
        return;
      }
      await _sb.from('school_students').insert(toInsert.map((s) => {
        'cohort_id': widget.cohortId, 'school_id': widget.schoolId,
        'student_name': s['name'], 'student_email': s['email'],
        'year_group': s['year'], 'status': 'invited',
      }).toList());
      if (mounted) {
        Navigator.pop(context);
        widget.onUploaded();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${toInsert.length} students uploaded!'
            '${skipped > 0 ? ' ($skipped already existed, skipped)' : ''}'),
          backgroundColor: AppColors.success));
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 20, right: 20, top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Upload Students via CSV', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text('Format: Name, Email, Year Group\nExample: John Smith, john@school.ac.uk, Year 11',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid)),
      const SizedBox(height: 12),
      TextFormField(controller: _ctrl, maxLines: 8,
        style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        decoration: const InputDecoration(hintText: 'Paste CSV here...',
          contentPadding: EdgeInsets.all(12))),
      const SizedBox(height: 8),
      if (_error != null) Text(_error!, style: const TextStyle(
        color: AppColors.error, fontFamily: 'Nunito', fontSize: 12)),
      if (_preview.isNotEmpty) Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10)),
        child: Text('${_preview.length} students ready',
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w700, color: Color(0xFF065F46)))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlineBtn(label: 'Preview', onPressed: _parse)),
        const SizedBox(width: 10),
        Expanded(child: PrimaryBtn(label: 'Upload',
          onPressed: _preview.isEmpty || _saving ? null : _upload,
          isLoading: _saving)),
      ]),
    ]));
}

// ══════════════════════════════════════════════
// ADD STUDENT SHEET
// ══════════════════════════════════════════════
class AddStudentSheet extends ConsumerStatefulWidget {
  final String cohortId, schoolId;
  final VoidCallback onAdded;
  const AddStudentSheet({super.key,
    required this.cohortId, required this.schoolId, required this.onAdded});
  @override
  ConsumerState<AddStudentSheet> createState() => _AddState();
}

class _AddState extends ConsumerState<AddStudentSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _year;
  bool _saving = false;
  static const _years = ['Year 9','Year 10','Year 11','Year 12','Year 13'];
  Future<void> _add() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _sb.from('school_students').insert({
        'cohort_id': widget.cohortId, 'school_id': widget.schoolId,
        'student_name': _nameCtrl.text.trim(),
        'student_email': _emailCtrl.text.trim(),
        'year_group': _year, 'status': 'invited'});
      if (mounted) { Navigator.pop(context); widget.onAdded(); }
    } finally { if (mounted) setState(() => _saving = false); }
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 20, right: 20, top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Add Student', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      TextFormField(controller: _nameCtrl,
        decoration: const InputDecoration(hintText: 'Student name',
          prefixIcon: Icon(Icons.person_outline))),
      const SizedBox(height: 10),
      TextFormField(controller: _emailCtrl,
        decoration: const InputDecoration(hintText: 'Email (optional)',
          prefixIcon: Icon(Icons.mail_outline))),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _year,
        hint: const Text('Year Group'),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
        items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
        onChanged: (v) => setState(() => _year = v)),
      const SizedBox(height: 16),
      PrimaryBtn(label: 'Add Student',
        onPressed: _saving ? null : _add, isLoading: _saving),
    ]));
}

// ══════════════════════════════════════════════
// CREATE COHORT SHEET
// ══════════════════════════════════════════════
class _CreateCohortSheet extends ConsumerStatefulWidget {
  final String schoolId;
  final VoidCallback onCreated;
  const _CreateCohortSheet({required this.schoolId, required this.onCreated});
  @override
  ConsumerState<_CreateCohortSheet> createState() => _CreateCohortState();
}

class _CreateCohortState extends ConsumerState<_CreateCohortSheet> {
  final _nameCtrl = TextEditingController();
  String? _year;
  String _ay = '2025/26';
  bool _saving = false;
  static const _years = ['Year 9','Year 10','Year 11','Year 12','Year 13','Mixed'];
  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _sb.from('school_cohorts').insert({
        'school_id': widget.schoolId, 'name': _nameCtrl.text.trim(),
        'year_group': _year, 'academic_year': _ay});
      if (mounted) { Navigator.pop(context); widget.onCreated(); }
    } finally { if (mounted) setState(() => _saving = false); }
  }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 20, right: 20, top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Create Cohort', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      TextFormField(controller: _nameCtrl,
        decoration: const InputDecoration(hintText: 'e.g. Year 11 - 2025/26',
          prefixIcon: Icon(Icons.group_rounded))),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _year, hint: const Text('Year Group'),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.school_outlined)),
        items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
        onChanged: (v) => setState(() => _year = v)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _ay,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined)),
        items: ['2024/25','2025/26','2026/27'].map((y) =>
          DropdownMenuItem(value: y, child: Text(y))).toList(),
        onChanged: (v) => setState(() => _ay = v!)),
      const SizedBox(height: 16),
      PrimaryBtn(label: 'Create Cohort',
        onPressed: _saving ? null : _create, isLoading: _saving),
    ]));
}

// Helpers
class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: const TextStyle(fontFamily: 'Nunito',
      fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)));
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontFamily: 'Nunito',
      fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
    Text(label, style: const TextStyle(fontFamily: 'Nunito',
      fontSize: 10, color: Colors.white70)),
  ]);
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Text(label, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 13, color: AppColors.textMid)),
      const Spacer(),
      Text(value, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 13, fontWeight: FontWeight.w700)),
    ]));
}
