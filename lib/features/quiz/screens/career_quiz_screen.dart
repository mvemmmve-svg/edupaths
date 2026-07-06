// lib/features/quiz/screens/career_quiz_screen.dart
//
// CAREER IQ QUIZ — fun knowledge-testing mini-game.
// Pick a career, answer 5 quick multiple-choice questions, get instant
// right/wrong feedback with a myth-busting fact, then a score card.
// Goal: entertainment that sneaks real careers education in, and a
// reason to open the app when you're not "researching".
// Starting set: 3 careers. Add more by extending _quizzes below.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

class _QuizQ {
  final String question;
  final List<String> options;
  final int correct; // index into options
  final String fact; // shown after answering
  const _QuizQ(this.question, this.options, this.correct, this.fact);
}

class _CareerQuiz {
  final String career, emoji;
  final Color color;
  final List<_QuizQ> questions;
  const _CareerQuiz(this.career, this.emoji, this.color, this.questions);
}

const _quizzes = <_CareerQuiz>[
  _CareerQuiz('Software Engineer', '💻', Color(0xFF5B4FE9), [
    _QuizQ('What do software engineers spend MOST of their day doing?',
      ['Writing brand-new code non-stop', 'Reading & improving existing code',
       'In meetings 24/7', 'Playing table tennis'], 1,
      'Most engineering is understanding and improving code that already exists — reading skills matter as much as writing.'),
    _QuizQ('Typical STARTING salary for a junior developer in the UK?',
      ['£18,000', '£28,000', '£55,000', '£90,000'], 1,
      'Juniors typically start around £25–32k — and salaries climb fast with experience.'),
    _QuizQ('Do you NEED a university degree to become a software engineer?',
      ['Yes, always', 'No — apprenticeships & bootcamps count too',
       'Only from Oxford or Cambridge', 'You need a PhD'], 1,
      'Degree apprenticeships at firms like IBM and BT PAY you ~£20k+ while you qualify.'),
    _QuizQ('Which language do most people recommend learning first?',
      ['Python', 'Latin', 'Morse code', 'Klingon'], 0,
      'Python reads almost like English — and it powers AI, apps and games.'),
    _QuizQ('In coding, what\'s a "bug"?',
      ['An insect in the server room', 'An error in the code',
       'A type of hacker', 'A hidden bonus feature'], 1,
      'The first computer "bug" (1947) was literally a moth stuck inside a computer. True story.'),
  ]),
  _CareerQuiz('Nurse', '🩺', Color(0xFF0E9B76), [
    _QuizQ('What\'s the starting salary for a newly qualified NHS nurse?',
      ['£19,000', 'Around £29,000', '£45,000', '£60,000'], 1,
      'Band 5 starts around £29k, rising with experience and specialisation.'),
    _QuizQ('Do student nurses pay tuition like everyone else?',
      ['Yes, exactly the same', 'They get a £5,000/yr grant they NEVER pay back',
       'Nursing degrees are illegal', 'They pay double'], 1,
      'The NHS training grant is at least £5,000 per year — and it\'s not a loan.'),
    _QuizQ('Can nurses prescribe medication?',
      ['Never — only doctors', 'Yes, with extra training',
       'Only on weekends', 'Only paracetamol'], 1,
      'Nurse prescribers are a big part of the modern NHS — nursing has serious career ladders.'),
    _QuizQ('Where can nurses work besides hospitals?',
      ['Nowhere, hospitals only', 'Schools, prisons, film sets & cruise ships',
       'Only GP surgeries', 'Space stations only'], 1,
      'Nurses work everywhere — including on film sets and superyachts. Seriously.'),
    _QuizQ('How much of nursing involves record-keeping?',
      ['Almost none — it\'s all hands-on', 'A big chunk — accurate records save lives',
       'Nurses aren\'t allowed to write', '100% paperwork, no patients'], 1,
      'Documentation is patient safety — it\'s how the whole team stays in sync.'),
  ]),
  _CareerQuiz('Electrician', '⚡', Color(0xFFFF8C42), [
    _QuizQ('How do MOST electricians qualify?',
      ['A university degree', 'An apprenticeship — earning from day one',
       'A YouTube course', 'Born with it'], 1,
      'The apprenticeship route means you\'re paid from day one — no student debt.'),
    _QuizQ('What can an experienced UK electrician earn?',
      ['£20k max, forever', '£40–50k+, often more self-employed',
       'Minimum wage only', 'They work for free'], 1,
      'Experienced sparks regularly out-earn graduates — self-employed ones can clear £50k+.'),
    _QuizQ('What comes out of a UK plug socket?',
      ['230V AC', 'DC like a battery', 'Wi-Fi', 'Static electricity'], 0,
      'UK mains is 230 volts AC — and knowing why is literally the job.'),
    _QuizQ('What do you typically need to work on building sites?',
      ['A driving licence', 'A health & safety card (ECS/CSCS)',
       'A university degree', 'A hard hat and nothing else'], 1,
      'The ECS card proves you\'re qualified and safe — employers check it at the gate.'),
    _QuizQ('Biggest MYTH about the trades?',
      ['"It\'s just a backup plan" — many out-earn graduates',
       'Electricians use electricity', 'You need steady hands',
       'You work with wires'], 0,
      'The UK has a huge electrician shortage — skilled trades are in-demand, secure and well paid.'),
  ]),
];

