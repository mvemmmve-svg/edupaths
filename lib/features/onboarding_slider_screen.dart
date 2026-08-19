import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Replaces the old yes/no "This or That" quiz.
/// Shows each interest with a 1–5 slider. At the end, saves
/// scores to user_interest (keeping the existing schema) and
/// shows a tip that interests/strengths can be changed in Profile.
///
/// Upload to: lib/screens/onboarding/onboarding_slider_screen.dart

class OnboardingSliderScreen extends StatefulWidget {
  const OnboardingSliderScreen({super.key});

  @override
  State<OnboardingSliderScreen> createState() => _OnboardingSliderScreenState();
}

class _OnboardingSliderScreenState extends State<OnboardingSliderScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  // All interests loaded from DB
  List<Map<String, dynamic>> _interests = [];

  // Map<interest_id, score 1–5>
  final Map<String, double> _scores = {};

  int _currentPage = 0;
  bool _loading = true;
  bool _saving = false;

  late final PageController _pageController;
  late final AnimationController _progressController;

  // How many interests per page (one per swipe keeps it Duolingo-like)
  static const int _perPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(vsync: this, value: 0);
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    try {
      final data = await _supabase
          .from('interests')
          .select('id, name, category')
          .order('category')
          .order('name');
      final list = List<Map<String, dynamic>>.from(data as List);
      // Default every interest to 3 (neutral)
      for (final i in list) {
        _scores[i['id'] as String] = 3.0;
      }
      setState(() {
        _interests = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int get _totalPages => _interests.length;

  double get _progress =>
      _totalPages == 0 ? 0 : (_currentPage + 1) / _totalPages;

  Future<void> _next() async {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo(
        _progress,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _back() async {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      // Look up internal users.id from supabase_uid
      final userRow = await _supabase
          .from('users')
          .select('id')
          .eq('supabase_uid', uid)
          .single();
      final userId = userRow['id'] as String;

      // Delete existing entries so we don't double-up on re-onboarding
      await _supabase.from('user_interest').delete().eq('user_id', userId);

      // Insert one row per interest that scored >= 2 (don't spam DB with "no interest" rows)
      final toInsert = _scores.entries
          .where((e) => e.value >= 2)
          .map((e) => {
                'user_id': userId,
                'interest_id': e.key,
              })
          .toList();

      if (toInsert.isNotEmpty) {
        await _supabase.from('user_interest').insert(toInsert);
      }

      // Mark onboarding complete on users table (use whatever flag your app uses)
      await _supabase
          .from('users')
          .update({'onboarding_complete': true}).eq('id', userId);

      if (mounted) {
        _showDoneDialog();
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  void _showDoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'You\'re all set!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your matches are ready. You can always update your interests and strengths anytime in your Profile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/home');
                  },
                  child: const Text('See My Matches',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ── Emoji per category ────────────────────────────────────────────────
  String _categoryEmoji(String? category) {
    switch (category) {
      case 'Technology':
        return '💻';
      case 'Business':
        return '📈';
      case 'Health and Human services':
        return '🏥';
      case 'Science':
        return '🔬';
      case 'Arts and Creativity':
        return '🎨';
      default:
        return '⭐';
    }
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Technology':
        return const Color(0xFF4F46E5);
      case 'Business':
        return const Color(0xFF0891B2);
      case 'Health and Human services':
        return const Color(0xFF059669);
      case 'Science':
        return const Color(0xFFD97706);
      case 'Arts and Creativity':
        return const Color(0xFFDB2777);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  String _sliderLabel(double v) {
    if (v <= 1) return 'Not for me';
    if (v <= 2) return 'Not really';
    if (v <= 3) return 'Maybe';
    if (v <= 4) return 'I like this';
    return 'Love it! 🔥';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_interests.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No interests found. Please try again.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What interests you?',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentPage + 1} of $_totalPages',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Skip',
                        style: TextStyle(color: Colors.black45)),
                  ),
                ],
              ),
            ),

            // ── Progress bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _categoryColor(
                        _interests[_currentPage]['category'] as String?),
                  ),
                ),
              ),
            ),

            // ── Page view ───────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  final interest = _interests[index];
                  final id = interest['id'] as String;
                  final name = interest['name'] as String;
                  final category = interest['category'] as String?;
                  final score = _scores[id] ?? 3.0;
                  final color = _categoryColor(category);
                  final emoji = _categoryEmoji(category);

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Big card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Category pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$emoji ${category ?? "General"}',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: color,
                                  inactiveTrackColor: color.withOpacity(0.15),
                                  thumbColor: color,
                                  overlayColor: color.withOpacity(0.12),
                                  trackHeight: 8,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 14),
                                ),
                                child: Slider(
                                  value: score,
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  onChanged: (v) =>
                                      setState(() => _scores[id] = v),
                                ),
                              ),

                              // Labels row
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('1', style: TextStyle(color: Colors.black38, fontSize: 12)),
                                    Text('2', style: TextStyle(color: Colors.black38, fontSize: 12)),
                                    Text('3', style: TextStyle(color: Colors.black38, fontSize: 12)),
                                    Text('4', style: TextStyle(color: Colors.black38, fontSize: 12)),
                                    Text('5', style: TextStyle(color: Colors.black38, fontSize: 12)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Dynamic label
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  _sliderLabel(score),
                                  key: ValueKey(score.round()),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Next / Finish button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _categoryColor(
                        _interests[_currentPage]['category'] as String?),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _saving ? null : _next,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _currentPage < _totalPages - 1 ? 'Next →' : 'See My Matches 🎉',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
