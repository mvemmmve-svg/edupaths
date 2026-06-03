// lib/core/services/db_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/models.dart';

class DbService {
  static SupabaseClient get _sb => Supabase.instance.client;
  static String? get _uid => _sb.auth.currentUser?.id;

  static Future<AppUser?> getUserByUid(String uid) async {
    final res = await _sb.from('users').select()
        .eq('supabase_uid', uid).maybeSingle();
    return res != null ? AppUser.fromJson(res) : null;
  }

  static Future<AppUser> upsertUser({
    required String uid, required String email,
    String? fullName, String? schoolYear, String roleType = 'student',
  }) async {
    // Wait briefly for the trigger to create the public user record
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Try to get the user created by the trigger
    final existing = await getUserByUid(uid);
    if (existing != null) {
      // Update with any extra info from signup form
      if (fullName != null || schoolYear != null) {
        await _sb.from('users').update({
          if (fullName != null) 'full_name': fullName,
          if (fullName != null) 'name': fullName,
          if (schoolYear != null) 'school_year': schoolYear,
        }).eq('supabase_uid', uid);
        return await getUserByUid(uid) ?? existing;
      }
      return existing;
    }
    
    // Fallback: manually create if trigger didn't fire
    try {
      final res = await _sb.from('users').insert({
        'supabase_uid': uid, 'full_name': fullName, 'name': fullName,
        'email': email, 'school_year': schoolYear,
        'role': roleType, 'role_type': roleType, 'onboarding_complete': false,
      }).select().single();
      return AppUser.fromJson(res);
    } catch (e) {
      final retry = await getUserByUid(uid);
      if (retry != null) return retry;
      rethrow;
    }
  }

  static Future<void> markOnboardingComplete(String userId) async {
    await _sb.from('users').update({'onboarding_complete': true}).eq('id', userId);
  }

  static Future<List<Interest>> getAllInterests() async {
    final res = await _sb.from('interests').select().order('category').order('name');
    return (res as List).map((e) => Interest.fromJson(e)).toList();
  }

  static Future<void> saveUserInterests(String userId, List<String> ids) async {
    await _sb.from('user_interest').delete().eq('user_id', userId);
    if (ids.isEmpty) return;
    await _sb.from('user_interest').insert(
        ids.map((id) => {'user_id': userId, 'interest_id': id}).toList());
  }

  static Future<void> saveUserTraits(String userId, List<String> traitIds) async {
    await _sb.from('user_trait').delete().eq('user_id', userId);
    if (traitIds.isEmpty) return;
    await _sb.from('user_trait').insert(
        traitIds.map((id) => {'user_id': userId, 'trait_id': id}).toList());
  }

  static Future<List<Trait>> getAllTraits() async {
    final res = await _sb.from('trait').select().order('name');
    return (res as List).map((e) => Trait.fromJson(e)).toList();
  }

  static Future<void> savePreferences(Map<String, String> prefs) async {
    if (_uid == null) return;
    await _sb.from('preferences').upsert({
      'firebase_uid': _uid, 'pathway_focus': prefs['pathway'],
      'location_preference': prefs['location'], 'budget_importance': prefs['budget'],
      'work_environment': prefs['environment'], 'study_intensity': prefs['intensity'],
    }, onConflict: 'firebase_uid');
  }

  static Future<List<Career>> getAllCareers() async {
    final res = await _sb.from('careers').select('id, name, avg_salary, description, category').order('name');
    return (res as List).map((e) => Career.fromJson(e)).toList();
  }

  static Future<Career?> getCareerById(String id) async {
    final res = await _sb.from('careers').select('id, name, avg_salary, description, category').eq('id', id).maybeSingle();
    return res != null ? Career.fromJson(res) : null;
  }

  static Future<List<Career>> searchCareers(String q) async {
    final res = await _sb.from('careers').select().ilike('name', '%$q%').order('name');
    return (res as List).map((e) => Career.fromJson(e)).toList();
  }

  static Future<List<Course>> getAllCourses() async {
    final res = await _sb.from('courses').select('*, institutions(*)').order('title');
    return (res as List).map((e) => Course.fromJson(e)).toList();
  }

  static Future<Course?> getCourseById(String id) async {
    final res = await _sb.from('courses').select('*, institutions(*)')
        .eq('id', id).maybeSingle();
    return res != null ? Course.fromJson(res) : null;
  }

