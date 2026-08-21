import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class RoadmapPlanScreen extends StatefulWidget {
  const RoadmapPlanScreen({super.key});
  @override
  State<RoadmapPlanScreen> createState() => _RoadmapPlanScreenState();
}

class _RoadmapPlanScreenState extends State<RoadmapPlanScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _allMatches = [];   // all matches for selector
  int _selectedIndex = 0;                         // which career is selected
  List<Map<String, dynamic>> _roadmapSteps = [];
  List<Map<String, dynamic>> _qualifications = [];
  bool _loadingRoadmap = false;

  Map<String, dynamic>? get _currentCareer {
    if (_allMatches.isEmpty) return null;
    return _allMatches[_selectedIndex]['careers'] as Map<String, dynamic>?;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) { setState(() => _loading = false); return; }

      // Load ALL matches so user can switch between them
      final matchRes = await _supabase
          .from('matches')
          .select('career_id, match_score, careers(id, name, description, avg_salary, category)')
          .eq('firebase_uid', user.id)
          .order('match_score', ascending: false)
          .limit(10);

      final matches = List<Map<String, dynamic>>.from(matchRes as List);

      setState(() {
        _allMatches = matches;
        _loading = false;
      });

      if (matches.isNotEmpty) {
        await _loadRoadmapForIndex(0);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRoadmapForIndex(int index) async {
    if (index < 0 || index >= _allMatches.length) return;
    setState(() => _loadingRoadmap = true);

    final career = _allMatches[index]['careers'] as Map<String, dynamic>? ?? {};
    final careerId = career['id']?.toString() ?? '';

    List<Map<String, dynamic>> quals = [];
    if (careerId.isNotEmpty) {
      try {
        final qualRes = await _supabase
            .from('career_preclass')
            .select('preclass(id, title, level, type)')
            .eq('career_id', careerId);
        quals = (qualRes as List)
            .map((r) => r['preclass'] as Map<String, dynamic>? ?? {})
            .where((q) => q.isNotEmpty)
            .toList();
      } catch (_) {}
    }

    final steps = _buildRoadmapSteps(quals, career);

    setState(() {
      _selectedIndex = index;
      _roadmapSteps = steps;
      _qualifications = quals;
      _loadingRoadmap = false;
    });
  }

  List<Map<String, dynamic>> _buildRoadmapSteps(
    List<Map<String, dynamic>> quals,
    Map<String, dynamic> career,
  ) {
    final steps = <Map<String, dynamic>>[];
    final gcses = quals.where((q) => q['type'] == 'GCSE').toList();
    final aLevels = quals.where((q) => q['type'] == 'A-Level').toList();
    final btecs = quals.where((q) => q['type'] == 'BTEC').toList();
    final tLevels = quals.where((q) => q['type'] == 'T-Level').toList();

    if (gcses.isNotEmpty) {
      steps.add({
        'phase': 'GCSEs (Year 10–11)', 'icon': '📚', 'color': 0xFF5B4FE9,
        'items': gcses.map((q) => q['title'] ?? '').toList(),
        'tip': 'Focus on your core subjects. Aim for grade 5+ in Maths and English.',
      });
    }
    if (aLevels.isNotEmpty || btecs.isNotEmpty || tLevels.isNotEmpty) {
      final postGCSE = <String>[];
      postGCSE.addAll(aLevels.map((q) => q['title'] ?? ''));
      postGCSE.addAll(btecs.map((q) => q['title'] ?? ''));
      postGCSE.addAll(tLevels.map((q) => q['title'] ?? ''));
      steps.add({
        'phase': 'Post-16 (Year 12–13)', 'icon': '🎯', 'color': 0xFF7B6FF5,
        'items': postGCSE,
        'tip': 'Choose subjects relevant to your career goal.',
      });
    }
    steps.add({
      'phase': 'Next Steps', 'icon': '🚀', 'color': 0xFF4CAF50,
      'items': ['University degree', 'Degree apprenticeship', 'Higher apprenticeship'],
      'tip': 'Explore both routes — apprenticeships let you earn while you learn.',
    });
    steps.add({
      'phase': 'Career Goal', 'icon': '⭐', 'color': 0xFFFF9800,
      'items': [career['name'] ?? 'Your career'],
      'tip': career['avg_salary'] != null
          ? 'Average salary: ${career['avg_salary']}'
          : 'Keep going — you\'re on the right path!',
    });
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Roadmap',
            style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allMatches.isEmpty
              ? _buildEmpty()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Career selector ──────────────────────────────────
                    const Text('Choose a career pathway:',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888AAA),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allMatches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final career = _allMatches[i]['careers'] as Map<String, dynamic>? ?? {};
                          final name = career['name'] ?? 'Career';
                          final score = (_allMatches[i]['match_score'] as num?)?.toInt() ?? 0;
                          final selected = _selectedIndex == i;
                          return GestureDetector(
                            onTap: _loadingRoadmap ? null : () => _loadRoadmapForIndex(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF5B4FE9) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selected
                                        ? const Color(0xFF5B4FE9)
                                        : Colors.grey.shade300)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(name,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? Colors.white : const Color(0xFF1A1A2E))),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white.withOpacity(0.25)
                                        : const Color(0xFFEEECFF),
                                    borderRadius: BorderRadius.circular(10)),
                                  child: Text('$score%',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF5B4FE9))),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Career header ─────────────────────────────────────
                    if (_currentCareer != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5B4FE9), Color(0xFF8B7FF5)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Your pathway to',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_currentCareer!['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          if (_currentCareer!['avg_salary'] != null) ...[
                            const SizedBox(height: 4),
                            Text('💰 ${_currentCareer!['avg_salary']}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ]),
                      ),

                    const SizedBox(height: 24),

                    // ── Roadmap timeline ──────────────────────────────────
                    if (_loadingRoadmap)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      ..._roadmapSteps.asMap().entries.map((e) {
                        final i = e.key;
                        final step = e.value;
                        final isLast = i == _roadmapSteps.length - 1;
                        final color = Color(step['color'] as int);
                        final items = (step['items'] as List).cast<String>();
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                child: Center(child: Text(step['icon'] as String,
                                    style: const TextStyle(fontSize: 20)))),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 80 + (items.length * 22).toDouble(),
                                  color: color.withOpacity(0.3),
                                  margin: const EdgeInsets.symmetric(vertical: 4)),
                            ]),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const SizedBox(height: 10),
                                  Text(step['phase'] as String,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: color)),
                                  const SizedBox(height: 6),
                                  ...items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.check_circle, size: 16,
                                            color: color.withOpacity(0.6)),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(item,
                                            style: const TextStyle(
                                                color: Color(0xFF1A1A2E),
                                                fontSize: 13))),
                                      ]))),
                                  if ((step['tip'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: color.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Text('💡 ${step['tip']}',
                                          style: TextStyle(
                                              color: color.withOpacity(0.8),
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic))),
                                  ],
                                ]),
                              ),
                            ),
                          ],
                        );
                      }),

                    const SizedBox(height: 32),

                    // ── Qualifications completion table ───────────────────
                    if (_qualifications.isNotEmpty && !_loadingRoadmap) ...[
                      const Text('Qualifications Summary',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      const Text('Track which qualifications you still need.',
                          style: TextStyle(color: Color(0xFF888AAA), fontSize: 12)),
                      const SizedBox(height: 12),
                      _QualificationsTable(qualifications: _qualifications),
                    ],

                    const SizedBox(height: 24),
                    if (_currentCareer != null && !_loadingRoadmap)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/pathway/${_currentCareer!['id']}'),
                          icon: const Icon(Icons.explore_outlined,
                              color: Color(0xFF5B4FE9)),
                          label: const Text('View full career pathway',
                              style: TextStyle(color: Color(0xFF5B4FE9))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF5B4FE9)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🗺️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No roadmap yet',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          const Text(
              'Complete onboarding and we\'ll build a personalised journey to your top career.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888AAA))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/onboarding/start'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4FE9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: const Text('Get Started'),
          ),
        ]),
      ),
    );
  }
}

