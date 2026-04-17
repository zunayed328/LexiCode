import 'user_progress_model.dart';
import 'exercise_model.dart';

// ─── Lesson Topic ─────────────────────────────────────────────────

enum LessonTopic {
  // Beginner Grammar
  nouns,
  verbs,
  adjectives,
  adverbs,
  sentenceStructure,
  presentSimple,
  pastSimple,
  futureSimple,
  articles,
  pronouns,
  prepositions,

  // Intermediate Grammar
  presentPerfect,
  pastPerfect,
  conditionals,
  passiveVoice,
  modalVerbs,
  relativeClauses,
  reportedSpeech,
  gerundInfinitive,

  // Advanced
  complexSentences,
  academicWriting,
  formalRegister,
  idioms,
  phrasalVerbs,
  collocations,
}

extension LessonTopicX on LessonTopic {
  String get label {
    switch (this) {
      case LessonTopic.nouns:
        return 'Nouns';
      case LessonTopic.verbs:
        return 'Verbs';
      case LessonTopic.adjectives:
        return 'Adjectives';
      case LessonTopic.adverbs:
        return 'Adverbs';
      case LessonTopic.sentenceStructure:
        return 'Sentence Structure';
      case LessonTopic.presentSimple:
        return 'Present Simple';
      case LessonTopic.pastSimple:
        return 'Past Simple';
      case LessonTopic.futureSimple:
        return 'Future Simple';
      case LessonTopic.articles:
        return 'Articles (a, an, the)';
      case LessonTopic.pronouns:
        return 'Pronouns';
      case LessonTopic.prepositions:
        return 'Prepositions';
      case LessonTopic.presentPerfect:
        return 'Present Perfect';
      case LessonTopic.pastPerfect:
        return 'Past Perfect';
      case LessonTopic.conditionals:
        return 'Conditionals';
      case LessonTopic.passiveVoice:
        return 'Passive Voice';
      case LessonTopic.modalVerbs:
        return 'Modal Verbs';
      case LessonTopic.relativeClauses:
        return 'Relative Clauses';
      case LessonTopic.reportedSpeech:
        return 'Reported Speech';
      case LessonTopic.gerundInfinitive:
        return 'Gerund & Infinitive';
      case LessonTopic.complexSentences:
        return 'Complex Sentences';
      case LessonTopic.academicWriting:
        return 'Academic Writing';
      case LessonTopic.formalRegister:
        return 'Formal Register';
      case LessonTopic.idioms:
        return 'Idioms';
      case LessonTopic.phrasalVerbs:
        return 'Phrasal Verbs';
      case LessonTopic.collocations:
        return 'Collocations';
    }
  }

  LearningLevel get level {
    switch (this) {
      case LessonTopic.nouns:
      case LessonTopic.verbs:
      case LessonTopic.adjectives:
      case LessonTopic.adverbs:
      case LessonTopic.sentenceStructure:
      case LessonTopic.presentSimple:
      case LessonTopic.pastSimple:
      case LessonTopic.futureSimple:
      case LessonTopic.articles:
      case LessonTopic.pronouns:
      case LessonTopic.prepositions:
        return LearningLevel.beginner;
      case LessonTopic.presentPerfect:
      case LessonTopic.pastPerfect:
      case LessonTopic.conditionals:
      case LessonTopic.passiveVoice:
      case LessonTopic.modalVerbs:
      case LessonTopic.relativeClauses:
      case LessonTopic.reportedSpeech:
      case LessonTopic.gerundInfinitive:
        return LearningLevel.intermediate;
      case LessonTopic.complexSentences:
      case LessonTopic.academicWriting:
      case LessonTopic.formalRegister:
      case LessonTopic.idioms:
      case LessonTopic.phrasalVerbs:
      case LessonTopic.collocations:
        return LearningLevel.advanced;
    }
  }
}

// ─── Lesson Example ───────────────────────────────────────────────

class LessonExample {
  final String sentence;
  final String? highlightedPart;
  final String? pronunciationGuide;
  final String? translationHint;

