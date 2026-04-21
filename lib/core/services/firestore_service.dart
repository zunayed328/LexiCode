import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/activity_model.dart';
import '../../shared/models/activity_entry.dart';
import '../../shared/models/chat_history_entry.dart';
import '../../shared/models/code_review_model.dart';

/// Cloud Firestore data service.
///
/// All user data is stored under `users/{uid}` with subcollections for
/// activities, code reviews, and lesson progress.
///
/// Firestore Schema:
///   users/{uid}                            → user profile document
///   users/{uid}/activities/{autoId}        → activity entries
///   users/{uid}/codeReviews/{autoId}       → code review results
///   users/{uid}/lessonProgress/{lessonId}  → lesson progress
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to the top-level users collection.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  /// Returns the document reference for a given user.
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  // ─── User Document ────────────────────────────────────────────────────────

  /// Ensures a user profile document exists in Firestore.
  ///
  /// Called after successful authentication. If the document already exists,
  /// returns the existing data. If not, creates a new document with defaults.
  Future<Map<String, dynamic>?> ensureUserDocument({
    required String uid,
    required String name,
    required String email,
    String? photoURL,
  }) async {
    try {
      final docRef = _userDoc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        debugPrint('[Firestore] User $uid already exists — loaded.');
        return snapshot.data();
      }

      // New user — create the profile document
      final userData = {
        'name': name,
        'email': email,
        'photoURL': photoURL ?? '',
        'role': 'developer',
        'xp': 0,
        'level': 1,
        'streak': 0,
        'longestStreak': 0,
        'lessonsCompleted': 0,
        'codeReviewsCompleted': 0,
        'proficiencyLevel': 'A1',
        'badges': <String>[],
        'totalTimeSpentMinutes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveDate': FieldValue.serverTimestamp(),
      };

      await docRef.set(userData);
      debugPrint('[Firestore] Created new user document for $uid');

      // Fetch the newly created doc to return server-resolved timestamps
      final created = await docRef.get();
      return created.data();
    } catch (e) {
      debugPrint('[Firestore] ensureUserDocument error: $e');
      return null;
    }
  }

  /// Fetches the user profile document for [uid].
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _userDoc(uid).get();
      return snapshot.data();
    } catch (e) {
      debugPrint('[Firestore] getUserData error: $e');
      return null;
    }
  }

  // ─── XP & Level ───────────────────────────────────────────────────────────

  /// Awards [xpToAdd] XP to the user and recalculates their level.
  ///
  /// Returns the updated user data map.
  Future<Map<String, dynamic>?> updateXp(String uid, int xpToAdd) async {
    try {
      final docRef = _userDoc(uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return null;

      final data = snapshot.data()!;
      int currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      int currentLevel = (data['level'] as num?)?.toInt() ?? 1;

      int newXp = currentXp + xpToAdd;
      int newLevel = currentLevel;
      while (newXp >= newLevel * 500) {
        newXp -= newLevel * 500;
        newLevel++;
      }

      await docRef.update({
        'xp': newXp,
        'level': newLevel,
      });

      final updated = await docRef.get();
      return updated.data();
    } catch (e) {
      debugPrint('[Firestore] updateXp error: $e');
      return null;
    }
  }

  /// Computes and updates the user's streak based on their last active date.
  Future<void> updateStreak(String uid) async {
    try {
      final docRef = _userDoc(uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final now = DateTime.now();

      // Parse lastActiveDate — could be a Timestamp or a String
      DateTime lastActive;
      final lastActiveRaw = data['lastActiveDate'];
      if (lastActiveRaw is Timestamp) {
        lastActive = lastActiveRaw.toDate();
      } else if (lastActiveRaw is String) {
        lastActive = DateTime.tryParse(lastActiveRaw) ?? now;
      } else {
        lastActive = now;
      }

      final diffDays = now.difference(lastActive).inDays;
      int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
      int longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;

      int newStreak;
      if (diffDays == 0) {
        newStreak = currentStreak; // Same day — no change
      } else if (diffDays == 1) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1; // Streak broken
      }

      final newLongest =
          newStreak > longestStreak ? newStreak : longestStreak;

      await docRef.update({
        'streak': newStreak,
        'longestStreak': newLongest,
        'lastActiveDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] updateStreak error: $e');
    }
  }

  // ─── Counters ─────────────────────────────────────────────────────────────

  /// Increments a numeric field on the user document.
  Future<void> incrementField(String uid, String field, int amount) async {
    try {
      await _userDoc(uid).update({
        field: FieldValue.increment(amount),
      });
    } catch (e) {
      debugPrint('[Firestore] incrementField error: $e');
    }
  }

  /// Generic field update helper.
  Future<void> updateUserFields(
      String uid, Map<String, dynamic> fields) async {
    try {
      await _userDoc(uid).update(fields);
    } catch (e) {
      debugPrint('[Firestore] updateUserFields error: $e');
    }
  }

  // ─── Activity Log (subcollection) ─────────────────────────────────────────

  /// Saves an [ActivityEntry] to the `activities` subcollection.
  Future<void> saveActivity(ActivityEntry entry, String uid) async {
    try {
      final data = entry.toMap();
      data['userId'] = uid;
      await _userDoc(uid)
          .collection('activities')
          .add(data);
    } catch (e) {
      debugPrint('[Firestore] saveActivity error: $e');
    }
  }

  /// Returns the most recent 50 activity entries for [uid],
  /// ordered by timestamp descending.
  Future<List<ActivityEntry>> getActivities(String uid) async {
    try {
      final snapshot = await _userDoc(uid)
          .collection('activities')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return ActivityEntry.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('[Firestore] getActivities error: $e');
      return [];
    }
  }

  // ─── Lesson Progress (subcollection) ──────────────────────────────────────

  /// Persists lesson completion progress. Uses [lessonId] as the document ID
  /// so progress is upserted (created or updated).
  Future<void> saveLessonProgress({
    required String lessonId,
    required String uid,
    required int completedQuestions,
    required bool isCompleted,
  }) async {
    try {
      await _userDoc(uid)
          .collection('lessonProgress')
          .doc(lessonId)
          .set({
        'lessonId': lessonId,
        'completedQuestions': completedQuestions,
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] saveLessonProgress error: $e');
    }
  }

  /// Returns lesson progress map for [uid].
  Future<Map<String, Map<String, dynamic>>> getLessonProgress(
      String uid) async {
    try {
      final snapshot =
          await _userDoc(uid).collection('lessonProgress').get();

      final result = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
      return result;
    } catch (e) {
      debugPrint('[Firestore] getLessonProgress error: $e');
      return {};
    }
  }

  // ─── Code Reviews (subcollection) ─────────────────────────────────────────

  /// Saves a [CodeReviewResult] to the `codeReviews` subcollection.
  Future<void> saveCodeReview({
    required CodeReviewResult result,
    required String uid,
    required String language,
  }) async {
    try {
      await _userDoc(uid).collection('codeReviews').add({
        ...result.toMap(),
        'language': language,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] saveCodeReview error: $e');
    }
  }

  /// Returns the most recent 20 code reviews for [uid].
  Future<List<CodeReviewResult>> getCodeReviews(String uid) async {
    try {
      final snapshot = await _userDoc(uid)
          .collection('codeReviews')
          .orderBy('reviewDate', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        return CodeReviewResult.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('[Firestore] getCodeReviews error: $e');
      return [];
    }
  }

  // ─── Time Spent ───────────────────────────────────────────────────────────

  /// Atomically adds [minutes] to the user's total time using
  /// FieldValue.increment for safe concurrent writes.
  Future<void> addTimeSpent(String uid, int minutes) async {
    try {
      if (minutes <= 0) return;
      await _userDoc(uid).update({
        'totalTimeSpentMinutes': FieldValue.increment(minutes),
      });
    } catch (e) {
      debugPrint('[Firestore] addTimeSpent error: $e');
    }
  }

  // ─── Chat History → Activities (subcollection) ────────────────────────

  /// Saves an AI mentor chat exchange (prompt + Llama 4 Scout response) as
  /// a new [ActivityModel] document in `users/{uid}/activities`.
  ///
  /// Uses [FieldValue.serverTimestamp] so the [timestamp] field is set
  /// authoritatively by Firestore, protecting against client clock skew.
  ///
  /// Called from [AIService.chatWithMentor] immediately after a successful
  /// Groq API response. The [uid] must be [FirebaseAuth.instance.currentUser?.uid].
  Future<void> saveChatToHistory({
    required String uid,
    required String prompt,
    required String response,
    String category = 'mentorChat',
  }) async {
    try {
      final entry = ActivityModel(
        id: '',       // Firestore will assign the autoId on add()
        userId: uid,
        prompt: prompt,
        response: response,
        category: category,
        // timestamp is omitted — FieldValue.serverTimestamp() is used in toMap()
      );

      await _userDoc(uid).collection('activities').add(entry.toMap());
      debugPrint('[Firestore] Chat saved to activities for $uid');
    } catch (e) {
      debugPrint('[Firestore] saveChatToHistory error: $e');
    }
  }

  /// Returns the most recent 50 chat history entries for [uid],
  /// ordered by timestamp descending.
  Future<List<ChatHistoryEntry>> getChatHistory(String uid) async {
    try {
      final snapshot = await _userDoc(uid)
          .collection('chatHistory')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return ChatHistoryEntry.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint('[Firestore] getChatHistory error: $e');
      return [];
    }
  }

  // ─── Real-Time Streams (for StreamBuilder) ────────────────────────────────

  /// Returns a real-time stream of the current user's activities,
  /// ordered by timestamp descending.
  ///
  /// Used by [ActivityHistoryList] to provide live updates via [StreamBuilder].
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserActivities(
      String uid) {
    return _userDoc(uid)
        .collection('activities')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Returns a real-time stream of ALL activities across ALL users
  /// using a Firestore **collection group query**.
  ///
  /// ⚠️ Requires a composite index on `activities` (collectionGroup)
  /// with `timestamp` descending. Firestore will log the index-creation
  /// URL to the console if the index does not exist yet.
  ///
  /// Only accessible from the Admin Dashboard.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllActivities() {
    return _db
        .collectionGroup('activities')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // ─── Role Check ───────────────────────────────────────────────────────────

  /// Returns the role string for [uid] (e.g. 'developer', 'admin').
  ///
  /// Returns `null` if the user document does not exist or lacks a role field.
  Future<String?> getUserRole(String uid) async {
    try {
      final snapshot = await _userDoc(uid).get();
      return snapshot.data()?['role'] as String?;
    } catch (e) {
      debugPrint('[Firestore] getUserRole error: $e');
      return null;
    }
  }

  /// Returns a real-time stream of the user document for role-based UI gating.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserDocument(
      String uid) {
    return _userDoc(uid).snapshots();
  }
}
