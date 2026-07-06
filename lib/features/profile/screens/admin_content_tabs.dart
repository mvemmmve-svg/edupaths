// lib/features/profile/screens/admin_content_tabs.dart
//
// ADMIN — CONTENT MANAGEMENT TABS
// 💼 Careers: add / edit / delete careers, salaries, categories,
//    descriptions, and manage their interest + trait links (with scores)
//    so matching works — all without touching the database directly.
// 📋 Quals: add / edit / delete qualifications (GCSE, A-Level, BTEC,
//    T-Level) and link them to courses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

final _sb = Supabase.instance.client;

// ── Providers ──────────────────────────────────────────────────
final adminCareersListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('careers')
      .select('id, name, category, avg_salary, description')
      .order('name');
  return (res as List).cast<Map<String, dynamic>>();
});

final adminInterestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('interests').select('id, name').order('name');
  return (res as List).cast<Map<String, dynamic>>();
});

final adminTraitsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('trait').select('id, name').order('name');
  return (res as List).cast<Map<String, dynamic>>();
});

final adminPreclassProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('preclass')
      .select('id, title, type, level').order('type').order('title');
  return (res as List).cast<Map<String, dynamic>>();
});

final adminCoursesLiteProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('courses')
      .select('id, title, institutions(name)').order('title');
  return (res as List).cast<Map<String, dynamic>>();
});

// ══════════════════════════════════════════════
// 💼 CAREERS TAB
// ══════════════════════════════════════════════
class CareersAdminTab extends ConsumerStatefulWidget {
  const CareersAdminTab({super.key});
  @override
  ConsumerState<CareersAdminTab> createState() => _CareersAdminTabState();
}

class _CareersAdminTabState extends ConsumerState<CareersAdminTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final careersAsync = ref.watch(adminCareersListProvider);
    return careersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (careers) {
        final cats = careers.map((c) => (c['category'] ?? '') as String)
            .where((c) => c.isNotEmpty).toSet().toList()..sort();
        var list = careers;
        if (_search.isNotEmpty) {
          list = careers.where((c) =>
            (c['name'] ?? '').toString().toLowerCase()
              .contains(_search.toLowerCase()) ||
            (c['category'] ?? '').toString().toLowerCase()
              .contains(_search.toLowerCase())).toList();
        }
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Expanded(child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search ${careers.length} careers…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10)))),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openEditor(context, null, cats),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 12, fontWeight: FontWeight.w800))),
            ])),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EduCard(
                  onTap: () => _openEditor(context, c, cats),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(c['name'] ?? '', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w800)),
                      Text('${c['category'] ?? '—'}  ·  ${c['avg_salary'] ?? 'no salary'}',
                        style: const TextStyle(fontFamily: 'Nunito',
                          fontSize: 11, color: AppColors.textMid)),
                    ])),
                    const Icon(Icons.edit_rounded,
                      size: 16, color: AppColors.textLight),
                  ])));
            })),
        ]);
      });
  }

  void _openEditor(BuildContext context,
      Map<String, dynamic>? career, List<String> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPage,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CareerEditor(
        career: career, categories: categories,
        onSaved: () => ref.invalidate(adminCareersListProvider)));
  }
}

// ── Career editor sheet ────────────────────────────────────────
class _CareerEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? career; // null = create new
  final List<String> categories;
  final VoidCallback onSaved;
  const _CareerEditor({required this.career, required this.categories,
    required this.onSaved});
  @override
  ConsumerState<_CareerEditor> createState() => _CareerEditorState();
}

class _CareerEditorState extends ConsumerState<_CareerEditor> {
  late final TextEditingController _name;
  late final TextEditingController _salary;
  late final TextEditingController _desc;
  late String _category;
  bool _saving = false;
  List<Map<String, dynamic>>? _interestLinks; // interest_career rows + name
  List<Map<String, dynamic>>? _traitLinks;