  const LessonExample({
    required this.sentence,
    this.highlightedPart,
    this.pronunciationGuide,
    this.translationHint,
  });

  factory LessonExample.fromJson(Map<String, dynamic> json) =>
      LessonExample(
        sentence: json['sentence'] ?? '',
        highlightedPart: json['highlightedPart'],
        pronunciationGuide: json['pronunciationGuide'],
        translationHint: json['translationHint'],
      );

  Map<String, dynamic> toJson() => {
        'sentence': sentence,
        'highlightedPart': highlightedPart,
        'pronunciationGuide': pronunciationGuide,
        'translationHint': translationHint,
      };
}

// ─── Grammar Point ────────────────────────────────────────────────

class GrammarPoint {
  final String rule;
  final String ruleExplanation;
  final List<String> examples;
  final List<String> exceptions;
  final String? mnemonicTip;

  const GrammarPoint({
    required this.rule,
    required this.ruleExplanation,
    this.examples = const [],
    this.exceptions = const [],
    this.mnemonicTip,
  });

  factory GrammarPoint.fromJson(Map<String, dynamic> json) =>
      GrammarPoint(
        rule: json['rule'] ?? '',
        ruleExplanation: json['ruleExplanation'] ?? '',
        examples: List<String>.from(json['examples'] ?? []),
        exceptions: List<String>.from(json['exceptions'] ?? []),
        mnemonicTip: json['mnemonicTip'],
      );

  Map<String, dynamic> toJson() => {
        'rule': rule,
        'ruleExplanation': ruleExplanation,
        'examples': examples,
        'exceptions': exceptions,
        'mnemonicTip': mnemonicTip,
      };
}

// ─── Learning Lesson ──────────────────────────────────────────────

class LearningLesson {
  final String id;
  final String topic;
  final LearningLevel level;
  final String title;
  final String explanation; // 200–300 word beginner-friendly explanation
  final List<LessonExample> examples;
  final List<GrammarPoint> grammarPoints;
  final List<String> commonMistakes;
  final List<String> tips;
  final List<String> voiceExampleTexts; // Sentences for TTS
  final List<Exercise> exercises; // ADDED
  final int estimatedMinutes;
  final int xpReward;
  final DateTime generatedAt;

  LearningLesson({
    required this.id,
    required this.topic,
    required this.level,
    required this.title,
    required this.explanation,
    this.examples = const [],
    this.grammarPoints = const [],
    this.exercises = const [], // ADDED
    this.commonMistakes = const [],
    this.tips = const [],
    this.voiceExampleTexts = const [],
    this.estimatedMinutes = 15,
    this.xpReward = 20,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory LearningLesson.fromJson(Map<String, dynamic> json) =>
      LearningLesson(
        id: json['id'] ?? '',
        topic: json['topic'] ?? '',
        level: LearningLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => LearningLevel.beginner,
        ),
        title: json['title'] ?? '',
        explanation: json['explanation'] ?? '',
        examples: (json['examples'] as List<dynamic>?)
                ?.map((e) =>
                    LessonExample.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        grammarPoints: (json['grammarPoints'] as List<dynamic>?)
                ?.map((e) =>
                    GrammarPoint.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        exercises: (json['exercises'] as List<dynamic>?)
                ?.map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
        tips: List<String>.from(json['tips'] ?? []),
        voiceExampleTexts:
            List<String>.from(json['voiceExampleTexts'] ?? []),
        estimatedMinutes: json['estimatedMinutes'] ?? 15,
        xpReward: json['xpReward'] ?? 20,
        generatedAt: DateTime.tryParse(json['generatedAt'] ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'level': level.name,
        'title': title,
        'explanation': explanation,
        'examples': examples.map((e) => e.toJson()).toList(),
        'grammarPoints': grammarPoints.map((e) => e.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'commonMistakes': commonMistakes,
        'tips': tips,
        'voiceExampleTexts': voiceExampleTexts,
        'estimatedMinutes': estimatedMinutes,
        'xpReward': xpReward,
        'generatedAt': generatedAt.toIso8601String(),
      };
}
