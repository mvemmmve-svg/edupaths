import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class JoinSchoolScreen extends StatefulWidget {
  const JoinSchoolScreen({super.key});

  @override
  State<JoinSchoolScreen> createState() => _JoinSchoolScreenState();
}

class _JoinSchoolScreenState extends State<JoinSchoolScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _school;
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _pendingStudent; // student tapped — awaiting confirm

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _school = null;
      _students = [];
    });
    try {
      final schoolRes = await _supabase
          .from('schools')
          .select('id, name')
          .eq('invite_code', code)
          .maybeSingle();
      if (schoolRes == null) {
        setState(() {
          _error = 'No school found with that code. Check with your teacher.';
          _loading = false;
        });
        return;
      }
      // Find cohort(s) for this school
      final cohortRes = await _supabase
          .from('school_cohorts')
          .select('id, name, year_group')
          .eq('school_id', schoolRes['id']);
      final cohortIds = (cohortRes as List).map((c) => c['id']).toList();
      if (cohortIds.isEmpty) {
        setState(() {
          _error = 'No class groups set up yet. Ask your teacher.';
          _loading = false;
        });
        return;
      }
      // Get unlinked students
      final studentsRes = await _supabase
          .from('school_students')
          .select('id, student_name, year_group, cohort_id')
          .in_('cohort_id', cohortIds)
          .filter('user_id', 'is', null);

      setState(() {
        _school = schoolRes;
        _students = List<Map<String, dynamic>>.from(studentsRes);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Try again.';
        _loading = false;
      });
    }
  }

  /// First tap: show confirmation dialog before linking
  void _onStudentTap(Map<String, dynamic> student) {
    setState(() => _pendingStudent = student);
    _showConfirmDialog(student);
  }

  void _showConfirmDialog(Map<String, dynamic> student) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool confirmed = false;
          bool linking = false;
          String? dialogError;

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Confirm it\'s you'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: Color(0xFF1A1A2E), fontSize: 14, height: 1.4),
                    children: [
                      const TextSpan(text: 'You selected '),
                      TextSpan(
                        text: student['student_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                          text:
                              '.\n\nType your first name below to confirm this is you:'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Your first name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onChanged: (v) => setDialogState(() {}),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: linking
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        setState(() => _pendingStudent = null);
                      },
                child: const Text('Go back'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4FE9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: linking
                    ? null
                    : () async {
                        final entered =
                            nameController.text.trim().toLowerCase();
                        final fullName =
                            (student['student_name'] ?? '').toLowerCase();
                        final firstName = fullName.split(' ').first;

                        // Check entered first name matches
                        if (entered.isEmpty ||
                            !fullName.contains(entered) &&
                                entered != firstName) {
                          setDialogState(() =>
                              dialogError =
                                  'That doesn\'t match. Check your name and try again.');
                          return;
                        }

                        setDialogState(() => linking = true);
                        try {
                          await _linkStudent(student['id']);
                          if (mounted) {
                            Navigator.pop(ctx);
                            context.go('/home');
                          }
                        } catch (e) {
                          setDialogState(() {
                            linking = false;
                            dialogError = 'Could not link account. Try again.';
                          });
                        }
                      },
                child: const Text("That's me!"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _linkStudent(String rosterId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final meRes = await _supabase
        .from('users')
        .select('id')
        .eq('supabase_uid', user.id)
        .single();
    final userId = meRes['id'];
    await _supabase
        .from('school_students')
        .update({'user_id': userId, 'status': 'active', 'joined_at': DateTime.now().toIso8601String()})
        .eq('id', rosterId);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Row(
          children: [
            Text('Join your school ',
                style: TextStyle(
                    color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
            Text('🏫'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          if (_school == null) ...[
            const Text(
              'Enter the invite code from your teacher',
              style: TextStyle(color: Color(0xFF555577)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. ABC123',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _lookupCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4FE9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Find my school',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ] else ...[
            // School found — show student list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF5B4FE9), width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_box,
                      color: Color(0xFF5B4FE9), size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _school!['name'] ?? 'School',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A1A2E)),
                      ),
                      Text(
                        '${_students.length} students in your class',
                        style: const TextStyle(
                            color: Color(0xFF888AAA), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Which one is you?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 4),
            const Text(
              "Tap your name. You'll need to confirm by typing your first name — so don't guess!",
              style: TextStyle(color: Color(0xFF888AAA), fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'All students in this class are already linked. If you think this is wrong, ask your teacher.',
                  style: TextStyle(color: Color(0xFF888AAA)),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._students.map((s) {
                final name = s['student_name'] ?? '';
                final year = s['year_group'] ?? '';
                final isPending = _pendingStudent?['id'] == s['id'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor:
                          isPending ? const Color(0xFF5B4FE9) : const Color(0xFFEEECFF),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: isPending
                                ? Colors.white
                                : const Color(0xFF5B4FE9),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    subtitle: Text(year,
                        style: const TextStyle(
                            color: Color(0xFF888AAA), fontSize: 12)),
                    onTap: () => _onStudentTap(s),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
