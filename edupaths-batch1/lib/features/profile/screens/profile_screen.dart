// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/models.dart';
import '../../../core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../../core/services/auth_service.dart';
import '../../../core/services/db_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../../main.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final savedAsync = ref.watch(savedItemsProvider);
    final matchAsync = ref.watch(matchesProvider);
    final subAsync   = ref.watch(subscriptionProvider);
    final isLoggedIn = ref.watch(currentUidProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Avatar
          userAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
            data: (user) => Column(children: [
              Container(width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(24)),
                child: Center(child: Text(user?.initials ?? 'G',
                  style: const TextStyle(fontFamily: 'Nunito',
                    color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)))),
              const SizedBox(height: 12),
              Text(user?.displayName ?? 'Guest',
                style: Theme.of(context).textTheme.headlineMedium),
              Text(user?.email ?? 'Browse as guest',
                style: const TextStyle(fontFamily: 'Nunito',
                  fontSize: 13, color: AppColors.textMid)),
              const SizedBox(height: 6),
              subAsync.when(
                loading: () => const SizedBox(), error: (_, __) => const SizedBox(),
                data: (sub) {
                  if (sub?.isPremiumPlus == true) {
                    return const TagBadge(label: '👑 Premium+ Member',
                      bg: Color(0xFFFFF7E6), fg: Color(0xFFB45309));
                  } else if (sub?.isPremium == true) {
                    return const TagBadge(label: '⭐ Premium Member',
                      bg: Color(0xFFFFFBEB), fg: Color(0xFF92400E));
                  }
                  return GestureDetector(
                    onTap: () => context.push(AppConstants.routePricing),
                    child: const TagBadge(label: '🚀 Upgrade to Premium'));
                }),
            ]),
          ),
          const SizedBox(height: 20),

          // Stats (only if logged in)
          if (isLoggedIn) ...[
            Row(children: [
              Expanded(child: _Stat(
                value: savedAsync.valueOrNull?.length.toString() ?? '0',
                label: 'Saved', emoji: '🔖',
                bg: AppColors.primaryPale, fg: AppColors.primaryDark)),
              const SizedBox(width: 10),
              Expanded(child: _Stat(
                value: matchAsync.valueOrNull?.isNotEmpty == true
                    ? '${matchAsync.value!.first.matchScore}%' : '--',
                label: 'Top Match', emoji: '🎯',
                bg: const Color(0xFFECFDF5), fg: const Color(0xFF065F46))),
              const SizedBox(width: 10),
              Expanded(child: _Stat(
                value: matchAsync.valueOrNull?.length.toString() ?? '0',
                label: 'Matches', emoji: '⭐',
                bg: const Color(0xFFFFFBEB), fg: const Color(0xFF92400E))),
            ]),
            const SizedBox(height: 20),
          ],

          // Menu
          if (isLoggedIn) ...[
            _MenuItem(emoji: '👤', label: 'Account Details',
              onTap: () => _showPersonalInfo(context, ref)),
            // Advisor portal — only for advisor accounts (and admins)
            userAsync.when(
              loading: () => const SizedBox(), error: (_, __) => const SizedBox(),
              data: (user) => (user?.roleType == 'advisor' || user?.isAdmin == true)
                ? _MenuItem(emoji: '🏫', label: 'School Advisor Portal',
                    onTap: () => context.push('/school-advisor'))
                : const SizedBox()),
            _MenuItem(emoji: '🎯', label: 'Interests & Preferences',
              onTap: () => _editInterests(context, ref)),
            _MenuItem(emoji: '🗺️', label: 'My Roadmap',
              onTap: () => context.go(AppConstants.routeRoadmap)),
            _MenuItem(emoji: '🔖', label: 'Saved Items',
              onTap: () => context.go(AppConstants.routeSaved)),
            _MenuItem(emoji: '🔔', label: 'Notifications',
              onTap: () => context.push(AppConstants.routeNotifications)),
          ],

          _MenuItem(emoji: '⭐', label: 'Upgrade to Premium',
            onTap: () => context.push(AppConstants.routePricing),
            highlight: true),
          _MenuItem(emoji: '⚙️', label: 'Settings',
            onTap: () => _showSettings(context, ref)),

            _MenuItem(emoji: '📧', label: 'Contact Us',
              onTap: () => _showContactUs(context, ref)),
          // Admin panel — only for admin users
          userAsync.when(
            loading: () => const SizedBox(), error: (_, __) => const SizedBox(),
            data: (user) => user?.isAdmin == true
              ? _MenuItem(emoji: '🛠', label: 'Admin Panel',
                  onTap: () => context.push(AppConstants.routeAdmin))
              : const SizedBox()),

          const SizedBox(height: 8),

          // Login/logout
          if (!isLoggedIn) ...[
            PrimaryBtn(label: 'Sign Up — It\'s Free!',
              onPressed: () => context.push(AppConstants.routeSignup)),
            const SizedBox(height: 8),
            OutlineBtn(label: 'Log In',
              onPressed: () => context.push(AppConstants.routeLogin)),
          ] else
            EduCard(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                    title: const Text('Log Out?', style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
                    content: const Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(fontFamily: 'Nunito')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel', style: TextStyle(
                          fontFamily: 'Nunito', color: AppColors.textMid))),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Log Out', style: TextStyle(
                          fontFamily: 'Nunito', color: AppColors.error,
                          fontWeight: FontWeight.w800))),
                    ]));
                if (confirmed != true) return;
                await AuthService.signOut();
                // Force all providers to reset so new user gets clean state
                ref.invalidate(appUserProvider);
                ref.invalidate(matchesProvider);
                ref.invalidate(savedItemsProvider);
                ref.invalidate(subscriptionProvider);
                ref.invalidate(onboardingProvider);
                ref.invalidate(allCareersProvider);
                // Wait for auth state to propagate before navigating
                await Future.delayed(const Duration(milliseconds: 300));
                if (context.mounted) context.go(AppConstants.routeSplash);
              },
              padding: const EdgeInsets.all(16),
              child: const Row(children: [
                Text('🚪', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Text('Log Out', style: TextStyle(fontFamily: 'Nunito',
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
              ])),
          const SizedBox(height: 80),
        ]),
      )),
    );
  }

  void _showPersonalInfo(BuildContext context, WidgetRef ref) {
    final user = ref.read(appUserProvider).valueOrNull;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Account Details', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _InfoRow('Full Name', user?.displayName ?? 'Not set'),
          _InfoRow('Email', user?.email ?? 'Not set'),
          _InfoRow('School Year', user?.schoolYear ?? 'Not set'),
          _InfoRow('Account Type', user?.roleType ?? 'student'),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Future<void> _editInterests(BuildContext context, WidgetRef ref) async {
    // Check weekly limit for free users
    final isPrem = ref.read(isPremiumProvider).valueOrNull ?? false;
    if (!isPrem) {
      final user = ref.read(appUserProvider).valueOrNull;
      if (user != null) {
        final count = user.interestsChangedCount ?? 0;
        final lastChanged = user.interestsLastChanged;
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        if (count >= 2 && lastChanged != null && lastChanged.isAfter(weekAgo)) {
          showDialog(context: context, builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Weekly Limit Reached', style: TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
            content: const Text(
              "Free users can change interests & traits up to 2 times per week.\n\nUpgrade to Premium for unlimited changes.",
              style: TextStyle(fontFamily: 'Nunito')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
              TextButton(
                onPressed: () { Navigator.pop(ctx); context.push(AppConstants.routePricing); },
                child: const Text('Upgrade', style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w800))),
            ]));
          return;
        }
      }
    }
    // Show a bottom sheet to edit interests and traits, then regenerate matches
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => _EditInterestsSheet(scrollController: ctrl),
      ),
    ).then((_) async {
      // Regenerate matches when sheet closes
      if (!context.mounted) return;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await DbService.generateMatches([]);
        ref.invalidate(matchesProvider);
        ref.invalidate(appUserProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Matches updated!'),
            backgroundColor: AppColors.success));
        }
      }
    });
  }


  void _showContactUs(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(margin: const EdgeInsets.only(bottom: 20),
            alignment: Alignment.center,
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2)))),
          const Text('Contact Us', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Having trouble logging in or using EduPaths? We are here to help.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
              color: AppColors.textMid)),
          const SizedBox(height: 20),
          EduCard(child: Column(children: [
            _ContactRow(emoji: '📧', label: 'General Support',
              value: 'support@edupaths.co.uk'),
            const Divider(height: 1),
            _ContactRow(emoji: '🐛', label: 'Report a Bug',
              value: 'bugs@edupaths.co.uk'),
            const Divider(height: 1),
            _ContactRow(emoji: '💬', label: 'General Enquiries',
              value: 'hello@edupaths.co.uk'),
            const Divider(height: 1),
            _ContactRow(emoji: '🏫', label: 'School Partnerships',
              value: 'schools@edupaths.co.uk'),
          ])),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(child: Text(
                'For login issues, use the Forgot Password link on the login page to reset your password.',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  color: AppColors.textMid, height: 1.4))),
            ])),
          const SizedBox(height: 16),
        ])));
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Settings', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _SettingRow(emoji: '🔒', label: 'Privacy Policy',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
              onTap: () {}),
            _SettingRow(emoji: '📋', label: 'Terms of Service',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
              onTap: () {}),
            _SettingRow(emoji: '⭐', label: 'Rate EduPaths',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
              onTap: () {}),
            const SizedBox(height: 10),
            const Center(child: Text('Version 1.0.0',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textLight))),
            const SizedBox(height: 10),
          ]),
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 13, color: AppColors.textMid,
        fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(
        fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700))),
    ]));
}

