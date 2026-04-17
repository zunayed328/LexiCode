import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Saves user progress data to Firestore:
 * - Lesson completion
 * - XP gains
 * - Streak updates
 * - Achievement tracking
 */
export async function updateProgress(data: any, userId: string): Promise<any> {
  if (!data) {
    throw new functions.https.HttpsError('invalid-argument', 'Progress data is required.');
  }

  const userRef = admin.firestore().collection('users').doc(userId);
  const now = admin.firestore.FieldValue.serverTimestamp();

  try {
    // Use a transaction for atomic updates
    const result = await admin.firestore().runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      let userData: any;
      if (!userDoc.exists) {
        // Create new user document
        userData = {
          xp: 0,
          level: 1,
          streak: 0,
          lessonsCompleted: 0,
          codeReviewsCompleted: 0,
          proficiencyLevel: 'A1',
          badges: [],
          lastActiveDate: now,
          createdAt: now,
        };
        transaction.set(userRef, userData);
      } else {
        userData = userDoc.data()!;
      }

      const updates: any = {
        lastActiveDate: now,
      };

      // Handle lesson completion
      if (data.lessonId && data.result) {
        updates.lessonsCompleted = admin.firestore.FieldValue.increment(1);

        // Add XP from lesson
        const xpGained = data.result.xpEarned || 10;
        updates.xp = admin.firestore.FieldValue.increment(xpGained);

        // Save lesson result
        const lessonResultRef = userRef.collection('lesson_results').doc(data.lessonId);
        transaction.set(lessonResultRef, {
          lessonId: data.lessonId,
          score: data.result.score || 0,
          xpEarned: xpGained,
          correctAnswers: data.result.correctAnswers || 0,
          totalQuestions: data.result.totalQuestions || 0,
          completedAt: now,
        });
      }

      // Handle code review completion
      if (data.codeReviewCompleted) {
        updates.codeReviewsCompleted = admin.firestore.FieldValue.increment(1);
        updates.xp = admin.firestore.FieldValue.increment(25);
      }

      // Handle streak update
      if (data.updateStreak) {
        const lastActive = userData.lastActiveDate?.toDate();
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        if (lastActive) {
          const lastActiveDay = new Date(lastActive);
          lastActiveDay.setHours(0, 0, 0, 0);

          const diffDays = Math.floor(
            (today.getTime() - lastActiveDay.getTime()) / (1000 * 60 * 60 * 24)
          );

          if (diffDays === 1) {
            // Consecutive day — increment streak
            updates.streak = admin.firestore.FieldValue.increment(1);
          } else if (diffDays > 1) {
            // Streak broken — reset to 1
            updates.streak = 1;
          }
          // diffDays === 0: same day, don't update streak
        } else {
          updates.streak = 1;
        }
      }

      // Handle level-up check
      const currentXp = (userData.xp || 0) + (data.result?.xpEarned || 0);
      const currentLevel = userData.level || 1;
      const xpForNextLevel = currentLevel * 500;
      if (currentXp >= xpForNextLevel) {
        updates.level = admin.firestore.FieldValue.increment(1);
      }

      // Handle badge/achievement unlocks
      if (data.badges && Array.isArray(data.badges)) {
        updates.badges = admin.firestore.FieldValue.arrayUnion(...data.badges);
      }

      // Handle proficiency level update
      if (data.proficiencyLevel) {
        updates.proficiencyLevel = data.proficiencyLevel;
      }

      transaction.update(userRef, updates);

      return {
        success: true,
        xpGained: data.result?.xpEarned || (data.codeReviewCompleted ? 25 : 0),
        updatedFields: Object.keys(updates),
      };
    });

    return result;
  } catch (error: any) {
    console.error('Progress update error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to save progress. Please try again.'
    );
  }
}
