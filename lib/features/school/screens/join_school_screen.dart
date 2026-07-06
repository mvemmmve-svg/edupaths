// lib/features/school/screens/join_school_screen.dart
//
// JOIN YOUR SCHOOL — the "Kahoot model".
// Teacher puts the cohort code on the board → student types it here →
// picks their name from the class roster → their account is linked and
// their status flips from "invited" to "active" on the advisor dashboard.
//
// IMPORTANT: this is fully optional. Most users are NOT part of a school,
// so this screen is only reachable from a quiet Profile menu row — it is
// never part of onboarding and never blocks anything.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _sb = Supabase.instance.client;

/// The current user's school link (null = not part of any school).
/// Used by the Profile screen to decide between "Join your school" and
/// "Linked to {school}".
final mySchoolLinkProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  try {
    final user = await DbService.getUserByUid(uid);
    if (user == null) return null;
    final res = await _sb.from('school_students')
        .select('id, status, school_id, schools(name), school_cohorts(name, year_group)')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    return res;
  } catch (_) {
    return null;
  }
});

class JoinSchoolScreen extends ConsumerStatefulWidget {
  const JoinSchoolScreen({super.key});
  @override
  ConsumerState<JoinSchoolScreen> createState() => _JoinSchoolState();
}

class _JoinSchoolState extends ConsumerState<JoinSchoolScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  // After a valid code:
  Map<String, dynamic>? _cohort;       // cohort row incl. schools(name)
  List<Map<String, dynamic>> _roster = [];
  String? _autoMatchedId;              // roster row matched by email
  bool _joined = false;
  String _joinedAs = '';

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _busy = true; _error = null; });
    try {
      final res = await _sb.from('school_cohorts')
          .select('id, name, year_group, school_id, invite_code, schools(name)')
          .ilike('invite_code', code)
          .maybeSingle()
          .timeout(const Duration(seconds: 12));
      if (res == null) {
        setState(() {
          _busy = false;
          _error = 'No class found for that code — double-check with your teacher!';
        });
        return;
      }
      // Load the unclaimed roster for this cohort
      final roster = await _sb.from('school_students')
          .select('id, student_name, student_email, year_group')
          .eq('cohort_id', res['id'])
          .filter('user_id', 'is', null)
          .order('student_name')
          .timeout(const Duration(seconds: 12));
      // Try to auto-match by the logged-in email
      final myEmail =
          (_sb.auth.currentUser?.email ?? '').trim().toLowerCase();
      String? matched;
      for (final r in (roster as List)) {
        final e = (r['student_email'] ?? '').toString().trim().toLowerCase();
        if (myEmail.isNotEmpty && e == myEmail) {
          matched = r['id'] as String;
          break;
        }
      }
      setState(() {
        _cohort = res;
        _roster = roster.cast<Map<String, dynamic>>();
        _autoMatchedId = matched;
        _busy = false;
      });
    } catch (e) {
      setState(() { _busy = false; _error = 'Couldn\'t check that code — try again.'; });
    }
  }

  Future<void> _claim(Map<String, dynamic> row) async {
    setState(() => _busy = true);
    try {
      final uid = _sb.auth.currentUser?.id;
      final user = uid == null ? null : await DbService.getUserByUid(uid);
      if (user == null) {
        setState(() { _busy = false; _error = 'You need to be logged in to join.'; });
        return;
      }
      // Re-check the row is still unclaimed right before taking it, so two
      // students tapping the same name don't both succeed.
      final check = await _sb.from('school_students')
          .select('user_id').eq('id', row['id']).maybeSingle();
      if (check != null && check['user_id'] != null) {
        setState(() {
          _busy = false;
          _error = 'That name was just claimed by someone else — pick another or ask your teacher.';
        });
        _lookupCode();
        return;
      }
      await _sb.from('school_students')
          .update({
            'user_id': user.id,
            'status': 'active',
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', row['id']);
      // Link the school on the user record too
      await _sb.from('users')
          .update({'school_id': _cohort!['school_id']})
          .eq('id', user.id);
      ref.invalidate(mySchoolLinkProvider);
      setState(() {
        _busy = false;
        _joined = true;
        _joinedAs = row['student_name'] ?? '';
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() { _busy = false; _error = 'Something went wrong — try again.'; });
    }
  }

  Future<void> _joinAsNew() async {
    // Student has the code but isn't on the uploaded roster —
    // Kahoot model says let them in; the advisor can remove them later.
    final uid = _sb.auth.currentUser?.id;
    final user = uid == null ? null : await DbService.getUserByUid(uid);
    if (user == null || _cohort == null) return;
    setState(() => _busy = true);
    try {
      await _sb.from('school_students').insert({
        'cohort_id': _cohort!['id'],
        'school_id': _cohort!['school_id'],
        'user_id': user.id,
        'student_name': user.fullName ?? user.email ?? 'Student',
        'student_email': user.email ?? '',
        'year_group': user.schoolYear ?? _cohort!['year_group'] ?? '',
        'status': 'active',
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _sb.from('users')
          .update({'school_id': _cohort!['school_id']})
          .eq('id', user.id);
      ref.invalidate(mySchoolLinkProvider);
      setState(() {
        _busy = false;
        _joined = true;
        _joinedAs = user.fullName ?? 'you';
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() { _busy = false; _error = 'Something went wrong — try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Join your school 🏫'),
        leading: GestureDetector(
          onTap: () => context.pop(), child: const BackBtn())),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _joined
            ? _buildSuccess()
            : _cohort == null
                ? _buildCodeEntry()
                : _buildRoster())),
    );
  }

  // ── Step 1: enter the class code ──
  Widget _buildCodeEntry() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      const Center(child: Text('🏫', style: TextStyle(fontSize: 56))),
      const SizedBox(height: 16),
      const Text('Got a class code?', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900,
        color: AppColors.textDark)),
      const SizedBox(height: 6),
      const Text(
        'If your school uses this app, your teacher will give you a short '
        'code. Enter it to link your account to your class.\n\n'
        'Not part of a school? No problem — you don\'t need a code to use '
        'the app.',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 13.5,
          color: AppColors.textMid, height: 1.5)),
      const SizedBox(height: 20),
      TextField(
        controller: _codeCtrl,
        textCapitalization: TextCapitalization.characters,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 24,
          fontWeight: FontWeight.w900, letterSpacing: 6),
        decoration: const InputDecoration(hintText: 'CLASS CODE'),
        onSubmitted: (_) => _lookupCode()),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(_error!, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 12.5, color: AppColors.error,
          fontWeight: FontWeight.w700))),
      const SizedBox(height: 16),
      PrimaryBtn(
        label: _busy ? 'Checking…' : 'Find my class',
        onPressed: _busy ? null : _lookupCode),
    ]);

  // ── Step 2: pick your name from the roster ──
  Widget _buildRoster() {
    final schoolName =
        (_cohort!['schools'] as Map?)?['name'] ?? 'Your school';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(schoolName, style: const TextStyle(fontFamily: 'Nunito',
              fontSize: 15, fontWeight: FontWeight.w900)),
            Text('${_cohort!['name'] ?? 'Class'}'
              '${_cohort!['year_group'] != null ? ' · ${_cohort!['year_group']}' : ''}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12,
                color: AppColors.textMid)),
          ])),
        ])),
      const SizedBox(height: 18),
      const Text('Which one is you?', style: TextStyle(
        fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      const Text('Tap your name to link your account.',
        style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5,
          color: AppColors.textMid)),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_error!, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 12.5, color: AppColors.error,
          fontWeight: FontWeight.w700))),
      const SizedBox(height: 12),
      if (_roster.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text('No unclaimed names on this class list yet.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
              color: AppColors.textMid)))
      else
        ..._roster.map((r) {
          final isMatch = r['id'] == _autoMatchedId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _busy ? null : () => _claim(r),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isMatch
                      ? const Color(0xFFECFDF5) : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMatch ? AppColors.success : AppColors.border,
                    width: isMatch ? 2 : 1.5)),
                child: Row(children: [
                  CircleAvatar(radius: 16,
                    backgroundColor: AppColors.primaryPale,
                    child: Text(
                      (r['student_name'] ?? '?').toString().isNotEmpty
                          ? (r['student_name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900, fontSize: 13,
                        color: AppColors.primary))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['student_name'] ?? '', style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 14,
                      fontWeight: FontWeight.w800)),
                    if ((r['year_group'] ?? '').toString().isNotEmpty)
                      Text(r['year_group'], style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 11,
                        color: AppColors.textMid)),
                  ])),
                  if (isMatch)
                    const TagBadge(label: 'That\'s me?',
                      bg: Color(0xFFECFDF5), fg: Color(0xFF065F46)),
                ]))));
        }),
      const SizedBox(height: 8),
      Center(child: TextButton(
        onPressed: _busy ? null : _joinAsNew,
        child: const Text('I\'m not on the list — add me',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w800, color: AppColors.primary)))),
    ]);
  }

  // ── Step 3: success ──
  Widget _buildSuccess() {
    final schoolName =
        (_cohort?['schools'] as Map?)?['name'] ?? 'your school';
    return Column(children: [
      const SizedBox(height: 40),
      const Text('🎉', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('You\'re in!', style: TextStyle(fontFamily: 'Nunito',
        fontSize: 24, fontWeight: FontWeight.w900,
        color: AppColors.textDark)),
      const SizedBox(height: 8),
      Text('$_joinedAs is now linked to $schoolName. Your careers '
        'advisor can see your progress and help you plan your next steps.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: AppColors.textMid, height: 1.5)),
      const SizedBox(height: 24),
      PrimaryBtn(label: 'Back to my profile',
        onPressed: () => context.pop()),
    ]);
  }
}
