import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/user_model.dart';

/// Service for Firestore database operations and serverless scaling.
///
/// Handles user document creation, retrieval, and field updates natively.
/// Migrated to utilize Cloud Functions (`FirebaseFunctions.instance`) for secure 
/// gamification metric manipulation (xp, level, streak), avoiding client-side state spoofing.
/// All methods are robust and gracefully fall back upon failure.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to the `users` collection.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection('users');

  // ─── User Document Management ─────────────────────────────────

  /// Ensures a user document exists in Firestore.
  ///
  /// If the document already exists, returns the stored data.
  /// If it doesn't exist, creates one with sensible defaults
  /// (level 1, xp 0, streak 0) and returns the new data.
  Future<Map<String, dynamic>?> ensureUserDocument({
    required String uid,
    required String name,
    required String email,
    String? photoURL,
  }) async {
    try {
      final docRef = _usersCollection.doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        // User already has a document — return existing data
        return snapshot.data();
      }

      // First-time user — create document with defaults
      final defaultData = <String, dynamic>{
        'uid': uid,
        'name': name,
        'email': email,
        'photoURL': photoURL,
        'xp': 0,
        'level': 1,
        'streak': 0,
        'longestStreak': 0,
        'lessonsCompleted': 0,
        'codeReviewsCompleted': 0,
        'proficiencyLevel': 'A1',
        'badges': <String>[],
        'hearts': 5,
        'gems': 0,
        'isPremium': false,
        'lastActiveDate': FieldValue.serverTimestamp(),
        'lastPracticeDate': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(defaultData);
      return defaultData;
    } catch (e) {
      debugPrint('FirestoreService.ensureUserDocument error: $e');
      return null;
    }
  }

  /// Fetches the user document for the given [uid].
  /// Returns null if not found or on error.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _usersCollection.doc(uid).get();
      return snapshot.data();
    } catch (e) {
      debugPrint('FirestoreService.getUserData error: $e');
      return null;
    }
  }

  // ─── XP & Progress Updates ────────────────────────────────────

  /// Awards XP to the user securely by invoking the Cloud Function.
  /// The backend manages level-up logic and transactional safely.
  Future<Map<String, dynamic>?> updateXp(String uid, int xpToAdd) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('saveProgress');
      final result = await callable.call({
        'result': {'xpEarned': xpToAdd},
      });
      // The backend returns success info, but for our provider to react instantly
      // we just pull the freshest document.
      final newDoc = await _usersCollection.doc(uid).get();
      return newDoc.data();
    } catch (e) {
      debugPrint('FirestoreService.updateXp error: $e');
      return null;
    }
  }

  /// Updates the user's daily streak securely via Cloud Function.
  Future<void> updateStreak(String uid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('saveProgress');
      await callable.call({'updateStreak': true});
    } catch (e) {
      debugPrint('FirestoreService.updateStreak error: $e');
    }
  }

  /// Safely route specific increments to the Cloud Function backend.
  Future<void> incrementField(String uid, String field, int amount) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('saveProgress');
      if (field == 'codeReviewsCompleted') {
        await callable.call({'codeReviewCompleted': true});
      } else if (field == 'lessonsCompleted') {
        await callable.call({
          'lessonId': 'manual_increment',
          'result': {'xpEarned': 0}, // just flag completion without extra XP
        });
      } else {
        // Attempt direct update for non-protected fields if necessary
        await _usersCollection.doc(uid).update({
          field: FieldValue.increment(amount),
        });
      }
    } catch (e) {
      debugPrint('FirestoreService.incrementField error: $e');
    }
  }

  /// Generic update for any fields on the user document.
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      await _usersCollection.doc(uid).update(fields);
    } catch (e) {
      debugPrint('FirestoreService.updateUserFields error: $e');
    }
  }
}