  bool get isNew => widget.career == null;
  String? get careerId => widget.career?['id'] as String?;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.career?['name'] ?? '');
    _salary = TextEditingController(
        text: widget.career?['avg_salary'] ?? '£25,000 – £45,000');
    _desc = TextEditingController(text: widget.career?['description'] ?? '');
    _category = widget.career?['category'] as String? ??
        (widget.categories.isNotEmpty ? widget.categories.first : 'Technology');
    if (!isNew) _loadLinks();
  }

  Future<void> _loadLinks() async {
    final ints = await _sb.from('interest_career')
        .select('id, score, interests(id, name)')
        .eq('career_id', careerId!);
    final trs = await _sb.from('trait_career')
        .select('id, score, trait(id, name)')
        .eq('career_id', careerId!);
    if (mounted) {
      setState(() {
        _interestLinks = (ints as List).cast<Map<String, dynamic>>();
        _traitLinks = (trs as List).cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': name,
        'category': _category,
        'avg_salary': _salary.text.trim(),
        'description': _desc.text.trim(),
      };
      if (isNew) {
        await _sb.from('careers').insert(data);
      } else {
        await _sb.from('careers').update(data).eq('id', careerId!);
      }
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isNew ? 'Career added ✓' : 'Career updated ✓'),
          backgroundColor: AppColors.success));
        if (isNew) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final sure = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Delete career?', style: TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Text(
          'This permanently removes "${_name.text}" plus its interest, '
          'trait, course and qualification links, and any user matches to it.',
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
              style: TextStyle(color: AppColors.error))),
        ]));
    if (sure != true) return;
    setState(() => _saving = true);
    try {
      final id = careerId!;
      // Clean up every table that references this career first
      await _sb.from('interest_career').delete().eq('career_id', id);
      await _sb.from('trait_career').delete().eq('career_id', id);
      await _sb.from('career_course').delete().eq('career_id', id);
      await _sb.from('career_preclass').delete().eq('career_id', id);
      try {
        await _sb.from('matches').delete().eq('career_id', id);
      } catch (_) {}
      try {
        await _sb.from('career_feedback').delete().eq('career_id', id);
      } catch (_) {}
      await _sb.from('careers').delete().eq('id', id);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Link management ──
  Future<void> _addLink(bool isInterest) async {
    List<Map<String, dynamic>> options;
    try {
      options = isInterest
          ? await ref.read(adminInterestsProvider.future)
          : await ref.read(adminTraitsProvider.future);
    } catch (_) {
      options = [];
    }
    final existing = (isInterest ? _interestLinks : _traitLinks) ?? [];
    final linkedIds = existing.map((l) =>
        (l[isInterest ? 'interests' : 'trait'] as Map?)?['id']).toSet();
    final available =
        options.where((o) => !linkedIds.contains(o['id'])).toList();
    if (available.isEmpty || !mounted) return;

    String? pickedId = available.first['id'] as String;
    double score = 0.8;
    final ok = await showDialog<bool>(context: context, builder: (ctx) =>
      StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text('Link ${isInterest ? 'interest' : 'trait'}',
          style: const TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: pickedId,
            isExpanded: true,
            items: available.map((o) => DropdownMenuItem(
              value: o['id'] as String,
              child: Text(o['name'] ?? '', style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13)))).toList(),
            onChanged: (v) => setD(() => pickedId = v)),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Score', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              fontWeight: FontWeight.w700)),
            Expanded(child: Slider(
              value: score, min: 0.5, max: 1.0, divisions: 10,
              label: score.toStringAsFixed(2),
              onChanged: (v) => setD(() => score = v))),
            Text(score.toStringAsFixed(2), style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12)),
          ]),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add')),
        ])));
    if (ok != true || pickedId == null) return;
    await _sb.from(isInterest ? 'interest_career' : 'trait_career').insert({
      isInterest ? 'interest_id' : 'trait_id': pickedId,
      'career_id': careerId,
      'score': double.parse(score.toStringAsFixed(2)),
    });
    _loadLinks();
  }

  Future<void> _removeLink(bool isInterest, String linkId) async {
    await _sb.from(isInterest ? 'interest_career' : 'trait_career')
        .delete().eq('id', linkId);
    _loadLinks();
  }

  Widget _linkSection(String title, bool isInterest,
      List<Map<String, dynamic>>? links) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 13, fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _addLink(isInterest),
          icon: const Icon(Icons.add_rounded, size: 14),
          label: const Text('Add', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 11,
            fontWeight: FontWeight.w800))),
      ]),
      if (links == null)
        const Padding(padding: EdgeInsets.all(8),
          child: Center(child: SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))))
      else if (links.isEmpty)
        const Text('No links yet — this career won\'t appear in matches.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
            color: AppColors.error))
      else
        Wrap(spacing: 6, runSpacing: 6, children: links.map((l) {
          final rel = l[isInterest ? 'interests' : 'trait'] as Map?;
          return Chip(
            label: Text('${rel?['name'] ?? '?'}  ${l['score']}',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 11,
                fontWeight: FontWeight.w700)),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            onDeleted: () => _removeLink(isInterest, l['id'] as String),
            backgroundColor: AppColors.primaryPale,
            visualDensity: VisualDensity.compact);
        }).toList()),
      const SizedBox(height: 14),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false, initialChildSize: 0.9, maxChildSize: 0.95,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(isNew ? 'Add Career 💼' : 'Edit Career 💼',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 18,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: _name, decoration: const InputDecoration(
              labelText: 'Career name')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: widget.categories.contains(_category)
                  ? _category : null,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories.map((c) => DropdownMenuItem(
                value: c, child: Text(c, style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category)),
            const SizedBox(height: 10),
            TextField(controller: _salary, decoration: const InputDecoration(
              labelText: 'Salary range (e.g. £25,000 – £45,000)')),
            const SizedBox(height: 10),
            TextField(controller: _desc, maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (teen-friendly, 1–2 sentences)')),
            const SizedBox(height: 16),
            PrimaryBtn(
              label: _saving ? 'Saving…' : (isNew ? 'Create Career' : 'Save Changes'),
              onPressed: _saving ? null : _save),
            if (!isNew) ...[
              const Divider(height: 28),
              _linkSection('🎯 Interest links (drives matching)',
                true, _interestLinks),
              _linkSection('⭐ Trait links', false, _traitLinks),
              const SizedBox(height: 4),
              Center(child: TextButton(
                onPressed: _saving ? null : _delete,
                child: const Text('🗑 Delete this career',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                    fontWeight: FontWeight.w800, color: AppColors.error)))),
            ],
            const SizedBox(height: 30),
          ]))));
  }
}

