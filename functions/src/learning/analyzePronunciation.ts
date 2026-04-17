import * as functions from 'firebase-functions';
import { OpenAI } from 'openai';
import { validatePronunciationInput } from '../utils/validation';
import { checkRateLimit } from '../utils/rateLimit';
import { getOpenAIKey } from '../config/apiKeys';

/**
 * Analyzes pronunciation by:
 * 1. Accepting base64 audio + target phrase
 * 2. Using OpenAI Whisper to transcribe
 * 3. Comparing transcription to target phrase
 * 4. Returning accuracy score and feedback
 */
export async function analyzePronunciation(data: any, userId: string): Promise<any> {
  // 1. Validate input
  const validation = validatePronunciationInput(data);
  if (!validation.valid) {
    throw new functions.https.HttpsError('invalid-argument', validation.error!);
  }

  // 2. Check rate limit
  const rateLimitCheck = await checkRateLimit(userId, 'pronunciation');
  if (!rateLimitCheck.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      `Daily pronunciation limit reached. Resets in ${rateLimitCheck.resetIn} seconds.`
    );
  }

  const { audioData, targetPhrase, language = 'en-US' } = data;

  try {
    const openai = new OpenAI({ apiKey: getOpenAIKey() });

    // 3. Transcribe audio using Whisper
    // Convert base64 to buffer for the API
    const audioBuffer = Buffer.from(audioData, 'base64');

    // Create a File-like object for the API
    const file = new File([audioBuffer], 'audio.webm', { type: 'audio/webm' });

    const transcription = await openai.audio.transcriptions.create({
      file: file,
      model: 'whisper-1',
      language: language.split('-')[0], // 'en' from 'en-US'
    });

    const spokenText = transcription.text;

    // 4. Compare transcription to target
    const accuracy = calculateAccuracy(spokenText, targetPhrase);
    const problemAreas = findProblemAreas(spokenText, targetPhrase);
    const feedback = generateFeedback(accuracy, problemAreas, targetPhrase);

    return {
      accuracy,
      spokenText,
      targetPhrase,
      feedback,
      problemAreas,
      overallScore: accuracy,
    };
  } catch (error: any) {
    console.error('Pronunciation analysis error:', error);

    // Fallback: return a simulated result
    return {
      accuracy: 75,
      spokenText: '(Audio processing unavailable)',
      targetPhrase,
      feedback: 'Audio analysis is temporarily unavailable. Please try again later.',
      problemAreas: [],
      overallScore: 75,
      fallback: true,
    };
  }
}

// ── Calculate word-level accuracy ──────────────────────────────────

function calculateAccuracy(spoken: string, target: string): number {
  const spokenWords = spoken.toLowerCase().split(/\s+/).filter(Boolean);
  const targetWords = target.toLowerCase().split(/\s+/).filter(Boolean);

  if (targetWords.length === 0) return 0;

  let matches = 0;
  for (const targetWord of targetWords) {
    // Check for exact match or close match (1 char difference)
    if (spokenWords.some((w) => w === targetWord || levenshteinDistance(w, targetWord) <= 1)) {
      matches++;
    }
  }

  return Math.round((matches / targetWords.length) * 100);
}

// ── Find words the user struggled with ─────────────────────────────

function findProblemAreas(spoken: string, target: string): string[] {
  const spokenWords = spoken.toLowerCase().split(/\s+/).filter(Boolean);
  const targetWords = target.toLowerCase().split(/\s+/).filter(Boolean);
  const problems: string[] = [];

  for (const targetWord of targetWords) {
    const hasMatch = spokenWords.some(
      (w) => w === targetWord || levenshteinDistance(w, targetWord) <= 1
    );
    if (!hasMatch) {
      problems.push(targetWord);
    }
  }

  return problems;
}

// ── Generate human-readable feedback ───────────────────────────────

function generateFeedback(accuracy: number, problems: string[], target: string): string {
  if (accuracy >= 95) {
    return 'Excellent pronunciation! You nailed it! 🎯';
  } else if (accuracy >= 85) {
    return `Good pronunciation! ${problems.length > 0 ? `Work on: "${problems.join('", "')}"` : 'Keep practicing!'}`;
  } else if (accuracy >= 70) {
    return `Decent attempt! Focus on these words: "${problems.join('", "')}"`;
  } else if (accuracy >= 50) {
    return `Keep practicing! Try saying each word slowly: "${target}"`;
  } else {
    return `Try again! Listen to the correct pronunciation and repeat slowly: "${target}"`;
  }
}

// ── Levenshtein distance for fuzzy matching ────────────────────────

function levenshteinDistance(a: string, b: string): number {
  const matrix: number[][] = [];

  for (let i = 0; i <= b.length; i++) matrix[i] = [i];
  for (let j = 0; j <= a.length; j++) matrix[0][j] = j;

  for (let i = 1; i <= b.length; i++) {
    for (let j = 1; j <= a.length; j++) {
      if (b[i - 1] === a[j - 1]) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1, // substitution
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j] + 1      // deletion
        );
      }
    }
  }

  return matrix[b.length][a.length];
}
