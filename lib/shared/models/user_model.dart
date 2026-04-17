import 'activity_entry.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int xp;
  final int level;
  final int streak;
  final int lessonsCompleted;
  final int codeReviewsCompleted;
  final String proficiencyLevel;
  final List<String> badges;
  final DateTime lastActiveDate;
  final int totalTimeSpentMinutes;
  final List<ActivityEntry> activityLog;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.lessonsCompleted = 0,
    this.codeReviewsCompleted = 0,
    this.proficiencyLevel = 'A1',
    this.badges = const [],
    DateTime? lastActiveDate,
    this.totalTimeSpentMinutes = 0,
    this.activityLog = const [],
  }) : lastActiveDate = lastActiveDate ?? DateTime.now();

  int get xpForNextLevel => level * 500;
  double get levelProgress => xp / xpForNextLevel;
  String get levelTitle => _getLevelTitle();

  String _getLevelTitle() {
    if (level <= 5) return 'Code Novice';
    if (level <= 10) return 'Bug Hunter';
    if (level <= 15) return 'Code Warrior';
    if (level <= 20) return 'Tech Linguist';
    if (level <= 30) return 'Senior Dev';
    return 'Code Master';
  }

  // ─── Activity Helpers ──────────────────────────────────────────

  /// Formatted display string for total time spent (e.g. "42h 15m").
  String get formattedTimeSpent {
    final hours = totalTimeSpentMinutes ~/ 60;
    final mins = totalTimeSpentMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Returns only code review activities from the log.
  List<ActivityEntry> get codeReviewActivities =>
      activityLog.where((a) => a.type == ActivityType.codeReview).toList();

  /// Returns only English learning activities from the log.
  List<ActivityEntry> get englishActivities => activityLog
      .where(
        (a) =>
            a.type == ActivityType.lesson ||
            a.type == ActivityType.ielts ||
            a.type == ActivityType.mentorChat ||
            a.type == ActivityType.practice,
      )
      .toList();

  /// Returns a map of day labels → activity counts for the last 7 days.
  Map<String, int> get dailyActivityLast7Days {
    final now = DateTime.now();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <String, int>{};

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = dayLabels[day.weekday - 1];
      final count = activityLog.where((a) {
        return a.timestamp.year == day.year &&
            a.timestamp.month == day.month &&
            a.timestamp.day == day.day;
      }).length;
      result[label] = count;
    }

    return result;
  }

  // ─── Serialization ─────────────────────────────────────────────

  /// Creates a [UserModel] from a Firestore document map.
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? 'Developer',
      email: data['email'] ?? '',
      avatarUrl: data['photoURL'] ?? '',
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      lessonsCompleted: (data['lessonsCompleted'] as num?)?.toInt() ?? 0,
      codeReviewsCompleted:
          (data['codeReviewsCompleted'] as num?)?.toInt() ?? 0,
      proficiencyLevel: data['proficiencyLevel'] ?? 'A1',
      badges: List<String>.from(data['badges'] ?? []),
      totalTimeSpentMinutes:
          (data['totalTimeSpentMinutes'] as num?)?.toInt() ?? 0,
      activityLog:
          (data['activityLog'] as List<dynamic>?)
              ?.map((e) => ActivityEntry.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  /// Converts this model to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoURL': avatarUrl,
      'xp': xp,
      'level': level,
      'streak': streak,
      'lessonsCompleted': lessonsCompleted,
      'codeReviewsCompleted': codeReviewsCompleted,
      'proficiencyLevel': proficiencyLevel,
      'badges': badges,
      'totalTimeSpentMinutes': totalTimeSpentMinutes,
      'activityLog': activityLog.map((e) => e.toMap()).toList(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? xp,
    int? level,
    int? streak,
    int? lessonsCompleted,
    int? codeReviewsCompleted,
    String? proficiencyLevel,
    List<String>? badges,
    DateTime? lastActiveDate,
    int? totalTimeSpentMinutes,
    List<ActivityEntry>? activityLog,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      codeReviewsCompleted: codeReviewsCompleted ?? this.codeReviewsCompleted,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      badges: badges ?? this.badges,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalTimeSpentMinutes:
          totalTimeSpentMinutes ?? this.totalTimeSpentMinutes,
      activityLog: activityLog ?? this.activityLog,
    );
  }
}
