import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A self-contained filter bar + results list for the Find Courses screen.
///
/// DROP-IN USAGE — wrap your existing CoursesScreen body with this widget,
/// or call CourseFilterBar directly inside a Column.
///
/// Upload to: lib/screens/courses/courses_filter_bar.dart
///
/// The widget queries `courses` (for University/College) and
/// `search_apprenticeships` RPC (for live gov.uk apprenticeships) with
/// Location, Course Type and Category filters applied server-side.

// ── Filter state ─────────────────────────────────────────────────────────────

class CourseFilters {
  String? location;       // free-text city / postcode fragment, null = all
  String? courseType;     // 'Apprenticeship' | 'University' | null = all
  String? category;       // e.g. 'Engineering', null = all
  String? searchQuery;

  CourseFilters({
    this.location,
    this.courseType,
    this.category,
    this.searchQuery,
  });

  CourseFilters copyWith({
    Object? location = _sentinel,
    Object? courseType = _sentinel,
    Object? category = _sentinel,
    Object? searchQuery = _sentinel,
  }) {
    return CourseFilters(
      location:    location    == _sentinel ? this.location    : location    as String?,
      courseType:  courseType  == _sentinel ? this.courseType  : courseType  as String?,
      category:    category    == _sentinel ? this.category    : category    as String?,
      searchQuery: searchQuery == _sentinel ? this.searchQuery : searchQuery as String?,
    );
  }

  bool get hasActiveFilters =>
      location != null || courseType != null || category != null;

  static const _sentinel = Object();
}

// ── UK city quick-picks ───────────────────────────────────────────────────────

const List<String> _ukCities = [
  'London', 'Manchester', 'Birmingham', 'Leeds', 'Liverpool',
  'Bristol', 'Sheffield', 'Newcastle', 'Nottingham', 'Cardiff',
  'Edinburgh', 'Glasgow', 'Oxford', 'Cambridge', 'Brighton',
];

const List<String> _courseTypes = ['Apprenticeship', 'University'];

const List<String> _categories = [
  'Engineering',
  'Computer Science & IT',
  'Business & Finance',
  'Marketing',
  'Health & Medicine',
  'Health & Nursing',
  'Creative & Media',
  'Architecture & Design',
  'Environmental Science',
  'Education & Teaching',
  'Psychology & Social Sciences',
  'Hair & Beauty',
  'Catering & Hospitality',
  'Transport & Logistics',
];

// ── Main filter bar widget ────────────────────────────────────────────────────

class CourseFilterBar extends StatefulWidget {
  const CourseFilterBar({super.key});

  @override
  State<CourseFilterBar> createState() => _CourseFilterBarState();
}

