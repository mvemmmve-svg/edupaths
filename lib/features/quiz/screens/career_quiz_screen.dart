// lib/features/quiz/screens/career_quiz_screen.dart
// Loads from DB. Careers grouped by category with search bar.
// All careers sorted alphabetically within each category.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

class _QuizQ {
  final String question, optionA, optionB, optionC, correctAnswer, fact;
  const _QuizQ({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.correctAnswer,
    required this.fact,
  });
  List<String> get options => [optionA, optionB, optionC];
  int get correctIndex =>
      correctAnswer == 'a' ? 0 : correctAnswer == 'b' ? 1 : 2;
  factory _QuizQ.fromRow(Map<String, dynamic> r) => _QuizQ(
        question: r['question'] as String,
        optionA: r['option_a'] as String,
        optionB: r['option_b'] as String,
        optionC: r['option_c'] as String,
        correctAnswer: (r['correct_answer'] as String).toLowerCase(),
        fact: r['explanation'] as String? ?? r['myth_busted'] as String? ?? '',
      );
}

class _CareerQuiz {
  final String careerId, careerName, category;
  final List<_QuizQ> questions;
  const _CareerQuiz({
    required this.careerId,
    required this.careerName,
    required this.category,
    required this.questions,
  });

  Color get color {
    const m = {
      'Technology': Color(0xFF4F46E5),
      'Engineering': Color(0xFF0891B2),
      'Health & Medicine': Color(0xFF059669),
      'Business & Finance': Color(0xFF0EA5E9),
      'Creative & Media': Color(0xFFDB2777),
      'Law & Social Work': Color(0xFF7C3AED),
      'Education & People': Color(0xFFD97706),
    };
    return m[category] ?? const Color(0xFF6C63FF);
  }

  String get emoji {
    const m = {
      'software engineer': '💻',
      'nurse': '🩺',
      'electrician': '⚡',
      'doctor': '🏥',
      'teacher': '📚',
      'accountant': '📊',
      'chef': '👨‍🍳',
      'graphic designer': '🎨',
      'civil engineer': '🏗️',
      'marketing manager': '📣',
      'psychologist': '🧠',
      'lawyer': '⚖️',
      'architect': '🏛️',
      'data scientist': '📈',
    };
    return m[careerName.toLowerCase()] ?? '🎯';
  }
}

class CareerQuizScreen extends StatefulWidget {
  const CareerQuizScreen({super.key});
  @override
  State<CareerQuizScreen> createState() => _CareerQuizScreenState();
}

