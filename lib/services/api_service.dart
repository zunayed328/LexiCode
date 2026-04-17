import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../shared/models/code_review_model.dart';
import 'models/pronunciation_result.dart';

/// API Service that calls Firebase Cloud Functions.
///
/// All methods are static for easy access. Each method wraps a
/// corresponding Cloud Function endpoint and handles errors.
class ApiService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // ═══════════════════════════════════════════════════════════════
  //  CODE REVIEW
  // ═══════════════════════════════════════════════════════════════

  /// Analyzes code by calling the backend Cloud Function.
  /// Returns a [CodeReviewResult] parsed from the response.
  static Future<CodeReviewResult> analyzeCode({
    required String code,
    required String language,
    String userLevel = 'B1',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'codeReview',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 300)),
      );

      final result = await callable.call({
        'code': code,
        'language': language,
        'userLevel': userLevel,
      });

      final data = Map<String, dynamic>.from(result.data);
      return _parseCodeReviewResult(data);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception('Daily review limit reached. Try again tomorrow.');
      }
      if (e.code == 'unauthenticated') {
        throw Exception('Please log in to use code review.');
      }
      throw Exception('Code review failed: ${e.message}');
    } catch (e) {
      throw Exception('Code review error: $e');
    }
  }

  /// Parses the Cloud Function response into a [CodeReviewResult].
  static CodeReviewResult _parseCodeReviewResult(Map<String, dynamic> data) {
    // Parse issues
    final issuesList = (data['issues'] as List<dynamic>?)?.map((i) {
      final issueMap = Map<String, dynamic>.from(i);
      return CodeIssue(
        title: issueMap['title'] ?? '',
        description: issueMap['description'] ?? '',
        simpleExplanation: issueMap['simpleExplanation'] ?? '',
        severity: _parseSeverity(issueMap['severity']),
        type: _parseIssueType(issueMap['type']),
        lineNumber: issueMap['lineNumber'],
        column: issueMap['column'],
        suggestion: issueMap['suggestion'],
        codeExample: issueMap['codeExample'],
        explanation: issueMap['explanation'],
        exampleFix: issueMap['exampleFix'],
      );
    }).toList() ?? [];

    // Parse syntax errors
    final syntaxErrorsList = (data['syntaxErrors'] as List<dynamic>?)?.map((e) {
      final errorMap = Map<String, dynamic>.from(e);
      return SyntaxError(
        line: errorMap['line'] ?? 0,
        column: errorMap['column'],
        message: errorMap['message'] ?? '',
        code: errorMap['code'] ?? '',
        fix: errorMap['fix'] ?? '',
        description: errorMap['description'],
      );
    }).toList() ?? [];

    // Parse ratings
    final ratingsRaw = data['ratings'];
    final ratings = <String, int>{};
    if (ratingsRaw is Map) {
      for (final entry in ratingsRaw.entries) {
        ratings[entry.key.toString()] = (entry.value is num) ? (entry.value as num).toInt() : 0;
      }
    }

    return CodeReviewResult(
      originalCode: data['originalCode'] ?? '',
      language: data['language'] ?? '',
      overallScore: (data['overallScore'] as num?)?.toInt() ?? 0,
      ratings: ratings,
      issues: issuesList,
      suggestions: List<String>.from(data['suggestions'] ?? []),
      explanation: data['explanation'] ?? '',
      newVocabulary: List<String>.from(data['newVocabulary'] ?? []),
      fixedCode: data['fixedCode'] ?? '',
      changedLines: List<int>.from(
        (data['changedLines'] as List<dynamic>?)?.map((e) => (e as num).toInt()) ?? [],
      ),
      summary: data['summary'] ?? '',
      hasSyntaxErrors: data['hasSyntaxErrors'] ?? false,
      syntaxErrors: syntaxErrorsList,
    );
  }

  static IssueSeverity _parseSeverity(dynamic value) {
    switch (value?.toString()) {
      case 'critical': return IssueSeverity.critical;
      case 'error': return IssueSeverity.error;
      case 'warning': return IssueSeverity.warning;
      default: return IssueSeverity.info;
    }
  }

  static IssueType _parseIssueType(dynamic value) {
    switch (value?.toString()) {
      case 'syntax': return IssueType.syntax;
      case 'bug': return IssueType.bug;
      case 'security': return IssueType.security;
      case 'performance': return IssueType.performance;
      case 'style': return IssueType.style;
      case 'bestPractice': return IssueType.bestPractice;
      default: return IssueType.bug;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ENGLISH LESSON
  // ═══════════════════════════════════════════════════════════════

  /// Generates an English lesson via the backend.
  static Future<Map<String, dynamic>> generateLesson({
    required String unitId,
    required String lessonId,
    String userLevel = 'A2',
    String lessonType = 'general',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'lessonGenerator',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );

      final result = await callable.call({
        'unitId': unitId,
        'lessonId': lessonId,
        'userLevel': userLevel,
        'lessonType': lessonType,
      });

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception('Daily lesson limit reached. Try again tomorrow.');
      }
      throw Exception('Lesson generation failed: ${e.message}');
    } catch (e) {
      throw Exception('Lesson error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  PRONUNCIATION ANALYSIS
  // ═══════════════════════════════════════════════════════════════

  /// Analyzes pronunciation by sending audio to the backend.
  static Future<PronunciationResult> analyzePronunciation({
    required String audioPath,
    required String targetPhrase,
    String language = 'en-US',
  }) async {
    try {
      // Read audio file and convert to base64
      final bytes = await File(audioPath).readAsBytes();
      final base64Audio = base64Encode(bytes);

      final callable = _functions.httpsCallable(
        'pronunciationAnalyzer',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call({
        'audioData': base64Audio,
        'targetPhrase': targetPhrase,
        'language': language,
      });

      return PronunciationResult.fromJson(Map<String, dynamic>.from(result.data));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception('Daily pronunciation limit reached. Try again tomorrow.');
      }
      throw Exception('Pronunciation analysis failed: ${e.message}');
    } catch (e) {
      throw Exception('Pronunciation error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  AI CHAT
  // ═══════════════════════════════════════════════════════════════

  /// Sends a chat message to the AI backend.
  static Future<String> chat({
    required String message,
    String context = 'general',
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'aiChat',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call({
        'message': message,
        'context': context,
        'conversationHistory': conversationHistory,
      });

      final data = Map<String, dynamic>.from(result.data);
      return data['response'] as String? ?? 'No response received.';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception('Daily chat limit reached. Try again tomorrow.');
      }
      throw Exception('Chat failed: ${e.message}');
    } catch (e) {
      throw Exception('Chat error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  USER PROGRESS
  // ═══════════════════════════════════════════════════════════════

  /// Saves user progress to the backend.
  static Future<void> saveProgress({
    String? lessonId,
    Map<String, dynamic>? result,
    bool codeReviewCompleted = false,
    bool updateStreak = false,
    List<String>? badges,
    String? proficiencyLevel,
  }) async {
    try {
      final callable = _functions.httpsCallable('saveProgress');

      await callable.call({
        'lessonId': ?lessonId,
        'result': ?result,
        'codeReviewCompleted': codeReviewCompleted,
        'updateStreak': updateStreak,
        'badges': ?badges,
        'proficiencyLevel': ?proficiencyLevel,
      });
    } catch (e) {
      // Progress save failure is non-fatal — Firebase may not be fully configured
      debugPrint('Progress save skipped (non-fatal): $e');
    }
  }
}