// ══════════════════════════════════════════════
// 📋 QUALIFICATIONS TAB
// ══════════════════════════════════════════════
class QualsAdminTab extends ConsumerStatefulWidget {
  const QualsAdminTab({super.key});
  @override
  ConsumerState<QualsAdminTab> createState() => _QualsAdminTabState();
}

class _QualsAdminTabState extends ConsumerState<QualsAdminTab> {
  String _type = 'GCSE';
  static const _types = ['GCSE', 'A-Level', 'BTEC', 'T-Level'];

  @override
  Widget build(BuildContext context) {
    final asyncQuals = ref.watch(adminPreclassProvider);
    return asyncQuals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (quals) {
        final list = quals.where((q) => q['type'] == _type).toList();
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Expanded(child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _types.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(t, style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 11,
                      fontWeight: FontWeight.w800)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t)),
                )).toList()))),
              ElevatedButton.icon(
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 12, fontWeight: FontWeight.w800))),
            ])),
          Expanded(child: list.isEmpty
            ? const EmptyState(emoji: '📋', title: 'No qualifications',
                subtitle: 'Add one with the + button')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final q = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: EduCard(
                      onTap: () => _openEditor(context, q),
                      child: Row(children: [
                        Expanded(child: Text(q['title'] ?? '',
                          style: const TextStyle(fontFamily: 'Nunito',
                            fontSize: 13, fontWeight: FontWeight.w700))),
                        TagBadge(label: q['level'] ?? '',
                          bg: AppColors.primaryPale,
                          fg: AppColors.primaryDark),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.textLight),
                      ])));
                })),
        ]);
      });
  }

  void _openEditor(BuildContext context, Map<String, dynamic>? qual) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPage,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _QualEditor(
        qual: qual, defaultType: _type,
        onSaved: () => ref.invalidate(adminPreclassProvider)));
  }
}

class _QualEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? qual;
  final String defaultType;
  final VoidCallback onSaved;
  const _QualEditor({required this.qual, required this.defaultType,
    required this.onSaved});
  @override
  ConsumerState<_QualEditor> createState() => _QualEditorState();
}

