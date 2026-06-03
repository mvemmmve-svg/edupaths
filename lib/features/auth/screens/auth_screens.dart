// lib/features/auth/screens/auth_screens.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shared_widgets.dart';

// ══════════════════════════════════════════════
// SPLASH SCREEN
// ══════════════════════════════════════════════
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: gradientBox(radius: 0,
          colors: [const Color(0xFF3D33C7), AppColors.primary, AppColors.primaryLight]),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const Spacer(flex: 2),
            Container(width: 90, height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
              child: const Icon(Icons.school_rounded, size: 48, color: Colors.white)),
            const SizedBox(height: 24),
            const Text('EduPaths', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 42, fontWeight: FontWeight.w900,
              color: Colors.white, letterSpacing: -1)),
            const SizedBox(height: 8),
            Text(AppConstants.appTagline,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8),
                fontFamily: 'Nunito', fontWeight: FontWeight.w600, height: 1.5)),
            const Spacer(flex: 3),
            ElevatedButton(
              onPressed: () => context.push(AppConstants.routeWelcome),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800)),
              child: const Text('Get Started 🚀'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push(AppConstants.routeLogin),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Log In',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppConstants.routeHome),
              child: Text('Continue as Guest',
                style: TextStyle(color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
          ]),
        )),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// WELCOME SCREEN
// ══════════════════════════════════════════════
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BackBtn(),
          const Spacer(),
          Container(padding: const EdgeInsets.all(20),
            decoration: gradientBox(radius: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your future\nstarts here 🌟',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 30,
                  fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
              const SizedBox(height: 12),
              Text('Explore courses, careers and pathways that fit you.',
                style: TextStyle(color: Colors.white.withOpacity(0.85),
                  fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w600)),
            ])),
          const SizedBox(height: 24),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _Pill(emoji: '🎯', label: 'AI Recommendations'),
            _Pill(emoji: '🗺️', label: 'Visual Roadmap'),
            _Pill(emoji: '🎓', label: 'Uni & Apprenticeships'),
            _Pill(emoji: '🤖', label: 'AI Career Advisor'),
            _Pill(emoji: '👨‍👩‍👧', label: 'Parent Dashboard'),
          ]),
          const Spacer(),
          PrimaryBtn(label: 'Sign Up — It\'s Free!',
            onPressed: () => context.push(AppConstants.routeSignup)),
          const SizedBox(height: 12),
          OutlineBtn(label: 'I already have an account',
            onPressed: () => context.push(AppConstants.routeLogin)),
          const SizedBox(height: 12),
          Center(child: GhostBtn(label: 'Continue as Guest',
            onPressed: () => context.go(AppConstants.routeHome))),
        ]),
      )),
    );
  }
}

class _Pill extends StatelessWidget {
  final String emoji, label;
  const _Pill({required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji), const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontFamily: 'Nunito',
        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    ]));
}

// ══════════════════════════════════════════════
// SIGN UP SCREEN
// ══════════════════════════════════════════════
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _schoolYear;
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  static const _years = ['Year 9', 'Year 10', 'Year 11', 'Year 12',
    'Year 13', 'Sixth Form', 'Graduate', 'Other'];

  Future<void> _signUp() async {
    // Validate all fields before hitting the API
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your full name.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    if (_passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter a password.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_confirmCtrl.text.isEmpty) {
      setState(() => _error = 'Please confirm your password.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final res = await AuthService.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      schoolYear: _schoolYear);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isSuccess) {
      context.go(AppConstants.routeWhoAreYou);
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BackBtn(),
          const SizedBox(height: 24),
          const Text('Create your\naccount ✨', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text("Let's get you started.",
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMid)),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(
                  color: AppColors.error, fontSize: 13, fontFamily: 'Nunito'))),
              ])),
            const SizedBox(height: 16),
          ],
          _Field(ctrl: _nameCtrl, hint: 'Full Name *', icon: Icons.person_outline),
          const SizedBox(height: 12),
          _Field(ctrl: _emailCtrl, hint: 'Email address *',
            icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _schoolYear,
            hint: const Text('School Year'),
            decoration: InputDecoration(
              filled: true, fillColor: AppColors.bgCard,
              prefixIcon: const Icon(Icons.school_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border))),
            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            onChanged: (v) => setState(() => _schoolYear = v)),
          const SizedBox(height: 12),
          _PassField(ctrl: _passCtrl, hint: 'Password *',
            obscure: _obscure, onToggle: () => setState(() => _obscure = !_obscure)),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text('Minimum 6 characters',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textMid))),
          const SizedBox(height: 12),
          _PassField(ctrl: _confirmCtrl, hint: 'Confirm Password *',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            onSubmit: _signUp),
          const SizedBox(height: 24),
          PrimaryBtn(label: 'Sign Up 🎉', onPressed: _signUp, isLoading: _loading),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account? ',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMid)),
            GestureDetector(
              onTap: () => context.push(AppConstants.routeLogin),
              child: const Text('Log in',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.w800, color: AppColors.primary))),
          ]),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════