// ══════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════
class CareerQuizScreen extends StatefulWidget {
  const CareerQuizScreen({super.key});
  @override
  State<CareerQuizScreen> createState() => _CareerQuizScreenState();
}

class _CareerQuizScreenState extends State<CareerQuizScreen> {
  _CareerQuiz? _quiz;   // null = picking a career
  int _index = 0;
  int _score = 0;
  int? _picked;         // selected option for current question
  bool _finished = false;

  void _start(_CareerQuiz q) => setState(() {
    _quiz = q; _index = 0; _score = 0; _picked = null; _finished = false;
  });

  void _answer(int i) {
    if (_picked != null) return; // already answered
    HapticFeedback.mediumImpact();
    setState(() {
      _picked = i;
      if (i == _quiz!.questions[_index].correct) _score++;
    });
  }

  void _next() => setState(() {
    if (_index < _quiz!.questions.length - 1) {
      _index++; _picked = null;
    } else {
      _finished = true;
    }
  });

  (String, String) get _verdict => switch (_score) {
    5 => ('🏆', 'Career Genius! You really know your stuff.'),
    4 => ('🔥', 'So close to perfect — you clearly pay attention.'),
    3 => ('👍', 'Solid! You know more than most people.'),
    _ => ('👀', 'Surprised? That\'s the point — most people are!'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Career IQ 🧠'),
        leading: GestureDetector(
          onTap: () {
            if (_quiz != null && !_finished) {
              setState(() => _quiz = null); // back to picker
            } else {
              context.pop();
            }
          },
          child: const BackBtn())),
      body: SafeArea(child: _quiz == null
          ? _buildPicker()
          : _finished
              ? _buildResults()
              : _buildQuestion()),
    );
  }

  // ── Career picker ──
  Widget _buildPicker() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Think you know these jobs?',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 22,
          fontWeight: FontWeight.w900, color: AppColors.textDark)),
      const SizedBox(height: 4),
      const Text('5 quick questions. Most people get at least one wrong…',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
          color: AppColors.textMid)),
      const SizedBox(height: 20),
      ..._quizzes.map((q) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => _start(q),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [q.color, q.color.withOpacity(0.75)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: q.color.withOpacity(0.35),
                blurRadius: 12, offset: const Offset(0, 6))]),
            child: Row(children: [
              Text(q.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q.career, style: const TextStyle(fontFamily: 'Nunito',
                  fontSize: 17, fontWeight: FontWeight.w900,
                  color: Colors.white)),
                const Text('5 questions · 1 minute', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  color: Colors.white70)),
              ])),
              const Icon(Icons.play_circle_fill_rounded,
                color: Colors.white, size: 32),
            ])),
        ))),
      const SizedBox(height: 8),
      const Center(child: Text('More careers coming soon 👀',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
          color: AppColors.textLight))),
    ]));

  // ── Question view ──
  Widget _buildQuestion() {
    final q = _quiz!.questions[_index];
    final answered = _picked != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${_quiz!.emoji} ${_quiz!.career}', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w800, color: _quiz!.color)),
          const Spacer(),
          Text('${_index + 1}/${_quiz!.questions.length}', style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w800, color: AppColors.textMid)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_index + (answered ? 1 : 0)) / _quiz!.questions.length,
            minHeight: 8,
            backgroundColor: AppColors.bgSurface,
            valueColor: AlwaysStoppedAnimation(_quiz!.color))),
        const SizedBox(height: 20),
        Text(q.question, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 18, fontWeight: FontWeight.w900,
          color: AppColors.textDark, height: 1.35)),
        const SizedBox(height: 16),
        ...List.generate(q.options.length, (i) {
          Color border = AppColors.border;
          Color bg = AppColors.bgCard;
          String? tail;
          if (answered) {
            if (i == q.correct) {
              border = AppColors.success; bg = const Color(0xFFECFDF5);
              tail = '✓';
            } else if (i == _picked) {
              border = AppColors.error; bg = const Color(0xFFFEF2F2);
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
                  border: Border.all(color: border, width: 2)),
                child: Row(children: [
                  Expanded(child: Text(q.options[i], style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w700, height: 1.3))),
                  if (tail != null) Text(tail, style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: tail == '✓' ? AppColors.success : AppColors.error)),
                ]))));
        }),
        if (answered) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _quiz!.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _quiz!.color.withOpacity(0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡 ', style: TextStyle(fontSize: 14)),
              Expanded(child: Text(q.fact, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12.5,
                color: AppColors.textDark, height: 1.45,
                fontWeight: FontWeight.w600))),
            ])),
          const SizedBox(height: 16),
          PrimaryBtn(
            label: _index < _quiz!.questions.length - 1
                ? 'Next question →' : 'See my score 🏁',
            onPressed: _next),
        ],
      ]));
  }

  // ── Results ──
  Widget _buildResults() {
    final (emoji, line) = _verdict;
    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 12),
        Text('$_score / ${_quiz!.questions.length}',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 42,
            fontWeight: FontWeight.w900, color: _quiz!.color)),
        const SizedBox(height: 6),
        Text(line, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 15,
            fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text('${_quiz!.emoji} ${_quiz!.career} quiz complete',
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 12.5,
            color: AppColors.textMid)),
        const SizedBox(height: 24),
        PrimaryBtn(label: '🧠 Try another career',
          onPressed: () => setState(() => _quiz = null)),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Home', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w700, color: AppColors.textMid))),
      ])));
  }
}
