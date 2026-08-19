// lib/features/quiz/screens/career_quiz_screen.dart
//
// Loads quizzes from `career_quizzes` table in Supabase.
// Falls back to empty state if no data. No intl dependency.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _QuizQ {
  final String question;
  final String optionA, optionB, optionC;
  final String correctAnswer; // 'a', 'b', or 'c'
  final String fact;

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

  factory _QuizQ.fromRow(Map<String, dynamic> row) => _QuizQ(
        question: row['question'] as String,
        optionA: row['option_a'] as String,
        optionB: row['option_b'] as String,
        optionC: row['option_c'] as String,
        correctAnswer: (row['correct_answer'] as String).toLowerCase(),
        fact: (row['explanation'] as String? ??
            row['myth_busted'] as String? ??
            ''),
      );
}

class _CareerQuiz {
  final String careerId, careerName;
  final List<_QuizQ> questions;

  const _CareerQuiz({
    required this.careerId,
    required this.careerName,
    required this.questions,
  });

  // Deterministic colour from career name
  Color get color {
    const palette = [
      Color(0xFF5B4FE9), Color(0xFF0E9B76), Color(0xFFFF8C42),
      Color(0xFF0891B2), Color(0xFFDB2777), Color(0xFFD97706),
      Color(0xFF059669), Color(0xFF7C3AED), Color(0xFF1D4ED8),
      Color(0xFFDC2626),
    ];
    return palette[careerName.length % palette.length];
  }

  String get emoji {
    const map = {
      'software engineer': '💻', 'nurse': '🩺', 'electrician': '⚡',
      'doctor': '🏥', 'teacher': '📚', 'accountant': '📊',
      'chef': '👨‍🍳', 'graphic designer': '🎨', 'civil engineer': '🏗️',
      'marketing manager': '📣', 'psychologist': '🧠',
    };
    return map[careerName.toLowerCase()] ?? '🎯';
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CareerQuizScreen extends StatefulWidget {
  const CareerQuizScreen({super.key});

  @override
  State<CareerQuizScreen> createState() => _CareerQuizScreenState();
}

class _CareerQuizScreenState extends State<CareerQuizScreen> {
  final _supabase = Supabase.instance.client;

  List<_CareerQuiz> _quizzes = [];
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
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final rows = await _supabase
          .from('career_quizzes')
          .select()
          .eq('is_active', true)
          .order('career_name')
          .order('sort_order');

      final data = List<Map<String, dynamic>>.from(rows as List);

      // Group by career
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in data) {
        final key = row['career_id'] as String;
        grouped.putIfAbsent(key, () => []).add(row);
      }

      final quizzes = grouped.entries.map((e) {
        final first = e.value.first;
        return _CareerQuiz(
          careerId: first['career_id'] as String,
          careerName: first['career_name'] as String,
          questions: e.value.map(_QuizQ.fromRow).toList(),
        );
      }).toList();

      // Sort alphabetically
      quizzes.sort((a, b) => a.careerName.compareTo(b.careerName));

      setState(() {
        _quizzes = quizzes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Could not load quizzes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadQuizzes();
                },
                child: const Text('Try again')),
          ]),
        ),
      );

  // ── Career picker ─────────────────────────────────────────────────────────

  Widget _buildPicker() => _quizzes.isEmpty
      ? const Center(
          child: Text('No quizzes available yet.',
              style: TextStyle(color: AppColors.textMid)))
      : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Think you know these jobs?',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('Quick questions. Most people get at least one wrong…',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppColors.textMid)),
              const SizedBox(height: 20),
              ..._quizzes.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _start(q),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            q.color,
                            q.color.withOpacity(0.75)
                          ]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: q.color.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: Row(children: [
                          Text(q.emoji,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q.careerName,
                                    style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                                Text(
                                    '${q.questions.length} questions · 1 minute',
                                    style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        color: Colors.white70)),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white, size: 32),
                        ]),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              const Center(
                  child: Text('More careers added regularly 👀',
                      style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.textLight))),
            ],
          ),
        );

  // ── Question ──────────────────────────────────────────────────────────────

  Widget _buildQuestion() {
    final q = _quiz!.questions[_index];
    final answered = _picked != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('${_quiz!.emoji} ${_quiz!.careerName}',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _quiz!.color)),
            const Spacer(),
            Text('${_index + 1}/${_quiz!.questions.length}',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMid)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_index + (answered ? 1 : 0)) /
                  _quiz!.questions.length,
              minHeight: 8,
              backgroundColor: AppColors.bgSurface,
              valueColor: AlwaysStoppedAnimation(_quiz!.color),
            ),
          ),
          const SizedBox(height: 20),
          Text(q.question,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.35)),
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
                border: Border.all(
                    color: _quiz!.color.withOpacity(0.3)),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ',
                        style: TextStyle(fontSize: 14)),
                    Expanded(
                        child: Text(q.fact,
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12.5,
                                color: AppColors.textDark,
                                height: 1.45,
                                fontWeight: FontWeight.w600))),
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
        ],
      ),
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
          Text('$_score / ${_quiz!.questions.length}',
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: _quiz!.color)),
          const SizedBox(height: 6),
          Text(line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text('${_quiz!.emoji} ${_quiz!.careerName} quiz complete',
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.5,
                  color: AppColors.textMid)),
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