class _QualificationsTable extends StatefulWidget {
  final List<Map<String, dynamic>> qualifications;
  const _QualificationsTable({required this.qualifications});
  @override
  State<_QualificationsTable> createState() => _QualificationsTableState();
}

class _QualificationsTableState extends State<_QualificationsTable> {
  final Set<String> _completed = {};

  Color _typeColor(String type) {
    switch (type) {
      case 'GCSE': return const Color(0xFF5B4FE9);
      case 'A-Level': return Colors.teal;
      case 'BTEC': return Colors.orange;
      case 'T-Level': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final byType = <String, List<Map<String, dynamic>>>{};
    for (final q in widget.qualifications) {
      final type = q['type']?.toString() ?? 'Other';
      byType.putIfAbsent(type, () => []).add(q);
    }

    return Column(
      children: byType.entries.map((e) {
        final type = e.key;
        final items = e.value;
        final color = _typeColor(type);
        final doneCount = items
            .where((q) => _completed.contains(q['id']?.toString() ?? ''))
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(type,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13))),
                const Spacer(),
                Text('$doneCount / ${items.length} done',
                    style: TextStyle(
                        color: doneCount == items.length ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            const Divider(height: 1),
            ...items.map((q) {
              final id = q['id']?.toString() ?? '';
              final title = q['title']?.toString() ?? '';
              final done = _completed.contains(id);
              return InkWell(
                onTap: () => setState(() {
                  if (done) { _completed.remove(id); } else { _completed.add(id); }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? Colors.green : Colors.grey.shade400,
                      size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(title,
                        style: TextStyle(
                            color: done ? Colors.grey : const Color(0xFF1A1A2E),
                            fontSize: 13,
                            decoration: done ? TextDecoration.lineThrough : null))),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 4),
          ]),
        );
      }).toList(),
    );
  }
}
