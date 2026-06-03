// lib/core/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/models.dart';
import 'db_service.dart';

class AuthService {
  static SupabaseClient get _sb => Supabase.instance.client;
  static User? get currentUser => _sb.auth.currentUser;
  static Stream<AuthState> get authStream => _sb.auth.onAuthStateChange;

  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    String? schoolYear,
    String roleType = 'student',
  }) async {
    try {
      final res = await _sb.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role_type': roleType,
          'role': roleType,
        },
      );
      if (res.user == null) return AuthResult(error: 'Sign up failed. Please try again.');
      await Future.delayed(const Duration(milliseconds: 800));
      try {
        await _sb.from('users').update({
          'full_name': fullName, 'name': fullName,
          'school_year': schoolYear, 'role_type': roleType,
        }).eq('supabase_uid', res.user!.id);
      } catch (_) {
        try {
          await _sb.from('users').insert({
            'supabase_uid': res.user!.id, 'full_name': fullName,
            'name': fullName, 'email': email, 'school_year': schoolYear,
            'role': roleType, 'role_type': roleType, 'onboarding_complete': false,
          });
        } catch (_) {}
      }
      final appUser = await DbService.getUserByUid(res.user!.id);
      return AuthResult(user: appUser);
    } on AuthException catch (e) {
      return AuthResult(error: _mapAuthError(e.message));
    } catch (e) {
      return AuthResult(error: 'Sign up error: ${e.toString()}');
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Full sign out first to clear any cached session
      await signOut();
      await Future.delayed(const Duration(milliseconds: 300));

      final res = await _sb.auth.signInWithPassword(
        email: email, password: password);
      if (res.user == null) return AuthResult(error: 'Login failed. Please try again.');
      final appUser = await DbService.getUserByUid(res.user!.id);
      return AuthResult(user: appUser);
    } on AuthException catch (e) {
      return AuthResult(error: _mapAuthError(e.message));
    } catch (e) {
      return AuthResult(error: 'Login error: ${e.toString()}');
    }
  }

  static Future<void> signOut() async {
    // Clear all local state on sign out
    try {
      await _sb.auth.signOut(scope: SignOutScope.global);
    } catch (_) {
      try { await _sb.auth.signOut(scope: SignOutScope.local); } catch (_) {}
    }
  }

  static Future<String?> sendPasswordReset(String email) async {
    try {
      await _sb.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return _mapAuthError(e.message);
    }
  }

  static String _mapAuthError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'An account already exists with this email.';
    }
    if (m.contains('password') && m.contains('short')) {
      return 'Password must be at least 6 characters.';
    }
    if (m.contains('email') && m.contains('invalid')) {
      return 'Please enter a valid email address.';
    }
    if (m.contains('user not found')) {
      return 'No account found with this email.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    return msg;
  }
}

class AuthResult {
  final AppUser? user;
  final String? error;
  const AuthResult({this.user, this.error});
  bool get isSuccess => error == null;
}
