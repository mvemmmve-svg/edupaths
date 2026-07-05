// lib/features/support/screens/support_screens.dart
//
// User ↔ Admin support messaging (item 6).
//  • SupportThreadScreen        — the person's own conversation with support
//  • SupportThreadScreen(userId:...) — an admin viewing/replying to any thread
//  • AdminInboxScreen           — all threads, newest first, unread badges
//
// Messages live in the support_messages table; row-level security ensures
// users only ever see their own thread while admins see all of them.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

// ══════════════════════════════════════════════════════════════
// USER + ADMIN CHAT THREAD
// ══════════════════════════════════════════════════════════════
class SupportThreadScreen extends ConsumerStatefulWidget {
  /// When null: the logged-in person's own thread (they write as 'user').
  /// When set: an admin viewing this user's thread (they write as 'admin').
  final String? userId;
  final String? userLabel;
  const SupportThreadScreen({super.key, this.userId, this.userLabel});

  @override
  ConsumerState<SupportThreadScreen> createState() => _SupportThreadState();
}

class _SupportThreadState extends ConsumerState<SupportThreadScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  bool get _isAdminView => widget.userId != null;
  String? get _threadUid =>
      widget.userId ?? Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
    // Light auto-refresh so replies appear without reopening the screen
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final uid = _threadUid;
    if (uid == null) return;
    if (!silent) setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client
          .from('support_messages')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: true);
      if (!mounted) return;
      setState(() {
        _messages = (res as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
      _markRead();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead() async {
    final uid = _threadUid;
    if (uid == null) return;
    final col = _isAdminView ? 'read_by_admin' : 'read_by_user';
    final from = _isAdminView ? 'user' : 'admin';
    try {
      await Supabase.instance.client
          .from('support_messages')
          .update({col: true})
          .eq('user_id', uid)
          .eq('sender', from)
          .eq(col, false);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    final uid = _threadUid;
    if (text.isEmpty || uid == null || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('support_messages').insert({
        'user_id': uid,
        'sender': _isAdminView ? 'admin' : 'user',
        'body': text,
      });
      _ctrl.clear();
      await _load(silent: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not send — please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isAdminView
        ? (widget.userLabel ?? 'User thread')
        : 'Message Support 💬';
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Column(children: [
          if (!_isAdminView)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Text('👋', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Tell us what you need help with — our team reads every message and replies right here.',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12.5,
                            color: AppColors.textMid,
                            height: 1.4))),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const EmptyState(
                        emoji: '💬',
                        title: 'No messages yet',
                        subtitle: 'Write your first message below.')
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (c, i) {
                          final m = _messages[i];
                          final mine = _isAdminView
                              ? m['sender'] == 'admin'
                              : m['sender'] == 'user';
                          return _Bubble(
                              body: (m['body'] ?? '').toString(),
                              mine: mine,
                              sender: m['sender'] == 'admin'
                                  ? 'EduPaths Support'
                                  : (widget.userLabel ?? 'You'),
                              time: DateTime.tryParse(
                                  (m['created_at'] ?? '').toString()));
                        }),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(color: AppColors.bgCard, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ]),
            child: Row(children: [
              Expanded(
                  child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                    hintText: 'Type your message…', counterText: ''),
                onSubmitted: (_) => _send(),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14)),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String body, sender;
  final bool mine;
  final DateTime? time;
  const _Bubble(
      {required this.body,
      required this.mine,
      required this.sender,
      this.time});
  @override
  Widget build(BuildContext context) {
    final t = time?.toLocal();
    final stamp = t == null
        ? ''
        : '${t.day}/${t.month} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
            color: mine ? AppColors.primary : AppColors.bgCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine ? null : Border.all(color: AppColors.border)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sender,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: mine
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textMid)),
          const SizedBox(height: 2),
          Text(body,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  height: 1.35,
                  color: mine ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 3),
          Text(stamp,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9.5,
                  color: mine
                      ? Colors.white.withOpacity(0.6)
                      : AppColors.textLight)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADMIN INBOX — every user thread, unread first
// ══════════════════════════════════════════════════════════════
class AdminInboxScreen extends ConsumerStatefulWidget {
  const AdminInboxScreen({super.key});
  @override
  ConsumerState<AdminInboxScreen> createState() => _AdminInboxState();
}

class _AdminInboxState extends ConsumerState<AdminInboxScreen> {
  List<Map<String, dynamic>> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sb = Supabase.instance.client;
      final rows = await sb
          .from('support_messages')
          .select()
          .order('created_at', ascending: false)
          .limit(500);

      // Group by user: latest message + unread count
      final byUser = <String, Map<String, dynamic>>{};
      for (final r in (rows as List).cast<Map<String, dynamic>>()) {
        final uid = r['user_id'].toString();
        byUser.putIfAbsent(uid, () => {
              'user_id': uid,
              'last': r,
              'unread': 0,
            });
        if (r['sender'] == 'user' && r['read_by_admin'] != true) {
          byUser[uid]!['unread'] = (byUser[uid]!['unread'] as int) + 1;
        }
      }

      // Attach names/emails
      final ids = byUser.keys.toList();
      if (ids.isNotEmpty) {
        final users = await sb
            .from('users')
            .select('supabase_uid, email, full_name')
            .in_('supabase_uid', ids);
        for (final u in (users as List).cast<Map<String, dynamic>>()) {
          final uid = u['supabase_uid'].toString();
          if (byUser.containsKey(uid)) {
            byUser[uid]!['email'] = u['email'];
            byUser[uid]!['name'] = u['full_name'];
          }
        }
      }

      final list = byUser.values.toList()
        ..sort((a, b) => (b['unread'] as int).compareTo(a['unread'] as int));
      if (mounted) {
        setState(() {
          _threads = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(title: const Text('Support Inbox 📥'), actions: [
        IconButton(
            onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? const EmptyState(
                  emoji: '📭',
                  title: 'No support messages yet',
                  subtitle:
                      'When users message you from Contact Us, threads appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _threads.length,
                  itemBuilder: (c, i) {
                    final t = _threads[i];
                    final last = t['last'] as Map<String, dynamic>;
                    final unread = t['unread'] as int;
                    final label = (t['name'] ?? t['email'] ?? 'User')
                        .toString();
                    return EduCard(
                      onTap: () async {
                        await context.push(
                            '/admin-thread/${t['user_id']}?name=${Uri.encodeComponent(label)}');
                        _load();
                      },
                      child: Row(children: [
                        CircleAvatar(
                            backgroundColor: unread > 0
                                ? AppColors.primary
                                : AppColors.primaryPale,
                            child: Text('💬',
                                style: const TextStyle(fontSize: 16))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text(label,
                                  style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              Text((last['body'] ?? '').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      color: AppColors.textMid)),
                            ])),
                        if (unread > 0)
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('$unread',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800))),
                      ]),
                    );
                  }),
    );
  }
}
