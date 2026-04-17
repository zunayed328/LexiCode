/**
 * Supported programming languages for code review.
 */
const SUPPORTED_LANGUAGES = [
  'dart', 'python', 'javascript', 'typescript',
  'java', 'c#', 'c++', 'c', 'go', 'swift',
  'rust', 'kotlin', 'php',
];

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

/**
 * Validate code review input data.
 */
export function validateCodeInput(data: any): ValidationResult {
  if (!data) {
    return { valid: false, error: 'Request body is required.' };
  }

  if (!data.code || typeof data.code !== 'string') {
    return { valid: false, error: 'Code is required and must be a string.' };
  }

  if (data.code.trim().length < 10) {
    return { valid: false, error: 'Code must be at least 10 characters long.' };
  }

  if (data.code.length > 50000) {
    return { valid: false, error: 'Code must be less than 50,000 characters.' };
  }

  if (!data.language || typeof data.language !== 'string') {
    return { valid: false, error: 'Programming language is required.' };
  }

  const lang = data.language.toLowerCase();
  if (!SUPPORTED_LANGUAGES.includes(lang)) {
    return {
      valid: false,
      error: `Unsupported language: "${data.language}". Supported: ${SUPPORTED_LANGUAGES.join(', ')}`,
    };
  }

  return { valid: true };
}

/**
 * Validate lesson generation input data.
 */
export function validateLessonInput(data: any): ValidationResult {
  if (!data) {
    return { valid: false, error: 'Request body is required.' };
  }

  if (!data.unitId || typeof data.unitId !== 'string') {
    return { valid: false, error: 'unitId is required.' };
  }

  if (!data.lessonId || typeof data.lessonId !== 'string') {
    return { valid: false, error: 'lessonId is required.' };
  }

  const validLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  if (data.userLevel && !validLevels.includes(data.userLevel)) {
    return { valid: false, error: `Invalid level. Must be one of: ${validLevels.join(', ')}` };
  }

  return { valid: true };
}

/**
 * Validate chat input data.
 */
export function validateChatInput(data: any): ValidationResult {
  if (!data) {
    return { valid: false, error: 'Request body is required.' };
  }

  if (!data.message || typeof data.message !== 'string') {
    return { valid: false, error: 'Message is required.' };
  }

  if (data.message.length > 5000) {
    return { valid: false, error: 'Message must be less than 5,000 characters.' };
  }

  return { valid: true };
}

/**
 * Validate pronunciation analysis input.
 */
export function validatePronunciationInput(data: any): ValidationResult {
  if (!data) {
    return { valid: false, error: 'Request body is required.' };
  }

  if (!data.audioData || typeof data.audioData !== 'string') {
    return { valid: false, error: 'Audio data (base64) is required.' };
  }

  if (!data.targetPhrase || typeof data.targetPhrase !== 'string') {
    return { valid: false, error: 'Target phrase is required.' };
  }

  // Check base64 size (rough limit: ~10MB encoded)
  if (data.audioData.length > 14_000_000) {
    return { valid: false, error: 'Audio data too large. Max ~10MB.' };
  }

  return { valid: true };
}