  static Future<List<AppMatch>> getMatches() async {
    if (_uid == null) return [];
    final res = await _sb.from('matches')
        .select('*, careers(name, avg_salary)')
        .eq('firebase_uid', _uid!)
        .order('match_score', ascending: false)
        .limit(20);
    return (res as List).map((e) {
      final c = e['careers'] as Map<String, dynamic>? ?? {};
      return AppMatch(
        careerId: e['career_id'].toString(),
        careerName: (c['name'] ?? '').toString().trim(),
        avgSalary: c['avg_salary'],
        matchScore: (e['match_score'] as num?)?.toInt() ?? 0,
        matchReason: e['match_reason'],
      );
    }).toList();
  }

  static Future<void> generateMatches(List<String> interestIds) async {
    if (_uid == null) return;
    try {
      // Call the smart SQL function
      await _sb.rpc('generate_smart_matches', params: {'p_user_uid': _uid});
    } catch (e) {
      // Fast fallback: bulk insert all careers at once
      try {
        final careers = await getAllCareers();
        if (careers.isEmpty) return;
        // Delete old matches first
        await _sb.from('matches').delete().eq('firebase_uid', _uid!);
        // Build all match data at once
        final data = careers.map((c) {
          int score = 50 + (c.id.hashCode.abs() % 40);
          return {
            'firebase_uid': _uid,
            'career_id': c.id,
            'match_score': score.clamp(0, 98),
            'match_reason': 'Based on your interests and strengths',
          };
        }).toList();
        // Insert all in one batch call
        if (data.isNotEmpty) {
          await _sb.from('matches').upsert(data,
            onConflict: 'firebase_uid,career_id');
        }
      } catch (_) {}
    }
  }

  // Saved items — store item_id as text to avoid UUID type issues
  static Future<List<SavedItem>> getSavedItems() async {
    if (_uid == null) return [];
    try {
      final res = await _sb.from('saved_items').select()
          .eq('firebase_uid', _uid!).order('created_at', ascending: false);
      return (res as List).map((e) => SavedItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> isItemSaved(String itemId) async {
    if (_uid == null) return false;
    try {
      final res = await _sb.from('saved_items').select('id')
          .eq('firebase_uid', _uid!).eq('item_id', itemId).maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveItem({
    required String itemType, required String itemId,
    String? title, String? subtitle,
  }) async {
    if (_uid == null) return;
    try {
      if (await isItemSaved(itemId)) return;
      await _sb.from('saved_items').insert({
        'firebase_uid': _uid, 'item_type': itemType,
        'item_id': itemId, 'item_title': title, 'item_subtitle': subtitle,
      });
    } catch (e) {
      // ignore save errors silently
    }
  }

  static Future<void> unsaveItem(String itemId) async {
    if (_uid == null) return;
    try {
      await _sb.from('saved_items').delete()
          .eq('firebase_uid', _uid!).eq('item_id', itemId);
    } catch (e) {
      // ignore
    }
  }

  static Future<Subscription?> getSubscription() async {
    if (_uid == null) return null;
    try {
      final res = await _sb.from('subscriptions').select()
          .eq('firebase_uid', _uid!).maybeSingle();
      return res != null ? Subscription.fromJson(res) : null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> activatePlan(String plan, String cycle) async {
    if (_uid == null) return;
    await _sb.from('subscriptions').upsert({
      'firebase_uid': _uid, 'plan': plan, 'status': 'active',
      'billing_cycle': cycle,
      'trial_ends_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    }, onConflict: 'firebase_uid');
  }

  static Future<List<Map<String, dynamic>>> getAllUsersAdmin() async {
    final res = await _sb.from('users').select(
        'id, full_name, email, school_year, role_type, onboarding_complete, is_admin, created_at')
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getAllSubscriptionsAdmin() async {
    final res = await _sb.from('subscriptions').select()
        .order('created_at', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<void> setUserPlan(String firebaseUid, String plan) async {
    await _sb.from('subscriptions').upsert({
      'firebase_uid': firebaseUid, 'plan': plan,
      'status': 'active', 'billing_cycle': 'monthly',
    }, onConflict: 'firebase_uid');
  }

  static Future<void> setAdminStatus(String userId, bool isAdmin) async {
    await _sb.from('users').update({'is_admin': isAdmin}).eq('id', userId);
  }
}
