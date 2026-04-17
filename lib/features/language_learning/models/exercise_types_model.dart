import 'user_progress_model.dart';
import 'exercise_model.dart';

// ─── Pronunciation Exercise ───────────────────────────────────────

class PronunciationExercise {
  final String word;
  final String phonetic; // IPA transcription
  final String? audioHint; // TTS-friendly pronunciation guide
  final String? definition;
  final String? exampleSentence;
  final ExerciseDifficulty difficulty;

  const PronunciationExercise({
    required this.word,
    required this.phonetic,
    this.audioHint,
    this.definition,
    this.exampleSentence,
    this.difficulty = ExerciseDifficulty.medium,
  });

  factory PronunciationExercise.fromJson(Map<String, dynamic> json) =>
      PronunciationExercise(
        word: json['word'] ?? '',
        phonetic: json['phonetic'] ?? '',
        audioHint: json['audioHint'],
        definition: json['definition'],
        exampleSentence: json['exampleSentence'],
        difficulty: ExerciseDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => ExerciseDifficulty.medium,
        ),
      );

  Map<String, dynamic> toJson() => {
    'word': word,
    'phonetic': phonetic,
    'audioHint': audioHint,
    'definition': definition,
    'exampleSentence': exampleSentence,
    'difficulty': difficulty.name,
  };
}

// ─── Spelling Exercise ────────────────────────────────────────────

enum SpellingCategory {
  common,
  homophones,
  silentLetters,
  doubleLetters,
  prefixes,
  suffixes,
  wordFamilies,
}

class SpellingExercise {
  final String word;
  final String definition;
  final String exampleSentence;
  final String? commonMisspelling;
  final String? pronunciationGuide;
  final SpellingCategory category;
  final ExerciseDifficulty difficulty;

  const SpellingExercise({
    required this.word,
    required this.definition,
    required this.exampleSentence,
    this.commonMisspelling,
    this.pronunciationGuide,
    this.category = SpellingCategory.common,
    this.difficulty = ExerciseDifficulty.medium,
  });

  factory SpellingExercise.fromJson(Map<String, dynamic> json) =>
      SpellingExercise(
        word: json['word'] ?? '',
        definition: json['definition'] ?? '',
        exampleSentence: json['exampleSentence'] ?? '',
        commonMisspelling: json['commonMisspelling'],
        pronunciationGuide: json['pronunciationGuide'],
        category: SpellingCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => SpellingCategory.common,
        ),
        difficulty: ExerciseDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => ExerciseDifficulty.medium,
        ),
      );

  Map<String, dynamic> toJson() => {
    'word': word,
    'definition': definition,
    'exampleSentence': exampleSentence,
    'commonMisspelling': commonMisspelling,
    'pronunciationGuide': pronunciationGuide,
    'category': category.name,
    'difficulty': difficulty.name,
  };
}

// ─── Reading Passage ──────────────────────────────────────────────

enum ReadingGenre {
  mystery,
  adventure,
  scienceFiction,
  historicalFiction,
  dailyLife,
  fantasy,
  biography,
  science,
  technology,
  culture,
  environment,
  health,
}

class VocabularyWord {
  final String word;
  final String definition;
  final String? pronunciationGuide;
  final String? exampleSentence;

  const VocabularyWord({
    required this.word,
    required this.definition,
    this.pronunciationGuide,
    this.exampleSentence,
  });

  factory VocabularyWord.fromJson(Map<String, dynamic> json) => VocabularyWord(
    word: json['word'] ?? '',
    definition: json['definition'] ?? '',
    pronunciationGuide: json['pronunciationGuide'],
    exampleSentence: json['exampleSentence'],
  );

  Map<String, dynamic> toJson() => {
    'word': word,
    'definition': definition,
    'pronunciationGuide': pronunciationGuide,
    'exampleSentence': exampleSentence,
  };
}

class DecisionPoint {
  final int positionInText;
  final String prompt;
  final List<String> choices;
  final Map<String, String>? consequenceTexts;

  const DecisionPoint({
    required this.positionInText,
    required this.prompt,
    required this.choices,
    this.consequenceTexts,
  });