class _SettingRow extends StatelessWidget {
  final String emoji, label;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingRow({required this.emoji, required this.label,
    required this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700))),
        trailing,
      ])));
}

class _Stat extends StatelessWidget {
  final String value, label, emoji;
  final Color bg, fg;
  const _Stat({required this.value, required this.label,
    required this.emoji, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontFamily: 'Nunito',
        fontSize: 20, fontWeight: FontWeight.w900, color: fg)),
      Text(label, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 10, color: AppColors.textMid, fontWeight: FontWeight.w600)),
    ]));
}

class _MenuItem extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  final bool highlight;
  const _MenuItem({required this.emoji, required this.label,
    required this.onTap, this.highlight = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: EduCard(onTap: onTap, padding: const EdgeInsets.all(16),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontFamily: 'Nunito',
          fontSize: 14, fontWeight: FontWeight.w700,
          color: highlight ? AppColors.primary : AppColors.textDark))),
        Icon(Icons.chevron_right_rounded,
          color: highlight ? AppColors.primary : AppColors.textLight),
      ])));
}

// ══════════════════════════════════════════════
// EDIT INTERESTS SHEET
// ══════════════════════════════════════════════
class _EditInterestsSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _EditInterestsSheet({required this.scrollController});
  @override
  ConsumerState<_EditInterestsSheet> createState() => _EditInterestsSheetState();
}

