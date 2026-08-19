import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin test wrappers — let admin run any user-facing screen
/// without affecting their real admin account.
///
/// Upload to: lib/features/admin/screens/admin_test_screens.dart
///
/// Routes to add in your router:
///   GoRoute(path: '/admin-test-onboarding', builder: (_, __) => const AdminTestOnboardingScreen()),
///   GoRoute(path: '/admin-test-home',       builder: (_, __) => const AdminTestHomeScreen()),

// ── Test Onboarding ───────────────────────────────────────────────────────────

class AdminTestOnboardingScreen extends StatelessWidget {
  const AdminTestOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _TestOnboardingWrapper(),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              color: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.science_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ADMIN TEST MODE — changes will NOT be saved',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/admin-home'),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _TestOnboardingWrapper extends StatefulWidget {
  const _TestOnboardingWrapper();

  @override
  State<_TestOnboardingWrapper> createState() => _TestOnboardingWrapperState();
}

class _TestOnboardingWrapperState extends State<_TestOnboardingWrapper>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _interests = [];
  final Map<String, double> _scores = {};
  int _currentPage = 0;
  bool _loading = true;
  late final PageController _pageController;
  late final AnimationController _progressController;

  static const List<Map<String, dynamic>> _scenarios = [
    {
      'question': 'You\'re given £500 and one weekend. Which would you rather do?',
      'optionA': '🧪 Sign up for a first-aid course and volunteer at a local event',
      'optionB': '🎸 Record an original song in a studio',
    },
    {
      'question': 'A local community needs help. Which project do you volunteer for?',
      'optionA': '📊 Redesigning their website and social media strategy',
      'optionB': '🌱 Building a community garden and composting scheme',
    },
    {
      'question': 'You\'ve been given a gap year and unlimited travel. You spend it:',
      'optionA': '⚖️ Interning at a human rights organisation abroad',
      'optionB': '🤖 Learning to build AI tools at a tech bootcamp',
    },
    {
      'question': 'Your school asks you to lead a new club. You choose:',
      'optionA': '🎙️ A debate and public-speaking society',
      'optionB': '🔬 A science and invention challenge club',
    },
    {
      'question': 'You\'re writing a book. What\'s it about?',
      'optionA': '🧠 The psychology of why people make bad decisions',
      'optionB': '💻 A teenager who hacks into government systems to expose corruption',
    },
  ];

  final Map<int, double> _scenarioScores = {};

  int get _totalPages => _interests.length + _scenarios.length;
  bool get _isScenarioPage => _currentPage >= _interests.length;
  double get _progress =>
      _totalPages == 0 ? 0 : (_currentPage + 1) / _totalPages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(vsync: this, value: 0);
    for (int i = 0; i < _scenarios.length; i++) {
      _scenarioScores[i] = 3.0;
    }
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

  Future<void> _next() async {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      _progressController.animateTo(_progress,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    } else {
      _showTestDoneDialog();
    }
  }

  void _showTestDoneDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✅ Test complete!'),
        content: const Text(
            'In real mode this would save to the DB and redirect to /home.\n\nNo data was saved — this was admin test mode.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/admin-home');
            },
            child: const Text('Back to Admin'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentPage = 0;
                for (final id in _scores.keys) _scores[id] = 3.0;
                for (int i = 0; i < _scenarios.length; i++) _scenarioScores[i] = 3.0;
              });
              _pageController.jumpToPage(0);
              _progressController.value = 0;
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _categoryEmoji(String? c) {
    switch (c) {
      case 'Technology': return '💻';
      case 'Business': return '📈';
      case 'Health and Human services': return '🏥';
      case 'Science': return '🔬';
      case 'Arts and Creativity': return '🎨';
      default: return '⭐';
    }
  }

  Color _categoryColor(String? c) {
    switch (c) {
      case 'Technology': return const Color(0xFF4F46E5);
      case 'Business': return const Color(0xFF0891B2);
      case 'Health and Human services': return const Color(0xFF059669);
      case 'Science': return const Color(0xFFD97706);
      case 'Arts and Creativity': return const Color(0xFFDB2777);
      default: return const Color(0xFF6C63FF);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(children: [
                if (_currentPage > 0)
                  IconButton(
                    onPressed: () {
                      setState(() => _currentPage--);
                      _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _isScenarioPage ? 'Quick scenarios' : 'What interests you?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text('${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isScenarioPage
                        ? const Color(0xFF7C3AED)
                        : _categoryColor(_interests[_currentPage.clamp(
                                0, _interests.length - 1)]['category'] as String?),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                itemBuilder: (ctx, index) {
                  if (index < _interests.length) {
                    final interest = _interests[index];
                    final id = interest['id'] as String;
                    final name = interest['name'] as String;
                    final category = interest['category'] as String?;
                    final score = _scores[id] ?? 3.0;
                    final color = _categoryColor(category);

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(
                                color: color.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8))],
                          ),
                          child: Column(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_categoryEmoji(category)} ${category ?? "General"}',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2)),
                            const SizedBox(height: 36),
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
                                min: 1, max: 5, divisions: 4,
                                onChanged: (v) => setState(() => _scores[id] = v),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _sliderLabel(score),
                                key: ValueKey(score.round()),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: color),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    );
                  } else {
                    final si = index - _interests.length;
                    final q = _scenarios[si];
                    final axisScore = _scenarioScores[si] ?? 3.0;
                    const color = Color(0xFF7C3AED);

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(
                                color: color.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8))],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('🎭 Quick scenario',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                            const SizedBox(height: 20),
                            Text(q['question'] as String,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.35)),
                            const SizedBox(height: 20),
                            _OptionBox(
                                text: q['optionA'] as String,
                                isActive: axisScore >= 3.5,
                                color: color),
                            const SizedBox(height: 8),
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
                                value: axisScore,
                                min: 1, max: 5, divisions: 4,
                                onChanged: (v) =>
                                    setState(() => _scenarioScores[si] = v),
                              ),
                            ),
                            _OptionBox(
                                text: q['optionB'] as String,
                                isActive: axisScore <= 2.5,
                                color: color),
                          ]),
                        ),
                      ]),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScenarioPage
                        ? const Color(0xFF7C3AED)
                        : _categoryColor(_interests[_currentPage.clamp(
                                0, _interests.length - 1)]['category'] as String?),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _next,
                  child: Text(
                    _currentPage < _totalPages - 1 ? 'Next →' : 'Finish test 🧪',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OptionBox extends StatelessWidget {
  final String text;
  final bool isActive;
  final Color color;
  const _OptionBox({required this.text, required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              color: isActive ? color : Colors.black54,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
    );
  }
}

// ── Test Home Screen ──────────────────────────────────────────────────────────

class AdminTestHomeScreen extends StatelessWidget {
  const AdminTestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // TODO: replace with your real HomeScreen widget
        // e.g.: const HomeScreen(),
        const Scaffold(
          body: Center(
            child: Text(
              'Add your HomeScreen widget here.\n\nReplace this placeholder in admin_test_screens.dart',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              color: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.visibility_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('ADMIN VIEW — Student home preview',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                GestureDetector(
                  onTap: () => context.go('/admin-home'),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