class _QualEditorState extends ConsumerState<_QualEditor> {
  late final TextEditingController _title;
  late final TextEditingController _level;
  late String _type;
  bool _saving = false;
  List<Map<String, dynamic>>? _courseLinks;

  bool get isNew => widget.qual == null;
  String? get qualId => widget.qual?['id'] as String?;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.qual?['title'] ?? '');
    _level = TextEditingController(text: widget.qual?['level'] ?? 'Level 2');
    _type = widget.qual?['type'] as String? ?? widget.defaultType;
    if (!isNew) _loadLinks();
  }

  Future<void> _loadLinks() async {
    final res = await _sb.from('preclass_course')
        .select('id, courses(id, title)')
        .eq('from_preclass', qualId!);
    if (mounted) {
      setState(() =>
          _courseLinks = (res as List).cast<Map<String, dynamic>>());
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title': _title.text.trim(),
        'type': _type,
        'level': _level.text.trim(),
      };
      if (isNew) {
        await _sb.from('preclass').insert(data);
      } else {
        await _sb.from('preclass').update(data).eq('id', qualId!);
      }
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved ✓'), backgroundColor: AppColors.success));
        if (isNew) Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final sure = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Delete qualification?', style: TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: const Text('Removes it and its course/career links.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
              style: TextStyle(color: AppColors.error))),
        ]));
    if (sure != true) return;
    setState(() => _saving = true);
    try {
      await _sb.from('preclass_course').delete().eq('from_preclass', qualId!);
      await _sb.from('career_preclass').delete().eq('preclass_id', qualId!);
      await _sb.from('preclass').delete().eq('id', qualId!);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCourseLink() async {
    List<Map<String, dynamic>> courses;
    try {
      courses = await ref.read(adminCoursesLiteProvider.future);
    } catch (_) {
      courses = [];
    }
    final linked = (_courseLinks ?? [])
        .map((l) => (l['courses'] as Map?)?['id']).toSet();
    final available =
        courses.where((c) => !linked.contains(c['id'])).toList();
    if (!mounted) return;
    String filter = '';
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        final shown = available.where((c) => (c['title'] ?? '').toString()
            .toLowerCase().contains(filter.toLowerCase())).toList();
        return AlertDialog(
          title: const Text('Link a course', style: TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
          content: SizedBox(width: double.maxFinite, height: 320,
            child: Column(children: [
              TextField(
                onChanged: (v) => setD(() => filter = v),
                decoration: const InputDecoration(
                  hintText: 'Search courses…', isDense: true)),
              const SizedBox(height: 8),
              Expanded(child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(shown[i]['title'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    (shown[i]['institutions'] as Map?)?['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 11)),
                  onTap: () => Navigator.pop(ctx, shown[i])))),
            ])),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'))]);
      }));
    if (picked == null) return;
    await _sb.from('preclass_course').insert({
      'from_preclass': qualId, 'to_course': picked['id']});
    _loadLinks();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false, initialChildSize: 0.8, maxChildSize: 0.95,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(isNew ? 'Add Qualification 📋' : 'Edit Qualification 📋',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 18,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: _title, decoration: const InputDecoration(
              labelText: 'Title (e.g. GCSE Computer Science)')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const ['GCSE', 'A-Level', 'BTEC', 'T-Level']
                  .map((t) => DropdownMenuItem(value: t,
                    child: Text(t, style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type)),
            const SizedBox(height: 10),
            TextField(controller: _level, decoration: const InputDecoration(
              labelText: 'Level (e.g. Level 2, Level 3)')),
            const SizedBox(height: 16),
            PrimaryBtn(
              label: _saving ? 'Saving…' : (isNew ? 'Create' : 'Save Changes'),
              onPressed: _saving ? null : _save),
            if (!isNew) ...[
              const Divider(height: 28),
              Row(children: [
                const Text('🎓 Linked courses', style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addCourseLink,
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Add', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 11,
                    fontWeight: FontWeight.w800))),
              ]),
              if (_courseLinks == null)
                const Center(child: CircularProgressIndicator())
              else if (_courseLinks!.isEmpty)
                const Text('No course links yet.',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
                    color: AppColors.textMid))
              else
                ..._courseLinks!.map((l) => ListTile(
                  dense: true, contentPadding: EdgeInsets.zero,
                  title: Text((l['courses'] as Map?)?['title'] ?? '',
                    style: const TextStyle(fontFamily: 'Nunito',
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.error),
                    onPressed: () async {
                      await _sb.from('preclass_course')
                          .delete().eq('id', l['id']);
                      _loadLinks();
                    }))),
              const SizedBox(height: 4),
              Center(child: TextButton(
                onPressed: _saving ? null : _delete,
                child: const Text('🗑 Delete this qualification',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                    fontWeight: FontWeight.w800, color: AppColors.error)))),
            ],
            const SizedBox(height: 30),
          ]))));
  }
}

