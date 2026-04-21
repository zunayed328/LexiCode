import 'package:cloud_firestore/cloud_firestore.dart';

/// A single AI chat exchange saved to Firestore.
///
/// Stored in `users/{uid}/chatHistory/{autoId}`.
class ChatHistoryEntry {
  final String id;
  final String userId;
  final String prompt;
  final String response;
  final DateTime timestamp;
  final String category;

  const ChatHistoryEntry({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.response,
    required this.timestamp,
    this.category = 'mentorChat',
  });

  /// Creates a [ChatHistoryEntry] from a Firestore document snapshot.
  factory ChatHistoryEntry.fromMap(String docId, Map<String, dynamic> data) {
    DateTime ts;
    final raw = data['timestamp'];
    if (raw is Timestamp) {
      ts = raw.toDate();
    } else if (raw is String) {
      ts = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return ChatHistoryEntry(
      id: docId,
      userId: data['userId'] as String? ?? '',
      prompt: data['prompt'] as String? ?? '',
      response: data['response'] as String? ?? '',
      timestamp: ts,
      category: data['category'] as String? ?? 'mentorChat',
    );
  }

  /// Converts this entry to a Firestore-compatible map.
  ///
  /// Uses [FieldValue.serverTimestamp] so the timestamp is set
  /// by the Firestore server, not the client clock.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'prompt': prompt,
      'response': response,
      'timestamp': FieldValue.serverTimestamp(),
      'category': category,
    };
  }

  /// Converts this entry to a map with a client-side timestamp
  /// (for local display before the server timestamp resolves).
  Map<String, dynamic> toMapWithClientTimestamp() {
    return {
      'userId': userId,
      'prompt': prompt,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }
}
