// lib/features/profile/screens/profile_edit_sheet.dart
// Floating bottom sheet — user can edit their name and school year.
// Saves to DB via update_my_profile RPC.
// 
// USAGE: call from your ProfileScreen:
//   showModalBottomSheet(context: context, isScrollControlled: true,
//     builder: (_) => ProfileEditSheet(
//       currentName: userName, currentYear: schoolYear,
//       onSaved: () => setState(() { /* reload */ })));

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEditSheet extends StatefulWidget {
  final String currentName;
  final String? currentYear;
  final VoidCallback onSaved;

  const ProfileEditSheet({
    super.key,
    required this.currentName,
    this.currentYear,
    required this.onSaved,
  });

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  final _supabase = Supabase.instance.client;
  late final TextEditingController _nameCtrl;
  String? _selectedYear;
  bool _saving = false;
  String? _error;

  static const _years = [
    'Year 9', 'Year 10', 'Year 11',
    'Year 12', 'Year 13',
    'Post-16', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
    _selectedYear = widget.currentYear;
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _supabase.rpc('update_my_profile', params: {
        'p_name': name,
        'p_school_year': _selectedYear ?? '',
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      setState(() { _saving = false; _error = 'Could not save. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle bar
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Name field
          const Text('Your name', style: TextStyle(fontSize: 13, color: Colors.black54,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true, fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 20),

          // Year group
          const Text('Year group', style: TextStyle(fontSize: 13, color: Colors.black54,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _years.map((y) {
            final selected = _selectedYear == y;
            return GestureDetector(
              onTap: () => setState(() => _selectedYear = y),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF6C63FF) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(y, style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.white : Colors.black87,
                    fontSize: 13)),
              ),
            );
          }).toList()),

          const SizedBox(height: 28),

          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save changes', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }
}
