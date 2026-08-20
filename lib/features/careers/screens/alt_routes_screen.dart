import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class AltRoutesScreen extends StatefulWidget {
  final String careerId;
  const AltRoutesScreen({super.key, required this.careerId});

  @override
  State<AltRoutesScreen> createState() => _AltRoutesScreenState();
}

class _AltRoutesScreenState extends State<AltRoutesScreen> {
  Map<String, dynamic>? _career;
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final careerRes = await _supabase
          .from('careers')
          .select('id, name, description, avg_salary, category')
          .eq('id', widget.careerId)
          .single();

      // Build routes from courses linked to this career
      final coursesRes = await _supabase
          .from('career_course')
          .select('courses(id, title, institution, course_type, duration, entry_requirements, url, description)')
          .eq('career_id', widget.careerId)
          .limit(20);

      final allCourses = (coursesRes as List)
          .map((r) => r['courses'] as Map<String, dynamic>? ?? {})
          .where((c) => c.isNotEmpty)
          .toList();

      final uniCourses = allCourses
          .where((c) => (c['course_type'] ?? '').toString().toLowerCase() == 'university')
          .toList();
      final appCourses = allCourses
          .where((c) => (c['course_type'] ?? '').toString().toLowerCase() == 'apprenticeship')
          .toList();

      // Build 3 route options
      final routes = <Map<String, dynamic>>[];

      if (uniCourses.isNotEmpty) {
        final sample = uniCourses.first;
        routes.add({
          'label': 'Option A',
          'icon': '🎓',
          'color': 0xFF5B4FE9,
          'title': 'University — ${sample['title'] ?? 'Degree route'}',
          'duration': sample['duration'] ?? '3–4 yrs',
          'description': sample['description'] ??
              'Study for a degree at university. Entry typically requires A-Levels or equivalent.',
          'entry': sample['entry_requirements'] ?? '',
        });
      }

      if (appCourses.isNotEmpty) {
        final sample = appCourses.first;
        routes.add({
          'label': 'Option B',
          'icon': '🔧',
          'color': 0xFF4CAF50,
          'title': 'Apprenticeship — ${sample['title'] ?? 'Earn while you learn'}',
          'duration': sample['duration'] ?? '2–4 yrs',
          'description': sample['description'] ??
              'Earn a salary while training on the job. No tuition fees.',
          'entry': sample['entry_requirements'] ?? '',
        });
      }

      // Always add a self-study/freelance option
      routes.add({
        'label': routes.isEmpty ? 'Option A' : routes.length == 1 ? 'Option B' : 'Option C',
        'icon': '🚀',
        'color': 0xFFFF9800,
        'title': 'Self-directed — Portfolio + Freelance',
        'duration': '1 yr +',
        'description':
            'Build skills through online courses, personal projects, and freelance work. No formal entry requirements.',
        'entry': '',
      });

      setState(() {
        _career = careerRes;
        _routes = routes;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final careerName = _career?['name'] ?? 'Career';
    final salary = _career?['avg_salary'] ?? '';

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
        title: Text(
          careerName,
          style: const TextStyle(
              color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Timeline header
                _buildTimelineHeader(careerName),
                const SizedBox(height: 24),

                // Route cards
                ..._routes.asMap().entries.map((e) {
                  final route = e.value;
                  return _RouteCard(route: route);
                }),

                const SizedBox(height: 16),

                // Compare CTA
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('⚖️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Compare these routes side by side',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E)),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Color(0xFF5B4FE9)),
                        ],
                      ),
                    ),
                  ),
                ),

                if (salary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFFEEECFF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Average salary for $careerName: $salary',
                              style: const TextStyle(
                                  color: Color(0xFF5B4FE9),
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildTimelineHeader(String careerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple year timeline
        Row(
          children: [
            _YearDot(year: DateTime.now().year.toString(), label: 'Now'),
            _TimelineLine(),
            _YearDot(
                year: (DateTime.now().year + 2).toString(), label: 'Post-16'),
            _TimelineLine(),
            _YearDot(
                year: (DateTime.now().year + 4).toString(),
                label: 'Next step'),
            _TimelineLine(),
            _YearDot(
                year: (DateTime.now().year + 7).toString(),
                label: careerName,
                isLast: true),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Age 18 — choose your route',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Each path leads to the same destination — pick what fits you.',
          style: TextStyle(color: Color(0xFF888AAA), fontSize: 13),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final color = Color(route['color'] as int);
    final entry = route['entry'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row — Expanded prevents overflow
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route['icon'] as String? ?? '',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              route['title'] as String? ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                              // KEY FIX: allows text to wrap instead of overflow
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          route['duration'] as String? ?? '',
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              route['description'] as String? ?? '',
              style: const TextStyle(
                color: Color(0xFF555577),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (entry.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 ', style: TextStyle(fontSize: 12)),
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
  }
}

class _YearDot extends StatelessWidget {
  final String year;
  final String label;
  final bool isLast;

  const _YearDot(
      {required this.year, required this.label, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isLast
                ? const Color(0xFF5B4FE9)
                : const Color(0xFFEEECFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF5B4FE9), width: 2),
          ),
          child: Center(
            child: Text(
              year.substring(2), // show last 2 digits e.g. "26"
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isLast ? Colors.white : const Color(0xFF5B4FE9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF888AAA)),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: const Color(0xFFDDDBFF),
        margin: const EdgeInsets.only(bottom: 20),
      ),
    );
  }
}
