import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { OpenAI } from 'openai';
import { checkCache, saveToCache, hashCode } from '../utils/cache';
import { validateCodeInput } from '../utils/validation';
import { checkRateLimit } from '../utils/rateLimit';
import { getOpenAIKey } from '../config/apiKeys';
import { checkSyntax, SyntaxErrorResult } from './syntaxChecker';

/**
 * Analyzes code with syntax checking first, then AI-powered comprehensive review.
 * Flow:
 * 1. Validate input
 * 2. Check rate limit
 * 3. Check cache
 * 4. Run local syntax check
 * 5. If syntax errors → return immediately with score 0
 * 6. If clean → call OpenAI for comprehensive analysis
 * 7. Cache result, track usage
 */
export async function analyzeCode(data: any, userId: string): Promise<any> {
  // 1. Validate input
  const validation = validateCodeInput(data);
  if (!validation.valid) {
    throw new functions.https.HttpsError('invalid-argument', validation.error!);
  }

  // 2. Check rate limit
  const rateLimitCheck = await checkRateLimit(userId, 'code_review');
  if (!rateLimitCheck.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      `Daily review limit reached. Resets in ${rateLimitCheck.resetIn} seconds. Remaining: ${rateLimitCheck.remaining ?? 0}`
    );
  }

  const code: string = data.code;
  const language: string = data.language;
  const userLevel: string = data.userLevel || 'B1';

  // 3. Check cache
  const cacheKey = `code_review_${language.toLowerCase()}_${hashCode(code)}`;
  const cached = await checkCache(cacheKey);
  if (cached) {
    return { ...cached, cached: true };
  }

  // 4. Run local syntax check
  const syntaxErrors = checkSyntax(code, language);

  // 5. If syntax errors found → return immediately with score 0
  if (syntaxErrors.length > 0) {
    const result = buildSyntaxErrorResult(code, language, syntaxErrors);
    await saveToCache(cacheKey, result, 86400);
    await trackUsage(userId, language, code.length, 'syntax_only');
    return { ...result, cached: false };
  }

  // 6. Call OpenAI for comprehensive analysis
  try {
    const aiResult = await callOpenAICodeReview(code, language, userLevel);

    // 7. Cache result (24 hours) and track usage
    await saveToCache(cacheKey, aiResult, 86400);
    await trackUsage(userId, language, code.length, 'full_review');

    return { ...aiResult, cached: false };
  } catch (error: any) {
    console.error('OpenAI API error:', error);

    // Fallback: return local-only analysis
    const fallbackResult = buildLocalOnlyResult(code, language);
    return { ...fallbackResult, cached: false, fallback: true };
  }
}

// ── Build result for syntax errors (score = 0) ─────────────────────

function buildSyntaxErrorResult(
  code: string,
  language: string,
  syntaxErrors: SyntaxErrorResult[]
): any {
  const issues = syntaxErrors.map((e) => ({
    title: e.message,
    description: `Line ${e.line}${e.column ? `, Column ${e.column}` : ''}: ${e.message}`,
    simpleExplanation: e.description || 'This is a syntax error that prevents your code from running.',
    severity: 'critical',
    type: 'syntax',
    lineNumber: e.line,
    column: e.column,
    suggestion: `Change: "${e.code}" → "${e.fix}"`,
    codeExample: e.code,
    explanation: e.description || 'This syntax error prevents your code from compiling or running.',
    exampleFix: e.fix,
  }));

  const fixedCode = applySyntaxFixes(code, syntaxErrors);
  const changedLines = [...new Set(syntaxErrors.map((e) => e.line))].sort((a, b) => a - b);

  return {
    originalCode: code,
    language,
    overallScore: 0,
    ratings: { quality: 0, security: 0, performance: 0, maintainability: 0 },
    issues,
    suggestions: ['Fix all syntax errors before submitting for code review'],
    explanation: `Your code has ${syntaxErrors.length} syntax error${syntaxErrors.length > 1 ? 's' : ''} that prevent it from running.`,
    newVocabulary: [
      'syntax - the set of rules that defines the structure of a programming language',
      'colon - the character (:) used to start code blocks in Python',
      'semicolon - the character (;) used to end statements in many languages',
    ],
    fixedCode,
    changedLines,
    summary: `Code has ${syntaxErrors.length} syntax error${syntaxErrors.length > 1 ? 's' : ''} and will not run/compile.`,
    hasSyntaxErrors: true,
    syntaxErrors: syntaxErrors.map((e) => ({
      line: e.line,
      column: e.column,
      message: e.message,
      code: e.code,
      fix: e.fix,
      description: e.description,
    })),
    processingTime: '0.5s',
  };
}

