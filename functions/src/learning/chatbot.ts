import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { OpenAI } from 'openai';
import { validateChatInput } from '../utils/validation';
import { checkRateLimit } from '../utils/rateLimit';
import { getOpenAIKey } from '../config/apiKeys';

/**
 * AI chatbot with context-aware conversation.
 * Supports context modes: technical_english, code_review, general
 */
export async function chat(data: any, userId: string): Promise<any> {
  // 1. Validate input
  const validation = validateChatInput(data);
  if (!validation.valid) {
    throw new functions.https.HttpsError('invalid-argument', validation.error!);
  }

  // 2. Check rate limit
  const rateLimitCheck = await checkRateLimit(userId, 'chat');
  if (!rateLimitCheck.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      `Daily chat limit reached. Resets in ${rateLimitCheck.resetIn} seconds.`
    );
  }

  const { message, context = 'general', conversationHistory = [] } = data;

  try {
    const openai = new OpenAI({ apiKey: getOpenAIKey() });

    // Build system prompt based on context
    const systemPrompt = getSystemPrompt(context);

    // Build messages array
    const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
      { role: 'system', content: systemPrompt },
    ];

    // Add conversation history (last 10 messages max)
    const recentHistory = conversationHistory.slice(-10);
    for (const msg of recentHistory) {
      if (msg.role && msg.content) {
        messages.push({
          role: msg.role as 'user' | 'assistant',
          content: msg.content,
        });
      }
    }

    // Add current message
    messages.push({ role: 'user', content: message });

    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo', // Use cheaper model for chat
      messages,
      temperature: 0.7,
      max_tokens: 1000,
    });

    const response = completion.choices[0]?.message?.content || 'I couldn\'t generate a response. Please try again.';

    // Save conversation to Firestore for history
    await saveConversationMessage(userId, message, response, context);

    return {
      response,
      context,
      tokensUsed: completion.usage?.total_tokens || 0,
    };
  } catch (error: any) {
    console.error('Chat error:', error);

    // Fallback: return a pre-built response
    const fallbackResponse = getFallbackResponse(message, context);
    return {
      response: fallbackResponse,
      context,
      fallback: true,
    };
  }
}

// ── Context-specific system prompts ────────────────────────────────

function getSystemPrompt(context: string): string {
  switch (context) {
    case 'technical_english':
      return `You are a friendly English mentor for software developers. Help them improve their technical English.
Focus on:
- Programming vocabulary and terminology
- Professional communication (emails, PR descriptions, standups)
- Common phrases used in tech meetings
- Code documentation writing
Keep responses concise and practical. Use examples from real software development.`;

    case 'code_review':
      return `You are a senior developer mentor. Help the user understand code review concepts in English.
Focus on:
- How to describe code issues professionally
- Common code review terminology
- Best practices for giving and receiving feedback
- Writing clear commit messages and PR descriptions
Keep responses developer-friendly and educational.`;

    default:
      return `You are a friendly AI mentor for LexiCode app. Help developers improve both their coding skills and English language proficiency.
Be concise, supportive, and use examples from real software development when possible.
If the user asks about code, provide brief, helpful explanations.
If they ask about English, focus on technical communication.`;
  }
}

// ── Fallback responses when AI is unavailable ──────────────────────

function getFallbackResponse(message: string, context: string): string {
  const responses: Record<string, string[]> = {
    technical_english: [
      'That\'s a great question! In software development, clear communication is key. Try breaking your message into smaller, more specific parts.',
      'Great progress! When writing technical documentation, always start with the "what" and then explain the "why".',
      'In professional settings, use precise language: instead of "fix the bug", try "resolve the defect in the authentication module".',
    ],
    code_review: [
      'When reviewing code, focus on: correctness, readability, performance, and security. Start with the positive aspects!',
      'A good PR description includes: what changed, why it changed, and how to test it.',
      'Use specific language in code reviews. Instead of "this looks wrong", try "this could cause a null reference on line 42".',
    ],
    general: [
      'That\'s a great question! In software development, this concept is fundamental.',
      'I\'d recommend breaking this down into smaller components.',
      'Think of it like building blocks — each function should do one thing well.',
    ],
  };

  const contextResponses = responses[context] || responses.general;
  return contextResponses[message.length % contextResponses.length];
}

// ── Save conversation to Firestore ─────────────────────────────────

async function saveConversationMessage(
  userId: string,
  userMessage: string,
  aiResponse: string,
  context: string
): Promise<void> {
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('conversations')
      .add({
        userMessage,
        aiResponse,
        context,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (error) {
    console.error('Conversation save error:', error);
  }
}
