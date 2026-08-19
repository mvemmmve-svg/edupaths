// lib/features/onboarding/screens/onboarding_slider_screen.dart
// Redesigned: 20 behaviour-based questions (not raw interest labels).
// 7-point scale. Questions cover what you enjoy, what you're good at,
// working style, and values — as per design feedback.
// Each question maps to 2–3 interest IDs so the matching engine still works.
// Scores saved to user_interest.score (1–7 normalised to 1–5 for DB).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Question model ────────────────────────────────────────────────────────────

class _Q {
  final String prompt;        // shown to user
  final String subLabel;      // "How much does this sound like you?"
  final List<String> interestNames; // mapped to interest_id at runtime
  final bool isStrength;      // if true, prompt is about confidence not interest

  const _Q({
    required this.prompt,
    required this.interestNames,
    this.subLabel = 'How much does this sound like you?',
    this.isStrength = false,
  });
}

// 20 questions covering: enjoyment, strength, working style, values
const List<_Q> _questions = [
  // ── What do you enjoy? ──────────────────────────────────────────────────
  _Q(
    prompt: 'I enjoy building things — websites, apps, tools — and figuring out why something isn\'t working.',
    interestNames: ['Web Development', 'Computer Science', 'Engineering'],
  ),
  _Q(
    prompt: 'I enjoy creating something from scratch — a piece of writing, a design, or a piece of music.',
    interestNames: ['Creative Writing', 'Graphic design', 'Music'],
  ),
  _Q(
    prompt: 'I enjoy helping people through a difficult situation — listening, supporting, or guiding them.',
    interestNames: ['Psychology', 'Social work', 'Nursing & Care'],
  ),
  _Q(
    prompt: 'I enjoy analysing data, spotting patterns, and turning numbers into conclusions.',
    interestNames: ['Data & Analytics', 'Maths & Statistics', 'Finance & Investment'],
  ),
  _Q(
    prompt: 'I enjoy organising people, running events, and making sure things go to plan.',
    interestNames: ['Business', 'Marketing & Advertising', 'Entrepreneurship'],
  ),
  _Q(
    prompt: 'I enjoy working with my hands — building, fixing, or making physical things.',
    interestNames: ['Construction & Trades', 'Engineering', 'Physics'],
  ),
  _Q(
    prompt: 'I enjoy understanding how the human body works and what makes people healthy or unwell.',
    interestNames: ['Medicine', 'Biology', 'Healthcare'],
  ),
  _Q(
    prompt: 'I enjoy debating ideas, arguing a case, or persuading people to think differently.',
    interestNames: ['Law', 'Politics & Policy', 'Journalism & Media'],
  ),
  _Q(
    prompt: 'I enjoy making technology smarter — teaching machines, automating tasks, or building AI tools.',
    interestNames: ['Artificial Intelligence', 'Machine Learning', 'Data & Analytics'],
  ),
  _Q(
    prompt: 'I enjoy working with children, young people, or in education.',
    interestNames: ['Education', 'Psychology', 'Social work'],
  ),

  // ── What are you naturally good at? ─────────────────────────────────────
  _Q(
    subLabel: 'How confident are you that you could do this well?',
    prompt: 'Breaking a complicated problem down into smaller steps and working through it methodically.',
    interestNames: ['Computer Science', 'Engineering', 'Maths & Statistics'],
    isStrength: true,
  ),
  _Q(
    subLabel: 'How confident are you that you could do this well?',
    prompt: 'Communicating clearly — whether writing, speaking, or presenting to an audience.',
    interestNames: ['Journalism & Media', 'Marketing & Advertising', 'Law'],
    isStrength: true,
  ),
  _Q(
    subLabel: 'How confident are you that you could do this well?',
    prompt: 'Coming up with original ideas — thinking of solutions no one else has tried.',
    interestNames: ['Entrepreneurship', 'Creative Writing', 'Animation & VFX'],
    isStrength: true,
  ),
  _Q(
    subLabel: 'How confident are you that you could do this well?',
    prompt: 'Working with people — understanding what they need and finding a way to help.',
    interestNames: ['Healthcare', 'Mental Health', 'Nursing & Care'],
    isStrength: true,
  ),

  // ── Working environment ──────────────────────────────────────────────────
  _Q(
    subLabel: 'How much does this match how you like to work?',
    prompt: 'I\'d rather work independently on a project than in a large group.',
    interestNames: ['Data & Analytics', 'Creative Writing', 'Cybersecurity'],
  ),
  _Q(
    subLabel: 'How much does this match how you like to work?',
    prompt: 'I\'d enjoy a job where I\'m on my feet, moving around, or working outdoors.',
    interestNames: ['Sport', 'Construction & Trades', 'Environmental Science'],
  ),
  _Q(
    subLabel: 'How much does this match how you like to work?',
    prompt: 'I\'d enjoy a career where I use technology every day — not just occasionally.',
    interestNames: ['Computer Science', 'Cybersecurity', 'Mobile Apps'],
  ),
  _Q(
    subLabel: 'How much does this match how you like to work?',
    prompt: 'I\'d enjoy working directly with patients, clients, or members of the public.',
    interestNames: ['Healthcare', 'Nursing & Care', 'Mental Health'],
  ),

  // ── Values ────────────────────────────────────────────────────────────────
  _Q(
    subLabel: 'How important is this to you in a future career?',
    prompt: 'Making a real difference to society — not just earning a salary.',
    interestNames: ['Social work', 'Mental Health', 'Environmental Science'],
  ),
  _Q(
    subLabel: 'How important is this to you in a future career?',
    prompt: 'Earning a high salary and having financial security.',
    interestNames: ['Finance & Investment', 'Law', 'Medicine'],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingSliderScreen extends StatefulWidget {
  const OnboardingSliderScreen({super.key});
  @override
  State<OnboardingSliderScreen> createState() => _OnboardingSliderScreenState();
}

class _OnboardingSliderScreenState extends State<OnboardingSliderScreen> {
  final _supabase = Supabase.instance.client;

  // Map interest name → id (loaded from DB)
  final Map<String, String> _interestIdByName = {};
  // Answer per question index (1–7)
  final Map<int, double> _answers = {};
  // Page state
  int _currentPage = 0;
  bool _loading = true;
  bool _saving = false;

  late final PageController _pageController;

  int get _total => _questions.length;
  double get _progress => (_currentPage + 1) / _total;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    for (int i = 0; i < _questions.length; i++) {
      _answers[i] = 4.0; // neutral default
    }
    _loadInterestIds();
  }

  Future<void> _loadInterestIds() async {
    try {
      final rows = await _supabase.from('interests').select('id, name');
      for (final r in List<Map<String, dynamic>>.from(rows as List)) {
        _interestIdByName[r['name'] as String] = r['id'] as String;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _next() async {
    if (_currentPage < _total - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      await _finish();
    }
  }

  Future<void> _back() async {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      final userRow = await _supabase
          .from('users').select('id').eq('supabase_uid', uid).single();
      final userId = userRow['id'] as String;

      await _supabase.from('user_interest').delete().eq('user_id', userId);

      // Accumulate scores per interest (average if same interest appears multiple times)
      final Map<String, List<double>> accumulated = {};
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final raw = _answers[i] ?? 4.0;
        // Normalise 1–7 → 1–5
        final score = ((raw - 1) / 6 * 4 + 1).clamp(1.0, 5.0);
        for (final name in q.interestNames) {
          final id = _interestIdByName[name];
          if (id != null) {
            accumulated.putIfAbsent(id, () => []).add(score);
          }
        }
      }

      final toInsert = accumulated.entries.map((e) => {
        'user_id': userId,
        'interest_id': e.key,
        'score': (e.value.reduce((a, b) => a + b) / e.value.length).round().clamp(1, 5),
      }).toList();

      if (toInsert.isNotEmpty) {
        await _supabase.from('user_interest').insert(toInsert);
      }

      await _supabase.from('users')
          .update({'onboarding_complete': true}).eq('id', userId);

      // Generate career matches immediately after onboarding
      try {
        await _supabase.rpc('generate_smart_matches',
            params: {'p_user_uid': uid.toString()});
      } catch (_) {
        // Non-fatal — user can regenerate from home screen
      }

      if (mounted) _showDoneDialog();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')));
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('You\'re all set!',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Your matches are ready. You can update your answers anytime in Profile.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                },
                child: const Text('See My Matches',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Colour based on question index section
  Color _sectionColor(int index) {
    if (index < 10) return const Color(0xFF6C63FF); // enjoyment
    if (index < 14) return const Color(0xFF0891B2); // strength
    if (index < 18) return const Color(0xFF059669); // working style
    return const Color(0xFFD97706);                  // values
  }

  String _sectionLabel(int index) {
    if (index < 10) return 'What do you enjoy?';
    if (index < 14) return 'What are you good at?';
    if (index < 18) return 'How do you like to work?';
    return 'What matters to you?';
  }

  String _scaleLabel(double v) {
    if (v <= 1) return 'Not at all';
    if (v <= 2) return 'Not really';
    if (v <= 3) return 'A little';
    if (v <= 4) return 'Somewhat';
    if (v <= 5) return 'Quite a bit';
    if (v <= 6) return 'Very much';
    return 'Absolutely ✨';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _questions[_currentPage];
    final score = _answers[_currentPage] ?? 4.0;
    final color = _sectionColor(_currentPage);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Column(children: [

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              if (_currentPage > 0)
                IconButton(
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18)),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_sectionLabel(_currentPage),
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: color)),
                  Text('${_currentPage + 1} of $_total',
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ])),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip', style: TextStyle(color: Colors.black38))),
            ]),
          ),

          // ── Progress bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress, minHeight: 5,
                backgroundColor: Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(color)),
            ),
          ),

          // ── Question card ─────────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _total,
              itemBuilder: (ctx, index) {
                final iq = _questions[index];
                final iscore = _answers[index] ?? 4.0;
                final icolor = _sectionColor(index);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(
                              color: icolor.withOpacity(0.12),
                              blurRadius: 24, offset: const Offset(0, 8))]),
                        child: Column(children: [

                          // Sub-label
                          Text(iq.subLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12,
                                  color: icolor, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),

                          // Prompt — behaviour not career label
                          Text(iq.prompt,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold,
                                  height: 1.45)),
                          const SizedBox(height: 32),

                          // Score display
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              '${iscore.round()} / 7',
                              key: ValueKey(iscore.round()),
                              style: TextStyle(fontSize: 32,
                                  fontWeight: FontWeight.w900, color: icolor)),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              _scaleLabel(iscore),
                              key: ValueKey(iscore.round()),
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600, color: icolor)),
                          ),
                          const SizedBox(height: 20),

                          // Slider — 7 points, tappable number row beneath
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: icolor,
                              inactiveTrackColor: icolor.withOpacity(0.15),
                              thumbColor: icolor,
                              overlayColor: icolor.withOpacity(0.12),
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 16)),
                            child: Slider(
                              value: iscore, min: 1, max: 7, divisions: 6,
                              onChanged: (v) => setState(() => _answers[index] = v)),
                          ),

                          // Tappable number row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (n) {
                              final val = (n + 1).toDouble();
                              final selected = iscore.round() == (n + 1);
                              return GestureDetector(
                                onTap: () => setState(() => _answers[index] = val),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: selected ? icolor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: selected ? icolor : Colors.black12)),
                                  child: Center(
                                    child: Text('${n + 1}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.bold : FontWeight.normal,
                                            color: selected ? Colors.white : Colors.black38))),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 8),
                          // Scale end labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Not at all', style: TextStyle(
                                  fontSize: 10, color: Colors.black38)),
                              Text('Absolutely', style: TextStyle(
                                  fontSize: 10, color: icolor,
                                  fontWeight: FontWeight.w600)),
                            ]),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Next button ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
                onPressed: _saving ? null : _next,
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _currentPage < _total - 1 ? 'Next →' : 'See My Matches 🎉',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
