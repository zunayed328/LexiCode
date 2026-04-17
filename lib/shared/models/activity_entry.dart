/// Represents a single tracked user activity event.
class ActivityEntry {
  final String id;
  final DateTime timestamp;
  final ActivityType type;
  final String title;
  final String? detail;
  final int xpEarned;

  const ActivityEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    this.detail,
    this.xpEarned = 0,
  });

  /// Creates an [ActivityEntry] from a Firestore-compatible map.
  factory ActivityEntry.fromMap(Map<String, dynamic> data) {
    return ActivityEntry(
      id: data['id'] ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.practice,
      ),
      title: data['title'] ?? '',
      detail: data['detail'],
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts this entry to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'title': title,
      'detail': detail,
      'xpEarned': xpEarned,
    };
  }

  /// Formatted relative timestamp (e.g. "2 hours ago", "Yesterday").
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}';
  }
}

/// Categories of tracked user activities.
enum ActivityType {
  codeReview('Code Review'),
  lesson('Lesson'),
  ielts('IELTS Practice'),
  mentorChat('Mentor Chat'),
  practice('Practice');

  final String label;
  const ActivityType(this.label);
}