class _CourseFilterBarState extends State<CourseFilterBar> {
  final _supabase = Supabase.instance.client;
  CourseFilters _filters = CourseFilters();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _hasFetched = false;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() => _loading = true);
    try {
      List<Map<String, dynamic>> results = [];

      final type = _filters.courseType;
      final search = _filters.searchQuery ?? '';
      final loc = _filters.location;
      final cat = _filters.category;

      // ── Apprenticeships via RPC ──────────────────────────────────────────
      if (type == null || type == 'Apprenticeship') {
        final resp = await _supabase.rpc('search_apprenticeships', params: {
          'p_search':   search.isEmpty ? null : search,
          'p_route':    null,  // route filter not exposed here; use category below
          'p_level':    null,
          'p_location': loc,
          'p_limit':    80,
        });
        var apps = List<Map<String, dynamic>>.from(resp as List);

        // Category filter (client-side for apprenticeships — route→category
        // mapping is in the sync function; here we filter by matching text)
        if (cat != null) {
          // Map category back to gov route keywords for filtering
          final routeKeyword = _categoryToRouteKeyword(cat);
          if (routeKeyword != null) {
            apps = apps
                .where((a) =>
                    (a['route'] as String? ?? '')
                        .toLowerCase()
                        .contains(routeKeyword.toLowerCase()))
                .toList();
          }
        }

        results.addAll(apps.map((a) => {
              '_type': 'apprenticeship',
              'title': a['title'],
              'employer': a['employer_name'],
              'location': a['location'],
              'is_national': a['is_national'],
              'wage': a['wage_text'],
              'level': a['apprenticeship_level'],
              'route': a['route'],
              'closing_date': a['closing_date'],
              'apply_url': a['apply_url'] ?? a['vacancy_url'],
              'duration': a['expected_duration'],
            }));
      }

      // ── University / other courses from courses table ────────────────────
      if (type == null || type == 'University') {
        var query = _supabase
            .from('courses')
            .select(
                'id, title, course_type, category, location, duration, entry_requirements, url, institution_id')
            .neq('course_type', 'Apprenticeship'); // exclude synced apprenticeships

        if (search.isNotEmpty) {
          query = query.ilike('title', '%$search%');
        }
        if (cat != null) {
          query = query.eq('category', cat);
        }
        if (loc != null && loc.isNotEmpty) {
          query = query.ilike('location', '%$loc%');
        }

        final uniResp = await query.order('title').limit(60);
        final uniList = List<Map<String, dynamic>>.from(uniResp as List);
        results.addAll(uniList.map((c) => {
              '_type': 'university',
              'title': c['title'],
              'course_type': c['course_type'],
              'category': c['category'],
              'location': c['location'],
              'duration': c['duration'],
              'url': c['url'],
            }));
      }

      setState(() {
        _results = results;
        _loading = false;
        _hasFetched = true;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  String? _categoryToRouteKeyword(String category) {
    const map = {
      'Engineering': 'engineering',
      'Computer Science & IT': 'digital',
      'Business & Finance': 'business',
      'Marketing': 'sales',
      'Health & Medicine': 'health',
      'Health & Nursing': 'care',
      'Creative & Media': 'creative',
      'Architecture & Design': 'construction',
      'Environmental Science': 'agriculture',
      'Education & Teaching': 'education',
      'Hair & Beauty': 'hair',
      'Catering & Hospitality': 'catering',
      'Transport & Logistics': 'transport',
    };
    return map[category];
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        current: _filters,
        onApply: (updated) {
          setState(() => _filters = updated);
          _fetchCourses();
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filters = CourseFilters();
      _searchController.clear();
    });
    _fetchCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + filter row ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search courses…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) {
                    _filters = _filters.copyWith(searchQuery: v.isEmpty ? null : v);
                    _fetchCourses();
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Filter button — badge shows active count
              Stack(
                children: [
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onPressed: _openFilterSheet,
                    child: Row(
                      children: [
                        const Icon(Icons.tune, size: 18),
                        const SizedBox(width: 6),
                        const Text('Filter'),
                      ],
                    ),
                  ),
                  if (_filters.hasActiveFilters)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          [
                            _filters.location,
                            _filters.courseType,
                            _filters.category,
                          ].where((f) => f != null).length.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // ── Active filter chips ───────────────────────────────────────────
        if (_filters.hasActiveFilters)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_filters.location != null)
                  _ActiveChip(
                    label: '📍 ${_filters.location}',
                    onRemove: () {
                      setState(() => _filters = _filters.copyWith(location: null));
                      _fetchCourses();
                    },
                  ),
                if (_filters.courseType != null)
                  _ActiveChip(
                    label: _filters.courseType == 'Apprenticeship'
                        ? '🔧 Apprenticeship'
                        : '🎓 University',
                    onRemove: () {
                      setState(
                          () => _filters = _filters.copyWith(courseType: null));
                      _fetchCourses();
                    },
                  ),
                if (_filters.category != null)
                  _ActiveChip(
                    label: _filters.category!,
                    onRemove: () {
                      setState(
                          () => _filters = _filters.copyWith(category: null));
                      _fetchCourses();
                    },
                  ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear all',
                      style: TextStyle(color: Colors.black45, fontSize: 13)),
                ),
              ],
            ),
          ),

        const SizedBox(height: 4),

        // ── Results ───────────────────────────────────────────────────────
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_hasFetched && _results.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text('No courses found',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final c = _results[i];
                return c['_type'] == 'apprenticeship'
                    ? _ApprenticeshipCard(data: c)
                    : _UniversityCourseCard(data: c);
              },
            ),
          ),
      ],
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final CourseFilters current;
  final ValueChanged<CourseFilters> onApply;

  const _FilterSheet({required this.current, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CourseFilters _draft;
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = CourseFilters(
      location: widget.current.location,
      courseType: widget.current.courseType,
      category: widget.current.category,
    );
    _locationController.text = widget.current.location ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Text('Filters',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _draft = CourseFilters();
                          _locationController.clear();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    // ── Location ────────────────────────────────────────
                    _SectionLabel(icon: '📍', label: 'Location'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'e.g. London, Manchester, M1 2AB…',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        suffixIcon: _locationController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _locationController.clear();
                                  setState(() => _draft =
                                      _draft.copyWith(location: null));
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) {
                        setState(() => _draft = _draft.copyWith(
                            location: v.trim().isEmpty ? null : v.trim()));
                      },
                    ),
                    const SizedBox(height: 10),

                    // Quick city picks
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _ukCities.map((city) {
                        final selected = _draft.location == city;
                        return ChoiceChip(
                          label: Text(city),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _draft = _draft.copyWith(
                                  location: selected ? null : city);
                              _locationController.text = selected ? '' : city;
                            });
                          },
                          selectedColor:
                              const Color(0xFF6C63FF).withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF6C63FF)
                                : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Course type ──────────────────────────────────────
                    _SectionLabel(icon: '🎓', label: 'Course type'),
                    const SizedBox(height: 10),
                    Row(
                      children: _courseTypes.map((t) {
                        final selected = _draft.courseType == t;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: t == _courseTypes.first ? 8 : 0),
                            child: GestureDetector(
                              onTap: () => setState(() => _draft =
                                  _draft.copyWith(
                                      courseType: selected ? null : t)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF6C63FF)
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      t == 'Apprenticeship' ? '🔧' : '🎓',
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      t,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Category ─────────────────────────────────────────
                    _SectionLabel(icon: '🏷️', label: 'Subject area'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _draft.category == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) => setState(() => _draft =
                              _draft.copyWith(
                                  category: selected ? null : cat)),
                          selectedColor:
                              const Color(0xFF6C63FF).withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF6C63FF)
                                : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Apply button
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onApply(_draft);
                      },
                      child: const Text('Apply filters',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Course result cards ───────────────────────────────────────────────────────

class _ApprenticeshipCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ApprenticeshipCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isNational = data['is_national'] as bool? ?? false;
    final location = isNational ? 'National' : (data['location'] as String? ?? 'Various');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🔧 Apprenticeship',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                if (data['level'] != null)
                  Text('Level ${data['level']}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data['title'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (data['employer'] != null) ...[
              const SizedBox(height: 4),
              Text(data['employer'] as String,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [
                _InfoPill(icon: Icons.location_on_outlined, label: location),
                if (data['wage'] != null)
                  _InfoPill(icon: Icons.payments_outlined, label: data['wage'] as String),
                if (data['duration'] != null)
                  _InfoPill(icon: Icons.schedule_outlined, label: data['duration'] as String),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UniversityCourseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _UniversityCourseCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎓 ${data['course_type'] ?? 'University'}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data['title'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (data['category'] != null) ...[
              const SizedBox(height: 4),
              Text(data['category'] as String,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54)),
            ],
            if (data['duration'] != null) ...[
              const SizedBox(height: 8),
              _InfoPill(
                  icon: Icons.schedule_outlined,
                  label: data['duration'] as String),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: Color(0xFF6C63FF)),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.black45),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
