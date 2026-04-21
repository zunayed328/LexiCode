import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single AI chat exchange persisted to Firestore.
///
/// Stored in `users/{uid}/activities/{autoId}`.
///
/// Fields:
///   - [id]        — Firestore document ID (set after write).
///   - [userId]    — Firebase Auth UID of the authenticated user.
///   - [prompt]    — The message the user sent to the AI mentor.
///   - [response]  — The Llama 4 Scout response returned by the Groq API.
///   - [timestamp] — Server-side Firestore [Timestamp] of when the entry was saved.
///   - [category]  — Logical category of the activity (e.g. 'mentorChat').
class ActivityModel {
  final String id;
  final String userId;
  final String prompt;
  final String response;
  final Timestamp? timestamp; // Nullable: server timestamp is resolved after write
  final String category;

  const ActivityModel({
    required this.id,
    required this.userId,
    required this.prompt,
    required this.response,
    this.timestamp,
    this.category = 'mentorChat',
  });

  // ─── Factory Constructors ────────────────────────────────────────────────

  /// Creates an [ActivityModel] from a Firestore document snapshot.
  factory ActivityModel.fromMap(String docId, Map<String, dynamic> data) {
    Timestamp? ts;
    final raw = data['timestamp'];
    if (raw is Timestamp) {
      ts = raw;
    }
    // If the field is a String (e.g. from a client-side write), convert it.
    // FieldValue.serverTimestamp() resolves asynchronously, so the value may
    // briefly be null in a freshly-written document — this is expected.

    return ActivityModel(
      id: docId,
      userId: data['userId'] as String? ?? '',
      prompt: data['prompt'] as String? ?? '',
      response: data['response'] as String? ?? '',
      timestamp: ts,
      category: data['category'] as String? ?? 'mentorChat',
    );
  }

  // ─── Serialisation ───────────────────────────────────────────────────────

  /// Converts this model to a map ready to [add] to Firestore.
  ///
  /// Uses [FieldValue.serverTimestamp] so the timestamp is authoritative
  /// and resistant to clock skew on the client device.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'prompt': prompt,
      'response': response,
      'timestamp': FieldValue.serverTimestamp(),
      'category': category,
    };
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Converts the Firestore [Timestamp] to a [DateTime].
  ///
  /// Falls back to [DateTime.now] when the server timestamp is not yet
  /// resolved (e.g. immediately after a local write).
  DateTime get dateTime => timestamp?.toDate() ?? DateTime.now();

  /// Formatted date string (locale-independent).
  String get formattedDate {
    final dt = dateTime;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'ActivityModel(id: $id, userId: $userId, category: $category, '
      'prompt: ${prompt.length > 40 ? '${prompt.substring(0, 40)}…' : prompt})';
}
