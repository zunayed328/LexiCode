import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/code_review_model.dart';
import 'firestore_service.dart';

/// Thrown when the submitted code does not match the selected language.
class LanguageMismatchException implements Exception {
  final String selectedLanguage;
  final String detectedLanguage;

  const LanguageMismatchException({
    required this.selectedLanguage,
    required this.detectedLanguage,
  });

  @override
  String toString() =>
      'LanguageMismatchException: selected=$selectedLanguage, detected=$detectedLanguage';
}

class AIService {
  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  final FirestoreService _firestoreService = FirestoreService();

  // ─── Language Mismatch Detection ──────────────────────────────

  /// Strong keyword indicators per language. A match requires 2+ hits.
  static const Map<String, List<String>> _languageSignatures = {
    'Dart': [
      'import \'package:',
      'Widget ',
      'StatelessWidget',
      'StatefulWidget',
      '@override',
      'BuildContext',
      'setState(',
      'final ',
      'late ',
    ],
    'Python': [
      'def ',
      'elif ',
      'import ',
      'self.',
      '__init__',
      'print(',
      'class :',
      'from ',
      'except ',
      'True',
      'False',
      'None',
    ],
    'JavaScript': [
      'console.log',
      'function ',
      'const ',
      'let ',
      'var ',
      '=>',
      'document.',
      'require(',
      'module.exports',
    ],
    'TypeScript': [
      'interface ',
      ': string',
      ': number',
      ': boolean',
      'import {',
      'export ',
      'type ',
      'as const',
    ],
    'Java': [
      'public class',
      'System.out',
      'import java.',
      'void main(String',
      'private ',
      'protected ',
      '@Override',
      'throws ',
    ],
    'Kotlin': [
      'fun ',
      'val ',
      'println(',
      'package ',
      'suspend ',
      'override fun',
      'companion object',
      'data class',
    ],
    'Swift': [
      'func ',
      'import UIKit',
      'import Foundation',
      'guard ',
      'let ',
      'struct ',
      '@IBOutlet',
      'override func',
    ],
    'Go': [
      'package main',
      'func main()',
      'fmt.',
      'import (',
      ':= ',
      'func (',
      'go func',
      'chan ',
    ],
    'Rust': [
      'fn main()',
      'let mut',
      'println!',
      'use std::',
      'impl ',
      '-> ',
      'pub fn',
      '&self',
    ],
    'C++': [
      '#include',
      'cout',
      'std::',
      'int main(',
      'using namespace',
      'cin',
      'endl',
      '::',
    ],
    'C#': [
      'using System',
      'namespace ',
      'Console.Write',
      'static void Main',
      'public class',
      'private ',
      'get;',
      'set;',
    ],
    'PHP': [
      '<?php',
      '\$this->',
      'echo ',
      'function ',
      'namespace ',
      'use ',
      '->',
      '::class',
    ],
  };

  /// Returns the detected language name if there is a mismatch,
  /// or `null` if no mismatch is detected.
  String? _detectLanguageMismatch(String code, String selectedLang) {
    // Score every language by how many keyword hits it gets
    final scores = <String, int>{};
    for (final entry in _languageSignatures.entries) {
      int hits = 0;
      for (final keyword in entry.value) {
        if (code.contains(keyword)) hits++;
      }
      if (hits >= 2) scores[entry.key] = hits;
    }

    if (scores.isEmpty) return null; // Can't determine — let AI handle it

    // Find the language with the highest score
    final bestMatch = scores.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    // Only flag a mismatch if the best match is NOT the selected language
    // and the selected language scored significantly lower
    final selectedScore = scores[selectedLang] ?? 0;
    if (bestMatch.key != selectedLang && bestMatch.value > selectedScore + 1) {
      return bestMatch.key;
    }

    return null;
  }

