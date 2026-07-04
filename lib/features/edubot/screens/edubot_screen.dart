// lib/features/edubot/screens/edubot_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/shared_widgets.dart';

// ── Message model ──────────────────────────────
class _Message {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime time;
  const _Message({required this.role, required this.content, required this.time});
}

// ── Suggested prompts by category ──────────────
const _suggestions = [
  '🎯 What careers match my interests?',
  '📚 What GCSEs do I need to become a nurse?',
  '🎓 Explain the difference between A-Levels and BTECs',
  '💼 What does a software developer do day to day?',
  '🔨 How do apprenticeships work in the UK?',
  '📝 Help me write my UCAS personal statement',
  '💰 What are the highest paying careers for my interests?',
  '🏫 What universities offer physiotherapy?',
];

// ══════════════════════════════════════════════
// EDUBOT SCREEN
// ══════════════════════════════════════════════
class EdubotScreen extends ConsumerStatefulWidget {
  const EdubotScreen({super.key});
  @override
  ConsumerState<EdubotScreen> createState() => _EdubotState();
}

class _EdubotState extends ConsumerState<EdubotScreen> {
  final List<_Message> _messages = [];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;
  bool _showSuggestions = true;

  // Build system prompt with user context
  String _buildSystemPrompt(AppUser? user, List<AppMatch> matches) {
    final name = user?.fullName ?? 'the student';
    final year = user?.schoolYear ?? 'unknown year';
    final topMatches = matches.take(5)
        .map((m) => '${m.careerName} (${m.matchScore}%)')
        .join(', ');

    return '''You are EduBot, an expert UK career guidance AI for EduPaths — a career guidance app for secondary school and sixth form students.

STUDENT PROFILE:
- Name: $name
- School Year: $year
- Top career matches: ${topMatches.isEmpty ? 'Not yet generated' : topMatches}

YOUR ROLE:
- Give clear, encouraging, personalised career guidance
- Focus on UK qualifications: GCSEs, A-Levels, BTECs, T-Levels, Apprenticeships, UCAS
- Reference real UK universities, courses and career pathways
- Be concise — use bullet points for lists, keep answers under 250 words unless asked for more
- Always be positive and encouraging — these are young people making important decisions
- If asked about a specific career, mention required GCSEs, A-Levels/BTECs, university options and apprenticeship routes
- Reference the student by name when appropriate
- Never give medical, legal or financial advice beyond general career guidance
- Always end with a follow-up question or offer to explore further

FORMATTING:
- Use bullet points (•) for lists
- Use **bold** for key terms
- Keep a friendly, encouraging tone
- Emoji use is welcome but keep it professional''';
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    _ctrl.clear();
    setState(() {
      _messages.add(_Message(role: 'user', content: text, time: DateTime.now()));
      _loading = true;
      _showSuggestions = false;
    });
    _scrollToBottom();

    try {
      // Get user context
      final uid = Supabase.instance.client.auth.currentUser?.id;
      AppUser? user;
      List<AppMatch> matches = [];
      if (uid != null) {
        user = await DbService.getUserByUid(uid);
        matches = await DbService.getMatches();
      }

      // Build conversation history for Claude
      final history = _messages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      // SECURITY: the AI is called via our own Netlify function
      // (/api/edubot), never directly — the Anthropic key lives only on
      // the server. We authenticate with the user's Supabase session.
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        setState(() {
          _messages.add(_Message(role: 'assistant',
            content: 'Please log in to chat with EduBot 😊',
            time: DateTime.now()));
        });
        return;
      }

      final req = http.Request('POST', Uri.base.resolve('/api/edubot'))
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer ${session.accessToken}'
        ..body = jsonEncode({'messages': history});

      final streamed = await req.send();

      if (streamed.statusCode == 200) {
        // Server streams Anthropic SSE events; accumulate the text deltas
        // and update the last bubble live as tokens arrive.
        setState(() => _messages.add(
            _Message(role: 'assistant', content: '', time: DateTime.now())));
        var buffer = '';
        await for (final chunk
            in streamed.stream.transform(const Utf8Decoder())) {
          for (final line in chunk.split('\n')) {
            if (!line.startsWith('data:')) continue;
            final payload = line.substring(5).trim();
            if (payload.isEmpty || payload == '[DONE]') continue;
            try {
              final evt = jsonDecode(payload);
              final delta = evt['delta'];
              if (delta is Map && delta['type'] == 'text_delta') {
                buffer += delta['text'] as String;
                setState(() => _messages.last = _Message(
                    role: 'assistant', content: buffer,
                    time: _messages.last.time));
                _scrollToBottom();
              }
            } catch (_) {/* ignore non-JSON keep-alives */}
          }
        }
        if (buffer.isEmpty) {
          setState(() => _messages.last = _Message(role: 'assistant',
              content: 'Sorry, I could not generate a response. Please try again.',
              time: _messages.last.time));
        }
      } else if (streamed.statusCode == 429) {
        final body = await streamed.stream.bytesToString();
        String msg =
            "You've reached your EduBot limit for now. Free accounts get 5 messages a day — upgrade to Premium for much more! ⭐";
        try {
          final j = jsonDecode(body);
          if (j['tier'] == 'premium') {
            msg = "You've reached the hourly message limit. Please try again in a little while.";
          }
        } catch (_) {}
        setState(() => _messages.add(_Message(
            role: 'assistant', content: msg, time: DateTime.now())));
      } else if (streamed.statusCode == 401) {
        setState(() => _messages.add(_Message(role: 'assistant',
            content: 'Please log in to chat with EduBot 😊',
            time: DateTime.now())));
      } else {
        throw Exception('API error: ${streamed.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.add(_Message(
          role: 'assistant',
          content: 'Sorry, I encountered an error. Please try again. '
              'Make sure you have an internet connection.',
          time: DateTime.now()));
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
      }
    });
  }

  void _clearChat() => setState(() {
    _messages.clear();
    _showSuggestions = true;
  });

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(appUserProvider);
    final matchesAsync = ref.watch(matchesProvider);
    final isGuest = Supabase.instance.client.auth.currentUser == null;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Row(children: [
          Text('🤖', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('EduBot', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900)),
          SizedBox(width: 6),
          _OnlineBadge(),
        ]),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Clear chat',
              onPressed: _clearChat),
        ],
      ),
      body: Column(children: [
        // Guest banner
        if (isGuest) Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.primaryPale,
          child: const Text(
            '💡 Sign in to get personalised advice based on your career matches!',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
              color: AppColors.primaryDark, fontWeight: FontWeight.w700))),

        // Chat area
        Expanded(child: _messages.isEmpty
            ? _buildWelcome()
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return const _TypingIndicator();
                  return _BubbleWidget(message: _messages[i]);
                })),

        // Suggestions
        if (_showSuggestions && _messages.isEmpty)
          SizedBox(height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _send(_suggestions[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border)),
                  child: Text(_suggestions[i], style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.textMid)))))),

        // Input area
        _InputBar(ctrl: _ctrl, loading: _loading, onSend: _send),
      ]),
    );
  }

  Widget _buildWelcome() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const SizedBox(height: 16),
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.smart_toy_rounded,
          color: Colors.white, size: 44)),
      const SizedBox(height: 20),
      const Text('Hi! I\'m EduBot 👋', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900,
        color: AppColors.textDark)),
      const SizedBox(height: 8),
      const Text('Your personal UK career guidance assistant.\nAsk me anything about careers, qualifications, universities or apprenticeships!',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: AppColors.textMid, height: 1.5)),
      const SizedBox(height: 24),
      const Text('Try asking...', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 13,
        fontWeight: FontWeight.w700, color: AppColors.textLight)),
      const SizedBox(height: 12),
      ..._suggestions.take(4).map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => _send(s),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
            child: Text(s, style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textDark)))))),
    ]));
}

