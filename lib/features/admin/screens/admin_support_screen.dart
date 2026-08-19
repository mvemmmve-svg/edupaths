import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Admin support inbox — lists all user threads, tap to open a thread.
///
/// Upload to: lib/features/admin/screens/admin_support_screen.dart
/// Route:     /admin-support

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final _supabase = Supabase.instance.client;
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
      final resp = await _supabase.rpc('admin_support_inbox');
      setState(() {
        _threads = List<Map<String, dynamic>>.from(resp as List);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/admin-home'),
        ),
        title: Row(
          children: [
            const Text('Support Inbox',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            if (_threads.any((t) => (t['unread_count'] as int? ?? 0) > 0))
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _threads
                      .fold<int>(
                          0,
                          (sum, t) =>
                              sum + (t['unread_count'] as int? ?? 0))
                      .toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('📭', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No support messages yet',
                          style: TextStyle(
                              fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final t = _threads[i];
                      final unread = t['unread_count'] as int? ?? 0;
                      final lastAt = t['last_message_at'] != null
                          ? DateTime.tryParse(
                              t['last_message_at'].toString())
                          : null;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminSupportThreadScreen(
                                userId: t['user_id'] as String,
                                userName: t['user_name'] as String? ??
                                    'Unknown',
                                userEmail:
                                    t['user_email'] as String? ?? '',
                              ),
                            ),
                          ).then((_) => _load());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: unread > 0
                                ? const Color(0xFFFFF7F7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: unread > 0
                                ? Border.all(
                                    color: const Color(0xFFDC2626)
                                        .withOpacity(0.3))
                                : null,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6)
                            ],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF6C63FF)
                                    .withOpacity(0.1),
                                child: Text(
                                  (t['user_name'] as String? ?? '?')
                                      .characters
                                      .first
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6C63FF)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t['user_name'] as String? ??
                                                'Unknown',
                                            style: TextStyle(
                                                fontWeight: unread > 0
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                fontSize: 14),
                                          ),
                                        ),
                                        if (lastAt != null)
                                          Text(
                                            _formatDate(lastAt),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black38),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t['user_email'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black45),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t['last_message'] as String? ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: unread > 0
                                              ? Colors.black87
                                              : Colors.black45,
                                          fontWeight: unread > 0
                                              ? FontWeight.w500
                                              : FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return DateFormat('HH:mm').format(dt);
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEE').format(dt);
    }
    return DateFormat('d MMM').format(dt);
  }
}

// ── Thread screen ─────────────────────────────────────────────────────────────

class AdminSupportThreadScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const AdminSupportThreadScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<AdminSupportThreadScreen> createState() =>
      _AdminSupportThreadScreenState();
}

class _AdminSupportThreadScreenState
    extends State<AdminSupportThreadScreen> {
  final _supabase = Supabase.instance.client;
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    try {
      final resp = await _supabase
          .rpc('admin_support_thread', params: {'p_user_id': widget.userId});
      setState(() {
        _messages = List<Map<String, dynamic>>.from(resp as List);
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _supabase.rpc('admin_support_reply',
          params: {'p_user_id': widget.userId, 'p_body': body});
      _replyController.clear();
      await _loadThread();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending: $e')));
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.userEmail,
                style:
                    const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final m = _messages[i];
                          final isAdmin = m['sender'] == 'admin';
                          final at = DateTime.tryParse(
                              m['created_at'].toString());

                          return Align(
                            alignment: isAdmin
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width *
                                          0.75),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? const Color(0xFF6C63FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.05),
                                      blurRadius: 4)
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['body'] as String? ?? '',
                                    style: TextStyle(
                                        color: isAdmin
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 14),
                                  ),
                                  if (at != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm d MMM').format(at),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: isAdmin
                                              ? Colors.white54
                                              : Colors.black38),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Reply box
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Reply to ${widget.userName}…',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 14),
                  ),
                  onPressed: _sending ? null : _sendReply,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