class _CareerQuizScreenState extends State<CareerQuizScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<_CareerQuiz> _all = [];
  List<_CareerQuiz> _filtered = [];
  bool _loading = true;
  String? _error;

  _CareerQuiz? _quiz;
  int _index = 0;
  int _score = 0;
  int? _picked;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load quiz questions
      final rows = await _supabase
          .from('career_quizzes')
          .select()
          .eq('is_active', true)
          .order('career_name')
          .order('sort_order');
      final data = List<Map<String, dynamic>>.from(rows as List);

      // Group by career_id
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final r in data) {
        grouped.putIfAbsent(r['career_id'] as String, () => []).add(r);
      }

      // Fetch categories for these careers using in_ (older supabase_flutter API)
      final careerIds = grouped.keys.toList();
      final Map<String, String> catMap = {};

      if (careerIds.isNotEmpty) {
        final careerRows = await _supabase
            .from('careers')
            .select('id, category')
            .in_('id', careerIds);
        for (final r in List<Map<String, dynamic>>.from(careerRows as List)) {
          catMap[r['id'] as String] = r['category'] as String? ?? 'Other';
        }
      }

      final quizzes = grouped.entries.map((e) {
        final first = e.value.first;
        return _CareerQuiz(
          careerId: first['career_id'] as String,
          careerName: first['career_name'] as String,
          category: catMap[first['career_id'] as String] ?? 'Other',
          questions: e.value.map(_QuizQ.fromRow).toList(),
        );
      }).toList()
        ..sort((a, b) => a.careerName.compareTo(b.careerName));

      setState(() {
        _all = quizzes;
        _filtered = quizzes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _search(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all
              .where((c) =>
                  c.careerName.toLowerCase().contains(lower) ||
                  c.category.toLowerCase().contains(lower))
              .toList();
    });
  }

  void _start(_CareerQuiz q) => setState(() {
        _quiz = q;
        _index = 0;
        _score = 0;
        _picked = null;
        _finished = false;
      });

  void _answer(int i) {
    if (_picked != null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _picked = i;
      if (i == _quiz!.questions[_index].correctIndex) _score++;
    });
  }

  void _next() => setState(() {
        if (_index < _quiz!.questions.length - 1) {
          _index++;
          _picked = null;
        } else {
          _finished = true;
        }
      });

  (String, String) get _verdict {
    final total = _quiz!.questions.length;
    if (total == 0) return ('👀', 'Interesting!');
    final pct = _score / total;
    if (pct == 1.0) return ('🏆', 'Career Genius! You really know your stuff.');
    if (pct >= 0.8) return ('🔥', 'So close to perfect — you clearly pay attention.');
    if (pct >= 0.6) return ('👍', 'Solid! You know more than most people.');
    return ('👀', "Surprised? That's the point — most people are!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Career IQ 🧠'),
        leading: GestureDetector(
          onTap: () {
            if (_quiz != null && !_finished) {
              setState(() => _quiz = null);
            } else {
              context.pop();
            }
          },
          child: const BackBtn(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _quiz == null
                    ? _buildPicker()
                    : _finished
                        ? _buildResults()
                        : _buildQuestion(),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Could not load quizzes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ]),
        ),
      );

  // ── Picker ────────────────────────────────────────────────────────────────

  Widget _buildPicker() {
    // Group filtered list by category, categories sorted
    final Map<String, List<_CareerQuiz>> byCategory = {};
    for (final q in _filtered) {
      byCategory.putIfAbsent(q.category, () => []).add(q);
    }
    final categories = byCategory.keys.toList()..sort();

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search careers or subjects…',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    })
                : null,
          ),
          onChanged: _search,
        ),
      ),

      Expanded(
        child: _filtered.isEmpty
            ? const Center(
                child: Text('No quizzes match your search',
                    style: TextStyle(color: AppColors.textMid)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_searchController.text.isEmpty) ...[
                    const Text(
                      'Think you know these jobs?',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Quick questions. Most people get at least one wrong…',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textMid),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Categories + careers
                  ...categories.expand((cat) => [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            cat,
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: byCategory[cat]!.first.color),
                          ),
                        ),
                        ...byCategory[cat]!.map((q) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: () => _start(q),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      q.color,
                                      q.color.withOpacity(0.75)
                                    ]),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                          color: q.color.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4))
                                    ],
                                  ),
                                  child: Row(children: [
                                    Text(q.emoji,
                                        style:
                                            const TextStyle(fontSize: 28)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(q.careerName,
                                              style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white)),
                                          Text(
                                              '${q.questions.length} question${q.questions.length != 1 ? "s" : ""} · ~1 min',
                                              style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontSize: 12,
                                                  color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: Colors.white,
                                        size: 28),
                                  ]),
                                ),
                              ),
                            )),
                      ]),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'More careers added regularly 👀',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppColors.textLight),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ]);
  }

  // ── Question ──────────────────────────────────────────────────────────────

  Widget _buildQuestion() {
    final q = _quiz!.questions[_index];
    final answered = _picked != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            '${_quiz!.emoji} ${_quiz!.careerName}',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _quiz!.color),
          ),
          const Spacer(),
          Text(
            '${_index + 1}/${_quiz!.questions.length}',
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textMid),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_index + (answered ? 1 : 0)) / _quiz!.questions.length,
            minHeight: 8,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation(_quiz!.color),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          q.question,
          style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.35),
        ),
        const SizedBox(height: 16),
        ...List.generate(q.options.length, (i) {
          Color border = AppColors.border;
          Color bg = AppColors.bgCard;
          String? tail;
          if (answered) {
            if (i == q.correctIndex) {
              border = AppColors.success;
              bg = const Color(0xFFECFDF5);
              tail = '✓';
            } else if (i == _picked) {
              border = AppColors.error;
              bg = const Color(0xFFFEF2F2);
              tail = '✗';
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _answer(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 2),
                ),
                child: Row(children: [
                  Expanded(
                      child: Text(q.options[i],
                          style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3))),
                  if (tail != null)
                    Text(tail,
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: tail == '✓'
                                ? AppColors.success
                                : AppColors.error)),
                ]),
              ),
            ),
          );
        }),
        if (answered && q.fact.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _quiz!.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _quiz!.color.withOpacity(0.3)),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(q.fact,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12.5,
                            color: AppColors.textDark,
                            height: 1.45,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            label: _index < _quiz!.questions.length - 1
                ? 'Next question →'
                : 'See my score 🏁',
            onPressed: _next,
          ),
        ],
      ]),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final (emoji, line) = _verdict;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(
            '$_score / ${_quiz!.questions.length}',
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: _quiz!.color),
          ),
          const SizedBox(height: 6),
          Text(line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(
            '${_quiz!.emoji} ${_quiz!.careerName} quiz complete',
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                color: AppColors.textMid),
          ),
          const SizedBox(height: 24),
          PrimaryBtn(
            label: '🧠 Try another career',
            onPressed: () => setState(() => _quiz = null),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to Home',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMid)),
          ),
        ]),
      ),
    );
  }
}
