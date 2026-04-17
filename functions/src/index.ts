import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { analyzeCode } from './codeReview/analyzeCode';
import { generateLesson } from './learning/generateLesson';
import { analyzePronunciation } from './learning/analyzePronunciation';
import { chat } from './learning/chatbot';
import { updateProgress } from './user/updateProgress';

// Initialize Firebase Admin
admin.initializeApp();

// ═══════════════════════════════════════════════════════════════════
//  CODE REVIEW ENDPOINT
//  POST /codeReview
//  Analyzes code with syntax checking, AI review, caching, rate limiting
// ═══════════════════════════════════════════════════════════════════
export const codeReview = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 300, memory: '1GB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be logged in to use code review.'
      );
    }
    return await analyzeCode(data, context.auth.uid);
  });

// ═══════════════════════════════════════════════════════════════════
//  ENGLISH LESSON GENERATOR ENDPOINT
//  POST /lessonGenerator
//  Generates structured English lessons with exercises using AI
// ═══════════════════════════════════════════════════════════════════
export const lessonGenerator = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 120, memory: '512MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be logged in.'
      );
    }
    return await generateLesson(data, context.auth.uid);
  });

// ═══════════════════════════════════════════════════════════════════
//  PRONUNCIATION ANALYSIS ENDPOINT
//  POST /pronunciationAnalyzer
//  Accepts base64 audio + target phrase, returns accuracy & feedback
// ═══════════════════════════════════════════════════════════════════
export const pronunciationAnalyzer = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 60, memory: '512MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be logged in.'
      );
    }
    return await analyzePronunciation(data, context.auth.uid);
  });

// ═══════════════════════════════════════════════════════════════════
//  AI CHATBOT ENDPOINT
//  POST /aiChat
//  Conversational AI with context modes (technical English, code review)
// ═══════════════════════════════════════════════════════════════════
export const aiChat = functions
  .region('us-central1')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be logged in.'
      );
    }
    return await chat(data, context.auth.uid);
  });

// ═══════════════════════════════════════════════════════════════════
//  USER PROGRESS ENDPOINT
//  POST /saveProgress
//  Saves lesson completion, XP, streaks, achievements to Firestore
// ═══════════════════════════════════════════════════════════════════
export const saveProgress = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be logged in.'
      );
    }
    return await updateProgress(data, context.auth.uid);
  });
