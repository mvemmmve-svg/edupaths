// lib/features/quiz/screens/admin_quiz_tab.dart
// Drop this widget as a tab inside your existing AdminScreen.
// It lets admins create, edit and delete career quiz questions.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

class AdminQuizTab extends StatefulWidget {
  const AdminQuizTab({super.key});
  @override
  State<AdminQuizTab> createState() => _AdminQuizTabState();
}

class _AdminQuizTabState extends State<AdminQuizTab> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _careers = [];
  bool _loading = true;
  String _filterCareer = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final q = await _sb
          .from('career_quizzes')
          .select()
          .order('career_name')
          .order('sort_order');
      final c = await _sb
          .from('careers')
          .select('id, name')
          .order('name');
      setState(() {
        _questions = List<Map<String, dynamic>>.from(q as List);
        _careers = List<Map<String, dynamic>>.from(c as List);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _filterCareer.isEmpty
      ? _questions
      : _questions
          .where((q) => q['career_name']
              .toString()
              .toLowerCase()
              .contains(_filterCareer.toLowerCase()))
          .toList();

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await _sb.from('career_quizzes').delete().eq('id', id);
    _load();
  }

  void _openEditor({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizEditor(
        careers: _careers,
        existing: existing,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filter by career name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _filterCareer = v),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ]),
      ),

      // Stats
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _Chip('${_questions.length} total questions'),
          const SizedBox(width: 8),
          _Chip('${_questions.map((q) => q['career_name']).toSet().length} careers'),
        ]),
      ),
      const SizedBox(height: 12),

      // List
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty
                ? const Center(child: Text('No questions found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final q = _filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          title: Text(q['career_name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(q['question'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                'Answer: ${q['correct_answer']?.toString().toUpperCase()} · '
                                'Order: ${q['sort_order']}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _openEditor(existing: q),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              onPressed: () => _delete(q['id']),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      );
}

// ── Quiz Editor Bottom Sheet ──────────────────────────────────────────────────
class _QuizEditor extends StatefulWidget {
  final List<Map<String, dynamic>> careers;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _QuizEditor(
      {required this.careers, this.existing, required this.onSaved});

  @override
  State<_QuizEditor> createState() => _QuizEditorState();
}

class _QuizEditorState extends State<_QuizEditor> {
  final _sb = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _question;
  late final TextEditingController _optA;
  late final TextEditingController _optB;
  late final TextEditingController _optC;
  late final TextEditingController _explanation;
  late final TextEditingController _myth;
  late final TextEditingController _order;
  String _correctAnswer = 'a';
  String? _careerId;
  String _careerName = '';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _question = TextEditingController(text: e?['question'] ?? '');
    _optA = TextEditingController(text: e?['option_a'] ?? '');
    _optB = TextEditingController(text: e?['option_b'] ?? '');
    _optC = TextEditingController(text: e?['option_c'] ?? '');
    _explanation = TextEditingController(text: e?['explanation'] ?? '');
    _myth = TextEditingController(text: e?['myth_busted'] ?? '');
    _order = TextEditingController(text: (e?['sort_order'] ?? 0).toString());
    _correctAnswer = e?['correct_answer'] ?? 'a';
    _careerId = e?['career_id'];
    _careerName = e?['career_name'] ?? '';
  }

  @override
  void dispose() {
    for (final c in [_question, _optA, _optB, _optC, _explanation, _myth, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_careerId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a career')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'career_id': _careerId,
        'career_name': _careerName,
        'question': _question.text.trim(),
        'option_a': _optA.text.trim(),
        'option_b': _optB.text.trim(),
        'option_c': _optC.text.trim(),
        'correct_answer': _correctAnswer,
        'explanation': _explanation.text.trim(),
        'myth_busted': _myth.text.trim().isEmpty ? null : _myth.text.trim(),
        'sort_order': int.tryParse(_order.text) ?? 0,
        'is_active': true,
      };
      if (widget.existing != null) {
        await _sb
            .from('career_quizzes')
            .update(data)
            .eq('id', widget.existing!['id']);
      } else {
        await _sb.from('career_quizzes').insert(data);
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'Add Quiz Question' : 'Edit Quiz Question',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Career picker
              DropdownButtonFormField<String>(
                value: _careerId,
                decoration: _dec('Career'),
                items: widget.careers.map((c) => DropdownMenuItem(
                  value: c['id'] as String,
                  child: Text(c['name'] as String),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    _careerId = v;
                    _careerName = widget.careers
                        .firstWhere((c) => c['id'] == v)['name'] as String;
                  });
                },
              ),
              const SizedBox(height: 14),

              _field(_question, 'Question', maxLines: 3),
              const SizedBox(height: 14),
              _field(_optA, 'Option A'),
              const SizedBox(height: 10),
              _field(_optB, 'Option B'),
              const SizedBox(height: 10),
              _field(_optC, 'Option C'),
              const SizedBox(height: 14),

              // Correct answer
              const Text('Correct Answer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: ['a', 'b', 'c'].map((v) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(v.toUpperCase()),
                  selected: _correctAnswer == v,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _correctAnswer == v ? Colors.white : Colors.black),
                  onSelected: (_) => setState(() => _correctAnswer = v),
                ),
              )).toList()),
              const SizedBox(height: 14),

              _field(_explanation, 'Explanation (shown after answer)', maxLines: 3),
              const SizedBox(height: 10),
              _field(_myth, 'Myth busted (optional)', maxLines: 2),
              const SizedBox(height: 10),
              _field(_order, 'Sort order (0, 1, 2...)', keyboardType: TextInputType.number),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(widget.existing == null ? 'Add Question' : 'Save Changes',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _dec(label),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Required' : null,
      );
}