  /// Sends a chat-completion request to the Groq API and returns the
  /// parsed JSON body from the assistant's response.
  Future<Map<String, dynamic>?> _callGroq(
    List<Map<String, String>> messages, {
    bool jsonMode = false,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'temperature': 0.3,
      'max_tokens': 4096,
    };

    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices'][0]['message']['content'] as String;
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        debugPrint('Groq API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error calling Groq API: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> analyzeAndFixCode(String brokenCode) async {
    final messages = [
      {
        'role': 'system',
        'content':
            'You are an expert programming instructor and English language teacher. '
            'You always respond with valid JSON only.',
      },
      {
        'role': 'user',
        'content':
            'The user will provide broken code. Analyze it, fix errors, and provide '
            'an English learning moment. Respond ONLY with a valid JSON object '
            'containing exactly two keys: "fixed_code" and "english_tip".\n\n'
            'Here is the broken code:\n$brokenCode',
      },
    ];

    return _callGroq(messages, jsonMode: true);
  }

  /// Analyzes code and returns a [CodeReviewResult].
  /// Used by AppProvider for the code review flow.
  Future<CodeReviewResult> analyzeCode(String code, String language) async {
    // Pre-check: detect language mismatch before spending an API call
    final mismatch = _detectLanguageMismatch(code, language);
    if (mismatch != null) {
      throw LanguageMismatchException(
        selectedLanguage: language,
        detectedLanguage: mismatch,
      );
    }

    final messages = [
      {
        'role': 'system',
        'content':
            'You are an expert code reviewer. You always respond with valid JSON only.',
      },
      {
        'role': 'user',
        'content':
            '''Analyze the following $language code and return a JSON object with these keys:
- "overallScore": integer 0-100
- "language": "$language"
- "originalCode": the original code
- "issues": array of objects with keys: "title", "description", "simpleExplanation", "severity" (one of: "critical","error","warning","info"), "type" (one of: "syntax","bug","security","performance","style","bestPractice"), "lineNumber" (int or null), "suggestion", "codeExample"
- "suggestions": array of improvement suggestion strings
- "explanation": overall explanation string
- "newVocabulary": array of programming term strings the user should learn
- "fixedCode": the corrected version of the code
- "summary": short summary of the review
- "hasSyntaxErrors": boolean
- "syntaxErrors": array of objects with "line", "message", "code", "fix"
- "ratings": object with keys "readability","performance","security","bestPractices" each mapped to int 0-100
- "changedLines": array of line numbers that were changed

Here is the code:
$code''',
      },
    ];

    try {
      final data = await _callGroq(messages, jsonMode: true);
      if (data != null) {
        return _parseCodeReviewResult(data, code, language);
      }
    } catch (e) {
      print('Error in analyzeCode: $e');
    }

    // Return a fallback result on failure
    return CodeReviewResult(
      originalCode: code,
      language: language,
      overallScore: 0,
      ratings: {},
      issues: [],
      suggestions: ['Analysis failed. Please try again.'],
      explanation: 'Could not analyze code.',
      newVocabulary: [],
      fixedCode: code,
      changedLines: [],
      summary: 'Analysis failed',
      hasSyntaxErrors: false,
      syntaxErrors: [],
    );
  }

  CodeReviewResult _parseCodeReviewResult(
    Map<String, dynamic> data,
    String originalCode,
    String language,
  ) {
    final issuesList =
        (data['issues'] as List<dynamic>?)?.map((i) {
          final m = Map<String, dynamic>.from(i);
          return CodeIssue(
            title: m['title'] ?? '',
            description: m['description'] ?? '',
            simpleExplanation: m['simpleExplanation'] ?? '',
            severity: _parseSeverity(m['severity']),
            type: _parseIssueType(m['type']),
            lineNumber: m['lineNumber'],
            suggestion: m['suggestion'],
            codeExample: m['codeExample'],
          );
        }).toList() ??
        [];

    final syntaxErrorsList =
        (data['syntaxErrors'] as List<dynamic>?)?.map((e) {
          final m = Map<String, dynamic>.from(e);
          return SyntaxError(
            line: m['line'] ?? 0,
            column: m['column'],
            message: m['message'] ?? '',
            code: m['code'] ?? '',
            fix: m['fix'] ?? '',
            description: m['description'],
          );
        }).toList() ??
        [];

    final ratingsRaw = data['ratings'];
    final ratings = <String, int>{};
    if (ratingsRaw is Map) {
      for (final entry in ratingsRaw.entries) {
        ratings[entry.key.toString()] = (entry.value is num)
            ? (entry.value as num).toInt()
            : 0;
      }
    }

    return CodeReviewResult(
      originalCode: data['originalCode'] ?? originalCode,
      language: data['language'] ?? language,
      overallScore: (data['overallScore'] as num?)?.toInt() ?? 0,
      ratings: ratings,
      issues: issuesList,
      suggestions: List<String>.from(data['suggestions'] ?? []),
      explanation: data['explanation'] ?? '',
      newVocabulary: List<String>.from(data['newVocabulary'] ?? []),
      fixedCode: data['fixedCode'] ?? '',
      changedLines: List<int>.from(
        (data['changedLines'] as List<dynamic>?)?.map(
              (e) => (e as num).toInt(),
            ) ??
            [],
      ),
      summary: data['summary'] ?? '',
      hasSyntaxErrors: data['hasSyntaxErrors'] ?? false,
      syntaxErrors: syntaxErrorsList,
    );
  }

  static IssueSeverity _parseSeverity(dynamic value) {
    switch (value?.toString()) {
      case 'critical':
        return IssueSeverity.critical;
      case 'error':
        return IssueSeverity.error;
      case 'warning':
        return IssueSeverity.warning;
      default:
        return IssueSeverity.info;
    }
  }

  static IssueType _parseIssueType(dynamic value) {
    switch (value?.toString()) {
      case 'syntax':
        return IssueType.syntax;
      case 'bug':
        return IssueType.bug;
      case 'security':
        return IssueType.security;
      case 'performance':
        return IssueType.performance;
      case 'style':
        return IssueType.style;
      case 'bestPractice':
        return IssueType.bestPractice;
      default:
        return IssueType.bug;
    }
  }

  /// Chat with an AI mentor. Returns the AI's response text.
  ///
  /// On a successful Groq API response, the prompt and response are
  /// immediately persisted to `users/{uid}/activities` via
  /// [FirestoreService.saveChatToHistory]. The UID is sourced directly
  /// from [FirebaseAuth.instance.currentUser?.uid] — the authoritative
  /// source of truth — rather than any locally-cached value.
  Future<String> chatWithMentor(String message, String context) async {
    final messages = [
      {
        'role': 'system',
        'content': '''You are Zen, a world-class Technical English Mentor embedded inside the LexiCode learning app.

Your personality:
- Encouraging, precise, and professional — like a senior engineer who mentors juniors.
- You never talk down to the user. You celebrate effort and correct mistakes gently.
- You are concise but thorough. Every response feels premium and structured.

Your core mission:
Help developers improve their English within the context of software engineering — covering vocabulary, grammar, writing, and professional communication.

Response format:
You MUST always structure your response into these three sections using this exact markdown formatting:

**💡 Answer**
[Provide a clear, direct, and friendly answer to the user's question. Use simple English but do not oversimplify technical content. Include examples where helpful.]

**✅ Grammar Check**
[ONLY include this section if the user made a grammatical or vocabulary mistake in their message. If their English was correct, write: "Your sentence was grammatically correct — well done! 🎉". Gently explain the mistake and show the corrected version. Example format: ❌ You wrote: "How I can improve..." ✅ Correct form: "How can I improve..."]

**🔧 Tech Tip**
[Pick one key technical English term from the conversation topic. Explain what it means, give a real-world code example or usage, and show how a professional developer would use it in a sentence or PR/email.]

Context hint: $context.
Always end with a single short, motivating sentence to keep the user engaged.''',
      },
      {'role': 'user', 'content': message},
    ];

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      final body = jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      });

      final httpResponse = await http.post(
        Uri.parse(_groqEndpoint),
        headers: headers,
        body: body,
      );

      if (httpResponse.statusCode == 200) {
        final data =
            jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final responseText =
            data['choices'][0]['message']['content'] as String;

        // ── Persist to Firestore immediately after a successful response ──
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null && uid.isNotEmpty) {
          // Non-blocking: the UI is not held up waiting for the Firestore write.
          _firestoreService.saveChatToHistory(
            uid: uid,
            prompt: message,
            response: responseText,
            category: 'mentorChat',
          );
        } else {
          debugPrint(
            '[AIService] saveChatToHistory skipped — no authenticated user.',
          );
        }

        return responseText;
      } else {
        debugPrint(
          'Groq API error ${httpResponse.statusCode}: ${httpResponse.body}',
        );
      }
    } catch (e) {
      debugPrint('Error in chatWithMentor: $e');
    }
    return 'Sorry, something went wrong. Please try again.';
  }
}