// ══════════════════════════════════════════════
// 🏛️ INSTITUTIONS TAB — edit/delete (fixes typos you couldn't before)
// ══════════════════════════════════════════════
final adminInstitutionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('institutions')
      .select('id, name, type, city, location, website_url').order('name');
  return (res as List).cast<Map<String, dynamic>>();
});

class InstitutionsAdminTab extends ConsumerStatefulWidget {
  const InstitutionsAdminTab({super.key});
  @override
  ConsumerState<InstitutionsAdminTab> createState() => _InstitutionsAdminTabState();
}

class _InstitutionsAdminTabState extends ConsumerState<InstitutionsAdminTab> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final asyncInsts = ref.watch(adminInstitutionsProvider);
    return asyncInsts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (insts) {
        var list = insts;
        if (_search.isNotEmpty) {
          list = insts.where((it) => (it['name'] ?? '').toString()
              .toLowerCase().contains(_search.toLowerCase())).toList();
        }
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Expanded(child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search ${insts.length} institutions…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10)))),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontFamily: 'Nunito',
                    fontSize: 12, fontWeight: FontWeight.w800))),
            ])),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final it = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EduCard(
                  onTap: () => _openEditor(context, it),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it['name'] ?? '', style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w800)),
                      Text('${it['type'] ?? '—'}  ·  ${it['city'] ?? it['location'] ?? 'no location'}',
                        style: const TextStyle(fontFamily: 'Nunito',
                          fontSize: 11, color: AppColors.textMid)),
                    ])),
                    const Icon(Icons.edit_rounded, size: 16,
                      color: AppColors.textLight),
                  ])));
            })),
        ]);
      });
  }

  void _openEditor(BuildContext context, Map<String, dynamic>? inst) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.bgPage,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _InstitutionEditor(
        inst: inst,
        onSaved: () => ref.invalidate(adminInstitutionsProvider)));
  }
}

class _InstitutionEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic>? inst;
  final VoidCallback onSaved;
  const _InstitutionEditor({required this.inst, required this.onSaved});
  @override
  ConsumerState<_InstitutionEditor> createState() => _InstitutionEditorState();
}

class _InstitutionEditorState extends ConsumerState<_InstitutionEditor> {
  late final TextEditingController _name, _city, _location, _url;
  late String _type;
  bool _saving = false;
  bool get isNew => widget.inst == null;
  String? get id => widget.inst?['id'] as String?;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.inst?['name'] ?? '');
    _city = TextEditingController(text: widget.inst?['city'] ?? '');
    _location = TextEditingController(text: widget.inst?['location'] ?? '');
    _url = TextEditingController(text: widget.inst?['website_url'] ?? '');
    _type = widget.inst?['type'] as String? ?? 'University';
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'type': _type,
        'city': _city.text.trim(),
        'location': _location.text.trim(),
        'website_url': _url.text.trim(),
      };
      if (isNew) {
        await _sb.from('institutions').insert(data);
      } else {
        await _sb.from('institutions').update(data).eq('id', id!);
      }
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved ✓'), backgroundColor: AppColors.success));
        if (isNew) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    // Block delete if courses still reference it (would orphan them)
    final courses = await _sb.from('courses')
        .select('id').eq('institution_id', id!).limit(1);
    if ((courses as List).isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Can\'t delete — courses still use this institution. '
          'Reassign or delete those courses first.'),
        backgroundColor: AppColors.error));
      return;
    }
    final sure = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Delete institution?', style: TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: Text('Remove "${_name.text}"?',
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
              style: TextStyle(color: AppColors.error))),
        ]));
    if (sure != true) return;
    await _sb.from('institutions').delete().eq('id', id!);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(isNew ? 'Add Institution 🏛️' : 'Edit Institution 🏛️',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 18,
                fontWeight: FontWeight.w900))),
            IconButton(icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(
            labelText: 'Name')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: const ['University','College','Apprenticeship','Sixth Form','Other']
                .contains(_type) ? _type : 'Other',
            decoration: const InputDecoration(labelText: 'Type'),
            items: const ['University','College','Apprenticeship','Sixth Form','Other']
                .map((t) => DropdownMenuItem(value: t, child: Text(t,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _type = v ?? _type)),
          const SizedBox(height: 10),
          TextField(controller: _city, decoration: const InputDecoration(
            labelText: 'City')),
          const SizedBox(height: 10),
          TextField(controller: _location, decoration: const InputDecoration(
            labelText: 'Region / location')),
          const SizedBox(height: 10),
          TextField(controller: _url, decoration: const InputDecoration(
            labelText: 'Website URL')),
          const SizedBox(height: 16),
          PrimaryBtn(label: _saving ? 'Saving…' : (isNew ? 'Create' : 'Save Changes'),
            onPressed: _saving ? null : _save),
          if (!isNew) Center(child: TextButton(
            onPressed: _saving ? null : _delete,
            child: const Text('🗑 Delete this institution',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                fontWeight: FontWeight.w800, color: AppColors.error)))),
          const SizedBox(height: 20),
        ])));
  }
}