// ── Apply syntax fixes to generate corrected code ──────────────────

function applySyntaxFixes(code: string, syntaxErrors: SyntaxErrorResult[]): string {
  const lines = code.split('\n');
  const errorsByLine: Record<number, SyntaxErrorResult[]> = {};

  for (const err of syntaxErrors) {
    if (!errorsByLine[err.line]) errorsByLine[err.line] = [];
    errorsByLine[err.line].push(err);
  }

  for (const lineStr of Object.keys(errorsByLine)) {
    const lineIdx = parseInt(lineStr) - 1;
    if (lineIdx >= 0 && lineIdx < lines.length) {
      const err = errorsByLine[parseInt(lineStr)][0];
      if (lines[lineIdx].includes(err.code)) {
        lines[lineIdx] = lines[lineIdx].replace(err.code, err.fix);
      } else {
        const indent = lines[lineIdx].length - lines[lineIdx].trimStart().length;
        lines[lineIdx] = ' '.repeat(indent) + err.fix;
      }
    }
  }

  return `// Syntax fixes applied\n${lines.join('\n')}`;
}

// ── Call OpenAI for comprehensive code review ──────────────────────

async function callOpenAICodeReview(
  code: string,
  language: string,
  userLevel: string
): Promise<any> {
  const openai = new OpenAI({ apiKey: getOpenAIKey() });

  const prompt = `You are a senior software engineer performing a code review.
Analyze the following ${language} code and provide a structured JSON response.
The user's English level is ${userLevel}, so keep explanations at that level.

CODE:
\`\`\`${language.toLowerCase()}
${code}
\`\`\`

Respond with ONLY valid JSON in this exact format:
{
  "overallScore": <0-100>,
  "ratings": {
    "quality": <0-100>,
    "security": <0-100>,
    "performance": <0-100>,
    "maintainability": <0-100>
  },
  "issues": [
    {
      "title": "Issue title",
      "description": "Detailed description",
      "simpleExplanation": "Simple explanation with emoji",
      "severity": "critical|error|warning|info",
      "type": "bug|security|performance|style|bestPractice",
      "lineNumber": <line number or null>,
      "suggestion": "How to fix",
      "codeExample": "problematic code",
      "explanation": "Why this matters",
      "exampleFix": "corrected code"
    }
  ],
  "suggestions": ["suggestion1", "suggestion2"],
  "explanation": "Overall explanation of the code",
  "newVocabulary": ["term1 - definition1", "term2 - definition2"],
  "fixedCode": "the corrected version of the entire code",
  "summary": "Brief summary of findings"
}`;

  const startTime = Date.now();

  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: 'You are a senior software engineer. Respond with only valid JSON.' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.3,
    max_tokens: 3000,
  });

  const processingTime = ((Date.now() - startTime) / 1000).toFixed(1);
  const responseText = completion.choices[0]?.message?.content || '{}';

  let result: any;
  try {
    result = JSON.parse(responseText);
  } catch {
    // If JSON parsing fails, wrap the response
    result = {
      overallScore: 70,
      ratings: { quality: 70, security: 75, performance: 70, maintainability: 70 },
      issues: [],
      suggestions: ['AI analysis returned non-structured response.'],
      explanation: responseText.substring(0, 500),
      newVocabulary: [],
      fixedCode: code,
      summary: 'Analysis completed with partial results.',
    };
  }

  // Determine changed lines by comparing original and fixed code
  const changedLines = getChangedLines(code, result.fixedCode || code);

  return {
    originalCode: code,
    language,
    overallScore: result.overallScore ?? 70,
    ratings: result.ratings ?? { quality: 70, security: 75, performance: 70, maintainability: 70 },
    issues: result.issues ?? [],
    suggestions: result.suggestions ?? [],
    explanation: result.explanation ?? '',
    newVocabulary: result.newVocabulary ?? [],
    fixedCode: result.fixedCode ?? code,
    changedLines,
    summary: result.summary ?? '',
    hasSyntaxErrors: false,
    syntaxErrors: [],
    processingTime: `${processingTime}s`,
  };
}