  factory DecisionPoint.fromJson(Map<String, dynamic> json) => DecisionPoint(
    positionInText: json['positionInText'] ?? 0,
    prompt: json['prompt'] ?? '',
    choices: List<String>.from(json['choices'] ?? []),
    consequenceTexts: json['consequenceTexts'] != null
        ? Map<String, String>.from(json['consequenceTexts'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'positionInText': positionInText,
    'prompt': prompt,
    'choices': choices,
    'consequenceTexts': consequenceTexts,
  };
}

class ReadingPassage {
  final String id;
  final String title;
  final String? subtitle;
  final String content;
  final ReadingGenre genre;
  final int wordCount;
  final LearningLevel level;
  final List<VocabularyWord> vocabularyWords;
  final List<Exercise> comprehensionQuestions;
  final List<DecisionPoint>? decisionPoints;

  const ReadingPassage({
    required this.id,
    required this.title,
    this.subtitle,
    required this.content,
    required this.genre,
    required this.wordCount,
    required this.level,
    this.vocabularyWords = const [],
    this.comprehensionQuestions = const [],
    this.decisionPoints,
  });

  factory ReadingPassage.fromJson(Map<String, dynamic> json) => ReadingPassage(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'],
    content: json['content'] ?? '',
    genre: ReadingGenre.values.firstWhere(
      (e) => e.name == json['genre'],
      orElse: () => ReadingGenre.dailyLife,
    ),
    wordCount: json['wordCount'] ?? 0,
    level: LearningLevel.values.firstWhere(
      (e) => e.name == json['level'],
      orElse: () => LearningLevel.intermediate,
    ),
    vocabularyWords:
        (json['vocabularyWords'] as List<dynamic>?)
            ?.map((e) => VocabularyWord.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
    comprehensionQuestions:
        (json['comprehensionQuestions'] as List<dynamic>?)
            ?.map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
    decisionPoints: (json['decisionPoints'] as List<dynamic>?)
        ?.map((e) => DecisionPoint.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'content': content,
    'genre': genre.name,
    'wordCount': wordCount,
    'level': level.name,
    'vocabularyWords': vocabularyWords.map((e) => e.toJson()).toList(),
    'comprehensionQuestions': comprehensionQuestions
        .map((e) => e.toJson())
        .toList(),
    'decisionPoints': decisionPoints?.map((e) => e.toJson()).toList(),
  };
}

// ─── Writing Task ─────────────────────────────────────────────────

enum WritingTaskType {
  email,
  paragraph,
  opinion,
  description,
  narrative,
  processExplanation,
  persuasive,
  report,
  essay,
}

class WritingTask {
  final String id;
  final String prompt;
  final WritingTaskType taskType;
  final int wordCountTarget;
  final List<String> evaluationCriteria;
  final List<String> suggestedVocabulary;
  final List<String>? sentenceStarters;
  final String? sampleAnswer;
  final LearningLevel level;

  const WritingTask({
    required this.id,
    required this.prompt,
    required this.taskType,
    this.wordCountTarget = 150,
    this.evaluationCriteria = const [],
    this.suggestedVocabulary = const [],
    this.sentenceStarters,
    this.sampleAnswer,
    required this.level,
  });

  factory WritingTask.fromJson(Map<String, dynamic> json) => WritingTask(
    id: json['id'] ?? '',
    prompt: json['prompt'] ?? '',
    taskType: WritingTaskType.values.firstWhere(
      (e) => e.name == json['taskType'],
      orElse: () => WritingTaskType.paragraph,
    ),
    wordCountTarget: json['wordCountTarget'] ?? 150,
    evaluationCriteria: List<String>.from(json['evaluationCriteria'] ?? []),
    suggestedVocabulary: List<String>.from(json['suggestedVocabulary'] ?? []),
    sentenceStarters: json['sentenceStarters'] != null
        ? List<String>.from(json['sentenceStarters'])
        : null,
    sampleAnswer: json['sampleAnswer'],
    level: LearningLevel.values.firstWhere(
      (e) => e.name == json['level'],
      orElse: () => LearningLevel.intermediate,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt,
    'taskType': taskType.name,
    'wordCountTarget': wordCountTarget,
    'evaluationCriteria': evaluationCriteria,
    'suggestedVocabulary': suggestedVocabulary,
    'sentenceStarters': sentenceStarters,
    'sampleAnswer': sampleAnswer,
    'level': level.name,
  };
}

// ─── Speaking Prompt ──────────────────────────────────────────────

class SpeakingPrompt {
  final String id;
  final String prompt;
  final int preparationTimeSeconds;
  final int speakingTimeSeconds;
  final List<String> bulletPoints;
  final List<String> usefulPhrases;
  final String? sampleAnswer;

  const SpeakingPrompt({
    required this.id,
    required this.prompt,
    this.preparationTimeSeconds = 60,
    this.speakingTimeSeconds = 120,
    this.bulletPoints = const [],
    this.usefulPhrases = const [],
    this.sampleAnswer,
  });

  factory SpeakingPrompt.fromJson(Map<String, dynamic> json) => SpeakingPrompt(
    id: json['id'] ?? '',
    prompt: json['prompt'] ?? '',
    preparationTimeSeconds: json['preparationTimeSeconds'] ?? 60,
    speakingTimeSeconds: json['speakingTimeSeconds'] ?? 120,
    bulletPoints: List<String>.from(json['bulletPoints'] ?? []),
    usefulPhrases: List<String>.from(json['usefulPhrases'] ?? []),
    sampleAnswer: json['sampleAnswer'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt,
    'preparationTimeSeconds': preparationTimeSeconds,
    'speakingTimeSeconds': speakingTimeSeconds,
    'bulletPoints': bulletPoints,
    'usefulPhrases': usefulPhrases,
    'sampleAnswer': sampleAnswer,
  };
}