// ══════════════════════════════════════════════
// 📢 BROADCAST TAB — send an announcement to all users
// ══════════════════════════════════════════════
final adminBroadcastsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await _sb.from('notifications')
      .select('id, title, body, category, created_at')
      .eq('is_global', true)
      .order('created_at', ascending: false).limit(20);
  return (res as List).cast<Map<String, dynamic>>();
});

class BroadcastAdminTab extends ConsumerStatefulWidget {
  const BroadcastAdminTab({super.key});
  @override
  ConsumerState<BroadcastAdminTab> createState() => _BroadcastAdminTabState();
}

class _BroadcastAdminTabState extends ConsumerState<BroadcastAdminTab> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _category = 'general';
  bool _sending = false;

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    final sure = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Send to everyone?', style: TextStyle(
          fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
        content: const Text('This notification appears for ALL users. '
          'Send it now?', style: TextStyle(fontFamily: 'Nunito', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send')),
        ]));
    if (sure != true) return;
    setState(() => _sending = true);
    try {
      await _sb.from('notifications').insert({
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'category': _category,
        'is_global': true,
      });
      _title.clear(); _body.clear();
      ref.invalidate(adminBroadcastsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📢 Broadcast sent to all users!'),
        backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(adminBroadcastsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Send an announcement 📢', style: TextStyle(
          fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Goes to every user\'s notification bell.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 12.5,
            color: AppColors.textMid)),
        const SizedBox(height: 14),
        TextField(controller: _title, decoration: const InputDecoration(
          labelText: 'Title (e.g. New feature: Career Quiz!)')),
        const SizedBox(height: 10),
        TextField(controller: _body, maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: const ['general','feature','deadline','tip']
              .map((c) => DropdownMenuItem(value: c, child: Text(c,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _category = v ?? 'general')),
        const SizedBox(height: 16),
        PrimaryBtn(label: _sending ? 'Sending…' : '📢 Send to all users',
          onPressed: _sending ? null : _send),
        const Divider(height: 32),
        const Text('Recent broadcasts', style: TextStyle(
          fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        recent.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (list) => list.isEmpty
            ? const Text('None yet.', style: TextStyle(fontFamily: 'Nunito',
                fontSize: 12, color: AppColors.textMid))
            : Column(children: list.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EduCard(child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['title'] ?? '', style: const TextStyle(
                      fontFamily: 'Nunito', fontSize: 13,
                      fontWeight: FontWeight.w800)),
                    Text(n['body'] ?? '', maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Nunito',
                        fontSize: 11.5, color: AppColors.textMid)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                    onPressed: () async {
                      await _sb.from('notifications').delete().eq('id', n['id']);
                      ref.invalidate(adminBroadcastsProvider);
                    }),
                ])))).toList())),
      ]));
  }
}
