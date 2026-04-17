import 'package:flutter/material.dart';

enum IssueSeverity { info, warning, error, critical }

enum IssueType { syntax, bug, security, performance, style, bestPractice }

// ─── Syntax Error Model ─────────────────────────────────────────

class SyntaxError {
  final int line;
  final int? column;
  final String message;
  final String code;       // problematic code line
  final String fix;        // corrected code line
  final String? description; // simple English explanation

  const SyntaxError({
    required this.line,
    this.column,
    required this.message,
    required this.code,
    required this.fix,
    this.description,
  });

  factory SyntaxError.fromJson(Map<String, dynamic> json) {
    return SyntaxError(
      line: json['line'] ?? 0,
      column: json['column'],
      message: json['message'] ?? '',
      code: json['code'] ?? '',
      fix: json['fix'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'line': line,
    'column': column,
    'message': message,
    'code': code,
    'fix': fix,
    'description': description,
  };
}

// ─── Code Review Result ─────────────────────────────────────────

class CodeReviewResult {
  final String originalCode;
  final String language;
  final int overallScore;
  final Map<String, int> ratings;
  final List<CodeIssue> issues;
  final List<String> suggestions;
  final String explanation;
  final List<String> newVocabulary;
  final String fixedCode;
  final List<int> changedLines;
  final String summary;
  final DateTime reviewDate;

  // Syntax error fields
  final bool hasSyntaxErrors;
  final List<SyntaxError> syntaxErrors;

  CodeReviewResult({
    required this.originalCode,
    required this.language,
    required this.overallScore,
    this.ratings = const {},
    this.issues = const [],
    this.suggestions = const [],
    this.explanation = '',
    this.newVocabulary = const [],
    this.fixedCode = '',
    this.changedLines = const [],
    this.summary = '',
    this.hasSyntaxErrors = false,
    this.syntaxErrors = const [],
    DateTime? reviewDate,
  }) : reviewDate = reviewDate ?? DateTime.now();

  int get criticalCount =>
      issues.where((i) => i.severity == IssueSeverity.critical).length;
  int get errorCount =>
      issues.where((i) => i.severity == IssueSeverity.error).length;
  int get warningCount =>
      issues.where((i) => i.severity == IssueSeverity.warning).length;
  int get infoCount =>
      issues.where((i) => i.severity == IssueSeverity.info).length;

  List<CodeIssue> get syntaxIssues =>
      issues.where((i) => i.type == IssueType.syntax).toList();
  List<CodeIssue> get criticalIssues =>
      issues.where((i) => i.severity == IssueSeverity.critical && i.type != IssueType.syntax).toList();
  List<CodeIssue> get highIssues =>
      issues.where((i) => i.severity == IssueSeverity.error).toList();
  List<CodeIssue> get mediumIssues =>
      issues.where((i) => i.severity == IssueSeverity.warning).toList();
  List<CodeIssue> get lowIssues =>
      issues.where((i) => i.severity == IssueSeverity.info).toList();

  String get scoreGrade {
    if (overallScore >= 90) return 'A+';
    if (overallScore >= 80) return 'A';
    if (overallScore >= 70) return 'B';
    if (overallScore >= 60) return 'C';
    if (overallScore >= 50) return 'D';
    return 'F';
  }

  String get scoreLabel {
    if (hasSyntaxErrors) return 'Won\'t Run';
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Good';
    if (overallScore >= 70) return 'Fair';
    if (overallScore >= 60) return 'Needs Work';
    return 'Poor';
  }

  Color get scoreColor {
    if (hasSyntaxErrors) return const Color(0xFFFF4757);
    if (overallScore >= 80) return const Color(0xFF00D68F);
    if (overallScore >= 60) return const Color(0xFFFFB800);
    return const Color(0xFFFF4757);
  }

  Map<String, dynamic> toJson() => {
    'originalCode': originalCode,
    'language': language,
    'overallScore': overallScore,
    'ratings': ratings,
    'issues': issues.map((i) => i.toJson()).toList(),
    'suggestions': suggestions,
    'explanation': explanation,
    'newVocabulary': newVocabulary,
    'fixedCode': fixedCode,
    'changedLines': changedLines,
    'summary': summary,
    'hasSyntaxErrors': hasSyntaxErrors,
    'syntaxErrors': syntaxErrors.map((e) => e.toJson()).toList(),
    'reviewDate': reviewDate.toIso8601String(),
  };
}

// ─── Code Issue ─────────────────────────────────────────────────

class CodeIssue {
  final String title;
  final String description;
  final String simpleExplanation;
  final IssueSeverity severity;
  final IssueType type;
  final int? lineNumber;
  final int? column;
  final String? suggestion;
  final String? codeExample;
  final String? explanation;
  final String? exampleFix;

  CodeIssue({
    required this.title,
    required this.description,
    required this.simpleExplanation,
    required this.severity,
    this.type = IssueType.bug,
    this.lineNumber,
    this.column,
    this.suggestion,
    this.codeExample,
    this.explanation,
    this.exampleFix,
  });

  String get severityLabel {
    switch (severity) {
      case IssueSeverity.info:
        return 'Low';
      case IssueSeverity.warning:
        return 'Medium';
      case IssueSeverity.error:
        return 'High';
      case IssueSeverity.critical:
        return 'Critical';
    }
  }

  Color get severityColor {
    switch (severity) {
      case IssueSeverity.critical:
        return const Color(0xFFFF4757);
      case IssueSeverity.error:
        return const Color(0xFFFF6B47);
      case IssueSeverity.warning:
        return const Color(0xFFFFB800);
      case IssueSeverity.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case IssueSeverity.critical:
        return Icons.error_rounded;
      case IssueSeverity.error:
        return Icons.warning_amber_rounded;
      case IssueSeverity.warning:
        return Icons.info_rounded;
      case IssueSeverity.info:
        return Icons.lightbulb_rounded;
    }
  }

  String get typeLabel {
    switch (type) {
      case IssueType.syntax:
        return 'Syntax';
      case IssueType.bug:
        return 'Bug';
      case IssueType.security:
        return 'Security';
      case IssueType.performance:
        return 'Performance';
      case IssueType.style:
        return 'Style';
      case IssueType.bestPractice:
        return 'Best Practice';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case IssueType.syntax:
        return Icons.code_off_rounded;
      case IssueType.bug:
        return Icons.bug_report_rounded;
      case IssueType.security:
        return Icons.security_rounded;
      case IssueType.performance:
        return Icons.speed_rounded;
      case IssueType.style:
        return Icons.brush_rounded;
      case IssueType.bestPractice:
        return Icons.check_circle_rounded;
    }
  }

  Color get typeColor {
    switch (type) {
      case IssueType.syntax:
        return const Color(0xFFFF4757);
      case IssueType.bug:
        return const Color(0xFFFF4757);
      case IssueType.security:
        return const Color(0xFFFF6584);
      case IssueType.performance:
        return const Color(0xFFFFB800);
      case IssueType.style:
        return const Color(0xFF6C63FF);
      case IssueType.bestPractice:
        return const Color(0xFF00D68F);
    }
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'simpleExplanation': simpleExplanation,
    'severity': severity.name,
    'type': type.name,
    'lineNumber': lineNumber,
    'column': column,
    'suggestion': suggestion,
    'codeExample': codeExample,
    'explanation': explanation,
    'exampleFix': exampleFix,
  };
}