// ── Get changed line numbers between original and fixed code ───────

function getChangedLines(original: string, fixed: string): number[] {
  const origLines = original.split('\n');
  const fixedLines = fixed.split('\n');
  const changed: number[] = [];

  const maxLen = Math.max(origLines.length, fixedLines.length);
  for (let i = 0; i < maxLen; i++) {
    if ((origLines[i] || '') !== (fixedLines[i] || '')) {
      changed.push(i + 1);
    }
  }

  return changed;
}

// ── Build local-only fallback result (no AI) ───────────────────────

function buildLocalOnlyResult(code: string, language: string): any {
  const issues: any[] = [];
  const lines = code.split('\n');

  // Division by zero check
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('/') && !lines[i].includes('//') && !lines[i].includes('http') &&
        (lines[i].includes('/ ') || lines[i].match(/\/[a-z]/))) {
      if (!code.includes('== 0') && !code.includes('!= 0')) {
        issues.push({
          title: 'Potential division by zero',
          description: 'Division without checking if the divisor is zero.',
          simpleExplanation: '💡 When you divide by zero, your program crashes.',
          severity: 'critical', type: 'bug', lineNumber: i + 1,
          suggestion: 'Add a zero-check before performing division.',
        });
        break;
      }
    }
  }

  // Missing error handling
  if (!code.includes('try') && !code.includes('catch') && !code.includes('except')) {
    issues.push({
      title: 'No error handling detected',
      description: 'Operations that might fail should be wrapped in error handling.',
      simpleExplanation: '💡 Error handling keeps your app safe from crashes!',
      severity: 'error', type: 'security',
      suggestion: 'Wrap risky operations in try-catch blocks.',
    });
  }

  // Debug statements
  if (code.includes('print(') || code.includes('console.log(')) {
    issues.push({
      title: 'Debug statements detected',
      description: 'Print/console.log should be removed in production.',
      simpleExplanation: '💡 Use a proper logging framework instead.',
      severity: 'warning', type: 'bestPractice',
      suggestion: 'Use a logging framework instead.',
    });
  }

  const score = Math.max(0, 100 - issues.length * 15);

  return {
    originalCode: code,
    language,
    overallScore: score,
    ratings: { quality: score, security: 75, performance: 80, maintainability: 70 },
    issues,
    suggestions: ['Consider adding unit tests', 'Validate all user inputs'],
    explanation: `Local analysis of ${language} code (AI service unavailable).`,
    newVocabulary: [],
    fixedCode: code,
    changedLines: [],
    summary: `Local analysis found ${issues.length} issue${issues.length !== 1 ? 's' : ''}.`,
    hasSyntaxErrors: false,
    syntaxErrors: [],
    processingTime: '0.1s',
  };
}

// ── Track API usage ────────────────────────────────────────────────

async function trackUsage(
  userId: string,
  language: string,
  codeLength: number,
  reviewType: string
): Promise<void> {
  try {
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('api_usage')
      .add({
        type: 'code_review',
        reviewType,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        language,
        codeLength,
      });
  } catch (error) {
    console.error('Usage tracking error:', error);
  }
}
