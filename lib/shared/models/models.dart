// lib/shared/models/models.dart
class AppUser {
  final String id;
  final String? supabaseUid;
  final String? fullName;
  final String? email;
  final String? schoolYear;
  final String roleType;
  final bool onboardingComplete;
  final bool isAdmin;
  final int? interestsChangedCount;
  final DateTime? interestsLastChanged;
  const AppUser({
    required this.id,
    this.supabaseUid,
    this.fullName,
    this.email,
    this.schoolYear,
    this.roleType = 'student',
    this.onboardingComplete = false,
    this.isAdmin = false,
    this.interestsChangedCount,
    this.interestsLastChanged,
  });
  String get displayName => fullName ?? email?.split('@').first ?? 'Explorer';
  String get firstName => displayName.split(' ').first;
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'E';
  }
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    supabaseUid: j['supabase_uid'] as String?,
    fullName: j['full_name'] as String?,
    email: j['email'] as String?,
    schoolYear: j['school_year'] as String?,
    roleType: j['role_type'] as String? ?? 'student',
    onboardingComplete: j['onboarding_complete'] as bool? ?? false,
    isAdmin: j['is_admin'] as bool? ?? false,
    interestsChangedCount: j['interests_changed_count'] as int?,
    interestsLastChanged: j['interests_last_changed'] != null
        ? DateTime.tryParse(j['interests_last_changed'].toString()) : null,
  );
}

class Interest {
  final String id; final String name; final String? category;
  const Interest({required this.id, required this.name, this.category});
  String get trimmed => name.trim();
  factory Interest.fromJson(Map<String, dynamic> j) =>
      Interest(id: j['id'], name: j['name'], category: j['category']);
}

class Career {
  final String id; final String name;
  final String? avgSalary; final String? description; final String? category;
  const Career({required this.id, required this.name, this.avgSalary, this.description, this.category});
  String get displayName => name.trim();
  String get salaryDisplay {
    final s = avgSalary?.trim() ?? '';
    if (s.isEmpty) return 'Varies';
    return s.startsWith('£') ? s : '£$s / yr';
  }
  factory Career.fromJson(Map<String, dynamic> j) => Career(
    id: j['id'], name: j['name'],
    avgSalary: j['avg_salary'], description: j['description'],
    category: j['category']);
}

class Course {
  final String id; final String title;
  final String? duration; final String? feesHome;
  final String? location; final String? url;
  final String? ucasCode; final String? startDate; final String? category;
  final Institution? institution;
  const Course({required this.id, required this.title, this.duration,
    this.feesHome, this.location, this.url, this.ucasCode, this.startDate,
    this.category, this.institution});
  String get trimmed => title.trim();
  bool get isApprenticeship =>
      title.toLowerCase().contains('apprenticeship') ||
      title.toLowerCase().contains('bootcamp') ||
      (institution?.type?.toLowerCase().contains('apprenticeship') ?? false);
  factory Course.fromJson(Map<String, dynamic> j) => Course(
    id: j['id'], title: j['title'], duration: j['duration'],
    feesHome: j['fees_home'], location: j['location'],
    url: j['url'], ucasCode: j['ucas_code'], startDate: j['start_date'],
    category: j['category'],
    institution: j['institutions'] != null
        ? Institution.fromJson(j['institutions']) : null);
}

class Institution {
  final String id; final String name;
  final String? type; final String? location;
  const Institution({required this.id, required this.name, this.type, this.location});
  String get trimmed => name.trim();
  factory Institution.fromJson(Map<String, dynamic> j) =>
      Institution(id: j['id'], name: j['name'], type: j['type'], location: j['location']);
}

class Trait {
  final String id; final String name; final String? category;
  const Trait({required this.id, required this.name, this.category});
  String get trimmed => name.trim();
  factory Trait.fromJson(Map<String, dynamic> j) =>
      Trait(id: j['id'], name: j['name'], category: j['category']);
}

class SavedItem {
  final String id; final String itemType;
  final String itemId; final String? itemTitle; final String? itemSubtitle;
  const SavedItem({required this.id, required this.itemType,
    required this.itemId, this.itemTitle, this.itemSubtitle});
  factory SavedItem.fromJson(Map<String, dynamic> j) => SavedItem(
    id: j['id'], itemType: j['item_type'],
    itemId: j['item_id'].toString(),
    itemTitle: j['item_title'], itemSubtitle: j['item_subtitle']);
}

class AppMatch {
  final String careerId; final String careerName;
  final String? avgSalary; final int matchScore; final String? matchReason;
  const AppMatch({required this.careerId, required this.careerName,
    this.avgSalary, required this.matchScore, this.matchReason});
}

class Subscription {
  final String firebaseUid; final String plan;
  final String status; final DateTime? trialEndsAt;
  const Subscription({required this.firebaseUid, required this.plan,
    required this.status, this.trialEndsAt});
  bool get isPremium => plan == 'premium' || plan == 'premium_plus';
  bool get isPremiumPlus => plan == 'premium_plus';
  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    firebaseUid: j['firebase_uid'] as String,
    plan: j['plan'] as String? ?? 'free',
    status: j['status'] as String? ?? 'active',
    trialEndsAt: j['trial_ends_at'] != null
        ? DateTime.parse(j['trial_ends_at']) : null);
}
