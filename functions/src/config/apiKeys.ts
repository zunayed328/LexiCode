import * as functions from 'firebase-functions';

/**
 * Retrieves API keys from Firebase Functions config.
 * Set keys via: firebase functions:config:set openai.key="sk-..."
 */
export function getOpenAIKey(): string {
  const config = functions.config();
  const key = config.openai?.key;
  if (!key) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'OpenAI API key not configured. Run: firebase functions:config:set openai.key="sk-..."'
    );
  }
  return key;
}

export function getAnthropicKey(): string | null {
  const config = functions.config();
  return config.anthropic?.key || null;
}

export function getGoogleAIKey(): string | null {
  const config = functions.config();
  return config.googleai?.key || null;
}