class _EditInterestsSheetState extends ConsumerState<_EditInterestsSheet> {
  Set<String> _selectedInterestIds = {};
  Set<String> _selectedTraitIds = {};
  bool _loading = true;
  bool _saving = false;
  int _tab = 0; // 0 = interests, 1 = traits

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    
    // Load existing interests
    final user = await DbService.getUserByUid(uid);
    if (user == null) { setState(() => _loading = false); return; }
    
    final interests = await Supabase.instance.client
        .from('user_interest').select('interest_id').eq('user_id', user.id);
    final traits = await Supabase.instance.client
        .from('user_trait').select('trait_id').eq('user_id', user.id);
    
    setState(() {
      _selectedInterestIds = Set<String>.from(
          (interests as List).map((e) => e['interest_id'] as String));
      _selectedTraitIds = Set<String>.from(
          (traits as List).map((e) => e['trait_id'] as String));
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final user = await DbService.getUserByUid(uid);
    if (user == null) return;
    
    await Future.wait([
      DbService.saveUserInterests(user.id, _selectedInterestIds.toList()),
      DbService.saveUserTraits(user.id, _selectedTraitIds.toList()),
    ]);
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final interestsAsync = ref.watch(interestsProvider);
    final traitsAsync = ref.watch(traitsProvider);

    return Column(children: [
      // Handle
      Container(margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40, height: 4,
        decoration: BoxDecoration(color: AppColors.border,
          borderRadius: BorderRadius.circular(2))),
      // Header
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Edit Interests & Strengths', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900)),
          Row(children: [
            TextButton(
              onPressed: () {
                setState(() {
                  if (_tab == 0) _selectedInterestIds.clear();
                  else _selectedTraitIds.clear();
                });
              },
              child: const Text('Clear All', style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.error))),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppColors.primary))),
          ]),
        ])),
      // Tab selector
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _tab = 0),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _tab == 0 ? AppColors.primary : AppColors.bgGrey,
                borderRadius: BorderRadius.circular(10)),
              child: Text('Interests (${_selectedInterestIds.length})',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _tab == 0 ? Colors.white : AppColors.textMid))))),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _tab = 1),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _tab == 1 ? AppColors.primary : AppColors.bgGrey,
                borderRadius: BorderRadius.circular(10)),
              child: Text('Strengths (${_selectedTraitIds.length})',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _tab == 1 ? Colors.white : AppColors.textMid))))),
        ])),
      const Divider(height: 1),
      // Content
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tab == 0
              ? _buildInterests(interestsAsync)
              : _buildTraits(traitsAsync)),
    ]);
  }

  Widget _buildInterests(AsyncValue<List<Interest>> interestsAsync) {
    return interestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (interests) {
        final byCategory = <String, List<Interest>>{};
        for (final i in interests) {
          byCategory.putIfAbsent(i.category ?? 'Other', () => []).add(i);
        }
        return ListView(controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          children: byCategory.entries.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(e.key.toUpperCase(), style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.textLight, letterSpacing: 0.8))),
            Wrap(spacing: 8, runSpacing: 8, children: e.value.map((i) {
              final sel = _selectedInterestIds.contains(i.id);
              return GestureDetector(
                onTap: () => setState(() => sel
                    ? _selectedInterestIds.remove(i.id)
                    : _selectedInterestIds.add(i.id)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border)),
                  child: Text(i.trimmed, style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textMid))));
            }).toList()),
          ])).toList());
      },
    );
  }

  Widget _buildTraits(AsyncValue<List<Trait>> traitsAsync) {
    return traitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (traits) {
        final byCategory = <String, List<Trait>>{};
        for (final t in traits) {
          byCategory.putIfAbsent(t.category ?? 'Other', () => []).add(t);
        }
        return ListView(controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          children: byCategory.entries.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(e.key.toUpperCase(), style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.textLight, letterSpacing: 0.8))),
            ...e.value.map((t) {
              final sel = _selectedTraitIds.contains(t.id);
              return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => sel
                      ? _selectedTraitIds.remove(t.id)
                      : _selectedTraitIds.add(t.id)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryPale : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border,
                        width: sel ? 2 : 1.5)),
                    child: Row(children: [
                      Expanded(child: Text(t.trimmed, style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600,
                        color: sel ? AppColors.primary : AppColors.textDark))),
                      if (sel) const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 18),
                    ]))));
            }),
          ])).toList());
      },
    );
  }
}


class _ContactRow extends StatelessWidget {
  final String emoji, label, value;
  const _ContactRow({required this.emoji, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(label, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 13, fontWeight: FontWeight.w700)),
        Text(value, style: const TextStyle(fontFamily: 'Nunito',
          fontSize: 12, color: AppColors.primary)),
      ])),
    ]));
}