// LOGIN SCREEN
// ══════════════════════════════════════════════
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address first');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://edupathmve.netlify.app/reset-password');
      if (!mounted) return;
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset email sent! Check your inbox.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 5)));
    } catch (e) {
      setState(() => _error = 'Could not send reset email. Check your email address.');
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    if (_passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await AuthService.signIn(
      email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.isSuccess) {
      if (!mounted) return;
      ref.invalidate(appUserProvider);
      ref.invalidate(matchesProvider);
      ref.invalidate(savedItemsProvider);
      ref.invalidate(subscriptionProvider);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      // Admins always go straight to home — bypass WhoAreYou
      final isAdmin = res.user?.isAdmin ?? false;
      final done = res.user?.onboardingComplete ?? false;
      if (isAdmin || done) {
        context.go(AppConstants.routeHome);
      } else {
        context.go(AppConstants.routeWhoAreYou);
      }
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const BackBtn(),
          const SizedBox(height: 24),
          const Text('Welcome\nback! 👋', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w900,
            color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Log in to your account',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMid)),
          const SizedBox(height: 28),
          if (_error != null) ...[
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(
                  color: AppColors.error, fontSize: 13, fontFamily: 'Nunito'))),
              ])),
            const SizedBox(height: 16),
          ],
          _Field(ctrl: _emailCtrl, hint: 'Email address',
            icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _PassField(ctrl: _passCtrl, hint: 'Password',
            obscure: _obscure, onToggle: () => setState(() => _obscure = !_obscure),
            onSubmit: _login),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPassword(context),
              child: const Text('Forgot password?',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.primary)))),
          const SizedBox(height: 8),
          PrimaryBtn(label: 'Log In', onPressed: _login, isLoading: _loading),
          const SizedBox(height: 12),
          Center(child: GestureDetector(
            onTap: _forgotPassword,
            child: const Text('Forgot your password?', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13,
              color: AppColors.primary, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Don't have an account? ",
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMid)),
            GestureDetector(
              onTap: () => context.push(AppConstants.routeSignup),
              child: const Text('Sign up',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  fontWeight: FontWeight.w800, color: AppColors.primary))),
          ]),
          const SizedBox(height: 16),
          Center(child: GhostBtn(label: 'Continue as Guest',
            onPressed: () => context.go(AppConstants.routeHome))),
        ]),
      )),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reset Password', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text("We'll send a reset link to your email.",
            style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textMid)),
          const SizedBox(height: 16),
          _Field(ctrl: ctrl, hint: 'Email address',
            icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          PrimaryBtn(label: 'Send Reset Link', onPressed: () async {
            final err = await AuthService.sendPasswordReset(ctrl.text.trim());
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(err ?? 'Reset link sent! Check your inbox. 📧'),
              backgroundColor: err == null ? AppColors.success : AppColors.error));
          }),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// WHO ARE YOU SCREEN
// ══════════════════════════════════════════════
class WhoAreYouScreen extends ConsumerWidget {
  const WhoAreYouScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            const Text("Who are you using\nEduPaths for?", style: TextStyle(
              fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w900,
              color: AppColors.textDark, height: 1.2)),
            const SizedBox(height: 8),
            const Text('This helps us personalise your experience.',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                color: AppColors.textMid)),
            const SizedBox(height: 28),
            _RoleCard(emoji: '🎓', title: 'Myself',
              subtitle: "I'm a student exploring my future", highlighted: true,
              onTap: () async {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid != null) {
                  await Supabase.instance.client.from('users')
                      .update({'role_type': 'student'})
                      .eq('supabase_uid', uid);
                }
                ref.read(onboardingProvider.notifier).setRole('student');
                if (context.mounted) context.push(AppConstants.routeOnboardingStart);
              }),
            const SizedBox(height: 12),
            _RoleCard(emoji: '👨‍👩‍👧', title: 'My Child',
              subtitle: "I'm a parent or guardian",
              onTap: () async {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid != null) {
                  await Supabase.instance.client.from('users')
                      .update({'role_type': 'parent', 'onboarding_complete': true})
                      .eq('supabase_uid', uid);
                }
                if (context.mounted) context.push(AppConstants.routeParentDashboard);
              }),
            const SizedBox(height: 12),
            _RoleCard(emoji: '🏫', title: 'School / Advisor',
              subtitle: "I'm an educator or careers advisor",
              onTap: () async {
                // Save role to database immediately
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid != null) {
                  await Supabase.instance.client.from('users')
                      .update({'role_type': 'advisor', 'onboarding_complete': true})
                      .eq('supabase_uid', uid);
                }
                ref.read(onboardingProvider.notifier).setRole('advisor');
                if (context.mounted) context.go('/school-advisor');
              }),
            const Spacer(),
            Center(child: GhostBtn(label: 'Skip for now',
              onPressed: () => context.go(AppConstants.routeHome))),
          ]),
        )),
      ),
    );
  }
}


class _RoleCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool highlighted;
  final VoidCallback onTap;
  const _RoleCard({required this.emoji, required this.title,
    required this.subtitle, required this.onTap, this.highlighted = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryPale : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.border,
          width: highlighted ? 2 : 1.5)),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          Text(subtitle, style: const TextStyle(fontFamily: 'Nunito',
            fontSize: 13, color: AppColors.textMid)),
        ])),
        Icon(Icons.chevron_right_rounded,
          color: highlighted ? AppColors.primary : AppColors.textLight),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  const _Field({required this.ctrl, required this.hint,
    required this.icon, this.keyboard});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: keyboard,
    decoration: InputDecoration(hintText: hint,
      prefixIcon: Icon(icon, size: 20)));
}

class _PassField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  final VoidCallback? onToggle;
  final VoidCallback? onSubmit;
  const _PassField({required this.ctrl, required this.hint,
    required this.obscure, this.onToggle, this.onSubmit});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, obscureText: obscure,
    onFieldSubmitted: (_) => onSubmit?.call(),
    textInputAction: onSubmit != null ? TextInputAction.done : TextInputAction.next,
    decoration: InputDecoration(hintText: hint,
      prefixIcon: const Icon(Icons.lock_outline, size: 20),
      suffixIcon: onToggle != null ? GestureDetector(
        onTap: onToggle,
        child: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20)) : null));
}
