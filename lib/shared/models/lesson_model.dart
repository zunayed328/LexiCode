import 'package:flutter/material.dart';

enum LessonCategory {
  techVocabulary,
  emailWriting,
  prWriting,
  meetingConversation,
  documentation,
  commitMessages,
  codeComments,
  technicalInterview,
}

enum LessonDifficulty { beginner, elementary, intermediate, upperIntermediate, advanced, proficiency }

enum QuestionType { multipleChoice, fillBlank, translation, matching, speaking, writing }

class LessonModel {
  final String id;
  final String title;
  final String description;
  final LessonCategory category;
  final LessonDifficulty difficulty;
  final IconData icon;
  final Color color;
  final int xpReward;
  final int totalQuestions;
  final int completedQuestions;
  final bool isLocked;
  final bool isCompleted;
  final List<QuestionModel> questions;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.icon,
    required this.color,
    this.xpReward = 10,
    this.totalQuestions = 5,
    this.completedQuestions = 0,
    this.isLocked = false,
    this.isCompleted = false,
    this.questions = const [],
  });

  double get progress => totalQuestions > 0 ? completedQuestions / totalQuestions : 0;

  String get difficultyLabel {
    switch (difficulty) {
      case LessonDifficulty.beginner:
        return 'A1';
      case LessonDifficulty.elementary:
        return 'A2';
      case LessonDifficulty.intermediate:
        return 'B1';
      case LessonDifficulty.upperIntermediate:
        return 'B2';
      case LessonDifficulty.advanced:
        return 'C1';
      case LessonDifficulty.proficiency:
        return 'C2';
    }
  }

  String get categoryLabel {
    switch (category) {
      case LessonCategory.techVocabulary:
        return 'Tech Vocabulary';
      case LessonCategory.emailWriting:
        return 'Email Writing';
      case LessonCategory.prWriting:
        return 'PR Description';
      case LessonCategory.meetingConversation:
        return 'Meeting Talk';
      case LessonCategory.documentation:
        return 'Documentation';
      case LessonCategory.commitMessages:
        return 'Commit Messages';
      case LessonCategory.codeComments:
        return 'Code Comments';
      case LessonCategory.technicalInterview:
        return 'Tech Interview';
    }
  }
}

class QuestionModel {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String? codeSnippet;
  final int xpReward;

  QuestionModel({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    this.explanation = '',
    this.codeSnippet,
    this.xpReward = 10,
  });
}

class LessonUnitModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<LessonModel> lessons;
  final int unitNumber;

  LessonUnitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.lessons,
    required this.unitNumber,
  });

  double get progress {
    if (lessons.isEmpty) return 0;
    final completed = lessons.where((l) => l.isCompleted).length;
    return completed / lessons.length;
  }

  bool get isCompleted => lessons.every((l) => l.isCompleted);
}
