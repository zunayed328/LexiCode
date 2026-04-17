import * as functions from 'firebase-functions';
import { OpenAI } from 'openai';
import { checkCache, saveToCache, hashCode } from '../utils/cache';
import { validateLessonInput } from '../utils/validation';
import { checkRateLimit } from '../utils/rateLimit';
import { getOpenAIKey } from '../config/apiKeys';

/**
 * Generates structured English lessons with exercises using AI.
 * Checks cache first (lessons are cached permanently since they're reusable).
 */
export async function generateLesson(data: any, userId: string): Promise<any> {
  // 1. Validate input
  const validation = validateLessonInput(data);
  if (!validation.valid) {
    throw new functions.https.HttpsError('invalid-argument', validation.error!);
  }

  // 2. Check rate limit
  const rateLimitCheck = await checkRateLimit(userId, 'lesson_generation');
  if (!rateLimitCheck.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      `Daily lesson limit reached. Resets in ${rateLimitCheck.resetIn} seconds.`
    );
  }

  const { unitId, lessonId, userLevel = 'A2', lessonType = 'general' } = data;

  // 3. Check cache (lessons cached for 7 days since they're reusable)
  const cacheKey = `lesson_${unitId}_${lessonId}_${userLevel}_${hashCode(lessonType)}`;
  const cached = await checkCache(cacheKey);
  if (cached) {
    return { lesson: cached, cached: true };
  }

  // 4. Generate lesson with AI
  try {
    const lesson = await callOpenAILessonGenerator(unitId, lessonId, userLevel, lessonType);

    // 5. Cache for 7 days (604800 seconds)
    await saveToCache(cacheKey, lesson, 604800);

    return { lesson, cached: false };
  } catch (error: any) {
    console.error('Lesson generation error:', error);

    // Fallback: return a basic pre-built lesson
    const fallback = buildFallbackLesson(unitId, lessonId, userLevel);
    return { lesson: fallback, cached: false, fallback: true };
  }
}

// ── Call OpenAI for lesson generation ──────────────────────────────

async function callOpenAILessonGenerator(
  unitId: string,
  lessonId: string,
  userLevel: string,
  lessonType: string
): Promise<any> {
  const openai = new OpenAI({ apiKey: getOpenAIKey() });

  const prompt = `You are an expert English teacher specializing in teaching programming professionals.
Generate a structured English lesson for a developer at ${userLevel} level.

Lesson context:
- Unit: ${unitId}
- Lesson: ${lessonId}
- Topic type: ${lessonType}
- Focus: Technical English for software developers

Generate a lesson with EXACTLY 5 exercises. Mix these types:
1. multipleChoice - 4 options, 1 correct
2. fillBlank - sentence with blank, 4 word choices
3. translation - translate a technical phrase

Respond with ONLY valid JSON:
{
  "id": "${lessonId}",
  "title": "Lesson Title",
  "description": "Brief description",
  "exercises": [
    {
      "type": "multipleChoice",
      "question": "Question text?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": 0,
      "explanation": "Why this is correct",
      "xpReward": 10
    },
    {
      "type": "fillBlank",
      "question": "Fill in: We need to _____ the codebase.",
      "options": ["refactor", "delete", "ignore", "copy"],
      "correctAnswer": 0,
      "explanation": "Refactor means to restructure code.",
      "xpReward": 10
    }
  ],
  "totalXp": 50,
  "estimatedMinutes": 5
}`;

  const completion = await openai.chat.completions.create({
    model: 'gpt-3.5-turbo', // Use cheaper model for lessons
    messages: [
      { role: 'system', content: 'You are an English teacher for developers. Respond with only valid JSON.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.7,
    max_tokens: 2000,
  });

  const responseText = completion.choices[0]?.message?.content || '{}';

  try {
    return JSON.parse(responseText);
  } catch {
    return buildFallbackLesson(unitId, lessonId, userLevel);
  }
}

// ── Fallback lesson when AI is unavailable ─────────────────────────

function buildFallbackLesson(unitId: string, lessonId: string, userLevel: string): any {
  return {
    id: lessonId,
    title: 'Technical Vocabulary Basics',
    description: 'Learn essential programming terms in English',
    exercises: [
      {
        type: 'multipleChoice',
        question: 'What does "deprecated" mean in programming?',
        options: [
          'No longer recommended for use',
          'Very popular and widely used',
          'Recently created',
          'Runs very fast',
        ],
        correctAnswer: 0,
        explanation: '"Deprecated" means a feature is outdated and developers are discouraged from using it.',
        xpReward: 10,
      },
      {
        type: 'fillBlank',
        question: 'We need to _____ this function to improve performance.',
        options: ['optimize', 'delete', 'ignore', 'copy'],
        correctAnswer: 0,
        explanation: '"Optimize" means to make something work as efficiently as possible.',
        xpReward: 10,
      },
      {
        type: 'multipleChoice',
        question: 'Which word means "to restructure code without changing its behavior"?',
        options: ['Refactor', 'Debug', 'Deploy', 'Compile'],
        correctAnswer: 0,
        explanation: '"Refactor" means reorganizing code to improve its internal structure.',
        xpReward: 10,
      },
      {
        type: 'multipleChoice',
        question: 'What is a "bug" in programming?',
        options: [
          'An error or flaw in the code',
          'A type of programming language',
          'A fast algorithm',
          'A testing framework',
        ],
        correctAnswer: 0,
        explanation: 'A "bug" is an error, flaw, or fault in a computer program.',
        xpReward: 10,
      },
      {
        type: 'fillBlank',
        question: 'The API returns a _____ when the request is successful.',
        options: ['response', 'error', 'crash', 'warning'],
        correctAnswer: 0,
        explanation: 'An API "response" is the data sent back by the server.',
        xpReward: 10,
      },
    ],
    totalXp: 50,
    estimatedMinutes: 5,
  };
}