// ── Chat Bubble ───────────────────────────────
class _BubbleWidget extends StatelessWidget {
  final _Message message;
  const _BubbleWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18)),
            const SizedBox(width: 8),
          ],
          Flexible(child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.bgCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16)),
              border: isUser ? null : Border.all(color: AppColors.border)),
            child: _RichText(
              text: message.content,
              isUser: isUser))),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 14,
              backgroundColor: AppColors.primaryPale,
              child: const Icon(Icons.person_rounded,
                size: 16, color: AppColors.primary)),
          ],
        ]));
  }
}

// ── Rich text renderer for markdown-lite ─────
class _RichText extends StatelessWidget {
  final String text;
  final bool isUser;
  const _RichText({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Bold processing
        final style = TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13.5,
          height: 1.5,
          color: isUser ? Colors.white : AppColors.textDark);

        if (line.startsWith('**') && line.endsWith('**')) {
          return Text(line.replaceAll('**', ''),
            style: style.copyWith(fontWeight: FontWeight.w800));
        }
        // Bullet points
        if (line.startsWith('• ') || line.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _buildInlineText(line, style));
        }
        return _buildInlineText(line, style);
      }).toList());
  }

  Widget _buildInlineText(String line, TextStyle base) {
    // Process **bold** inline
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final m in regex.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(text: line.substring(last, m.start), style: base));
      }
      spans.add(TextSpan(text: m.group(1),
        style: base.copyWith(fontWeight: FontWeight.w800)));
      last = m.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last), style: base));
    }
    return RichText(text: TextSpan(children: spans.isEmpty
        ? [TextSpan(text: line, style: base)] : spans));
  }
}

// ── Typing indicator ──────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingState();
}

class _TypingState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4)),
              border: Border.all(color: AppColors.border)),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dot(0),
                    const SizedBox(width: 4),
                    _dot(1),
                    const SizedBox(width: 4),
                    _dot(2),
                  ],
                );
              })),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    final raw = (_ctrl.value + index * 0.2) % 1.0;
    final opacity = raw.clamp(0.3, 1.0);
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle)));
  }
}

// ── Input bar ─────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool loading;
  final Function(String?) onSend;
  const _InputBar({required this.ctrl, required this.loading,
      required this.onSend});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      left: 12, right: 12, top: 8,
      bottom: MediaQuery.of(context).viewInsets.bottom + 12),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(children: [
      Expanded(child: TextField(
        controller: ctrl,
        maxLines: 4,
        minLines: 1,
        textInputAction: TextInputAction.send,
        onSubmitted: loading ? null : (_) => onSend(null),
        decoration: InputDecoration(
          hintText: 'Ask EduBot anything...',
          hintStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
          filled: true,
          fillColor: AppColors.bgGrey,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none)))),
      const SizedBox(width: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: loading ? null : () => onSend(null),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: loading ? AppColors.border : AppColors.primary,
              shape: BoxShape.circle),
            child: loading
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.white))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20)))),
    ]));
}

// ── Online badge ──────────────────────────────
class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(999)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981), shape: BoxShape.circle)),
      const SizedBox(width: 4),
      const Text('Online', style: TextStyle(fontFamily: 'Nunito',
        fontSize: 10, fontWeight: FontWeight.w700,
        color: Color(0xFF065F46))),
    ]));
}
