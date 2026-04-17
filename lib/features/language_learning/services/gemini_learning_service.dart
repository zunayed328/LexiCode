import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_progress_model.dart';
import '../models/lesson_model.dart';
import '../models/exercise_model.dart';
import '../models/exam_result_model.dart';
import '../models/suggestion_model.dart';
import '../models/exercise_types_model.dart';

/// Central AI service for the English Learning module.
///
/// Handles all AI content generation, evaluation, and analysis
/// using the Groq API (OpenAI-compatible) with the Llama 4 Scout model.
class GeminiLearningService {
  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqWhisperEndpoint =
      'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const String _whisperModel = 'whisper-large-v3';

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // ─── Content Generation ───────────────────────────────────────

  /// Generates a beginner grammar lesson on the given topic.
  Future<LearningLesson> generateBeginnerLesson(
    String topic,
    UserProgress progress,
  ) async {
    final exclusions = _buildExclusionBlock(progress);
    final prompt = '''
Generate a beginner-level English grammar lesson on "$topic".

Requirements:
- User level: Complete beginner
- Topics already covered: ${progress.recentTopics.join(', ')}

Provide a JSON object with:
- "id": unique string ID (use format "lesson_${topic.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}")
- "topic": "$topic"
- "level": "beginner"
- "title": engaging lesson title
- "explanation": simple beginner-friendly explanation (250 words max) with everyday examples
- "examples": array of objects with "sentence", "highlightedPart", "pronunciationGuide", "translationHint" (7 examples)
- "grammarPoints": array of objects with "rule", "ruleExplanation", "examples" (array), "exceptions" (array), "mnemonicTip"
- "commonMistakes": array of 3-5 common mistakes beginners make
- "tips": array of 3-5 tips to remember the rule
- "voiceExampleTexts": array of 5 sentences for pronunciation practice
- "exercises": array of 8 practice questions, each with:
  - "id": unique string
  - "type": one of "mcq", "fillBlank", "trueFalse"
  - "question": the question text related to $topic
  - "options": array of 4 options (for mcq/trueFalse)
  - "correctAnswer": the correct answer string (must exactly match one of the options)
  - "explanation": why the answer is correct
  - "difficulty": one of "veryEasy", "easy", "medium"
  - "points": 10
  - "hint": optional hint text
- "estimatedMinutes": 15
- "xpReward": 20

$exclusions

Ensure: Different examples from previous sessions, culturally neutral content.
''';

    return _generate(prompt, (data) => LearningLesson.fromJson(data));
  }

  /// Generates an exercise session for the given type and level.
  Future<ExerciseSession> generateExerciseSession(
    SessionType sessionType,
    LearningLevel level,
    UserProgress progress, {
    String? focusTopic,
    int questionCount = 12,
  }) async {
    final exclusions = _buildExclusionBlock(progress);
    final diffLabel = level.label;
    final prompt = '''
Generate an English practice session.

Parameters:
- Session type: ${sessionType.label}
- Level: $diffLabel
- Focus topic: ${focusTopic ?? 'Mixed'}
- Question count: $questionCount

Provide a JSON object with:
- "id": unique string ID
- "sessionType": "${sessionType.name}"
- "level": "${level.name}"
- "topic": the main topic
- "warmupText": brief warm-up message (1-2 sentences)
- "exercises": array of $questionCount exercise objects, each with:
  - "id": unique string
  - "type": one of "mcq", "fillBlank", "trueFalse", "errorCorrection"
  - "question": the question text
  - "options": array of 4 options (for mcq/trueFalse)
  - "correctAnswer": the correct answer string
  - "explanation": why the answer is correct
  - "difficulty": one of "veryEasy", "easy", "medium", "hard", "challenging"
  - "points": 10
  - "hint": optional hint text

Difficulty distribution: 25% easy, 50% medium, 25% hard.

$exclusions

Generate entirely new scenarios and sentences. Avoid textbook clichés.
''';

    return _generate(prompt, (data) => ExerciseSession.fromJson(data));
  }

  /// Generates a daily practice session based on day of week.
  Future<ExerciseSession> generateDailySession(
    DateTime date,
    UserProgress progress,
  ) async {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[date.weekday - 1];
    final focusMap = {
      'Monday': 'Reading comprehension',
      'Tuesday': 'Listening practice',
      'Wednesday': 'Writing exercise',
      'Thursday': 'Speaking practice',
      'Friday': 'Grammar focus',
      'Saturday': 'Mixed skills',
      'Sunday': 'Review & assessment',
    };
    final focus = focusMap[dayName] ?? 'Mixed skills';
    final exclusions = _buildExclusionBlock(progress);

    final prompt = '''
Generate a daily English practice session.

User Profile:
- Level: ${progress.currentLevel.label}
- Day: $dayName
- Streak: ${progress.streak.currentStreak} days
- Focus for today: $focus

Provide a JSON object with:
- "id": unique string ID
- "sessionType": "dailyPractice"
- "level": "${progress.currentLevel.name}"
- "topic": "$focus"
- "warmupText": motivational warm-up (2-3 sentences, mention streak)
- "cooldownReflection": reflection question about today's practice
- "exercises": array of 8-10 exercises, each with:
  - "id", "type", "question", "options", "correctAnswer", "explanation", "difficulty", "points"

$exclusions
''';

    return _generate(prompt, (data) => ExerciseSession.fromJson(data));
  }

  /// Generates an IELTS simulation section practice test.
  Future<ExerciseSession> generateIELTSSection(
    IELTSSectionType sectionType,
    UserProgress progress,
  ) async {
    // BYPASS API FOR WRITING TASK
    if (sectionType == IELTSSectionType.writing) {
      return ExerciseSession(
        id: 'mock_writing_001',
        sessionType: SessionType.ieltsExam,
        topic: 'IELTS Writing Practice',
        level: LearningLevel.advanced,
        warmupText: 'IELTS Writing Section. You have limited time.',
        cooldownReflection: 'Reflect on your writing today.',
        exercises: [
          const Exercise(
            id: 'task1',
            type: ExerciseType.writingPrompt,
            question: 'The chart below shows the percentage of people who ate five portions of fruit and vegetables per day in the UK from 2001 to 2008. Summarise the information by selecting and reporting the main features, and make comparisons where relevant.',
            context: 'The chart below shows the percentage of people who ate five portions of fruit and vegetables per day in the UK from 2001 to 2008. Summarise the information by selecting and reporting the main features, and make comparisons where relevant.',
            imageUrl: 'assets/images/task1_chart.png',
            correctAnswer: '',
            difficulty: ExerciseDifficulty.challenging,
          ),
          const Exercise(
            id: 'task2',
            type: ExerciseType.writingPrompt,
            question: 'Some people think that university education should be free for everyone. Others think that students should pay for their higher education. Discuss both these views and give your own opinion.',
            context: 'Some people think that university education should be free for everyone. Others think that students should pay for their higher education. Discuss both these views and give your own opinion.',
            correctAnswer: '',
            difficulty: ExerciseDifficulty.challenging,
          ),
        ],
      );
    }

    final exclusions = _buildExclusionBlock(progress);
    
    final prompt = '''
Generate an IELTS simulation section practice test for ${sectionType.name}.

Requirements:
- Target Level: IELTS Academic
- Section: ${sectionType.name}

Provide a JSON object with:
- "id": unique string ID
- "sessionType": "ieltsExam"
- "level": "advanced"
- "topic": "IELTS ${sectionType.name} Practice"
- "warmupText": "IELTS ${sectionType.name} Section. You have limited time."
- "exercises": array of 10-15 exercise objects representing IELTS questions, suitable for the section type.
  - "id", "type", "question", "options" (array), "correctAnswer", "explanation", "difficulty", "points"
  - For Reading/Writing: include a "context" field with the full reading passage or writing task prompt.
  - For Listening: include an "audioText" field with the transcript of the audio.
  - For Writing Task 1 exercises that describe a graph, chart, table, or diagram: include an "imageUrl" field with a sample chart image URL. Use "https://via.placeholder.com/400x250.png?text=Sample+Bar+Chart" as a placeholder. The first exercise should be a Task 1 with a graph description and include this imageUrl.

$exclusions
''';

    return _generate(prompt, (data) => ExerciseSession.fromJson(data));
  }

  // ─── Specialized Content Generation ─────────────────────────────

  /// Generates a reading passage with comprehension questions.
  Future<ReadingPassage> generateReadingPassage(
    LearningLevel level,
    UserProgress progress, {
    String? focusTopic,
  }) async {
    final exclusions = _buildExclusionBlock(progress);
    final diffLabel = level.label;
    final prompt = '''
Generate an English reading passage.

Parameters:
- Level: $diffLabel
- Focus topic: ${focusTopic ?? 'General Knowledge'}

Provide a JSON object conforming to ReadingPassage structure:
- "id": unique string ID
- "title": engaging title
- "subtitle": optional subtitle
- "content": the actual reading passage (300-400 words)
- "genre": one of "mystery", "adventure", "scienceFiction", "historicalFiction", "dailyLife", "fantasy", "biography", "science", "technology", "culture", "environment", "health"
- "wordCount": approx reading length
- "level": "${level.name}"
- "vocabularyWords": array of 5 vocabulary words from text (each with "word", "definition", "pronunciationGuide", "exampleSentence")
- "comprehensionQuestions": array of 5 questions (each with "id", "type": "mcq", "question", "options" (4 items), "correctAnswer", "explanation", "difficulty": "medium", "points": 10)

$exclusions
''';

    return _generate(prompt, (data) => ReadingPassage.fromJson(data));
  }

  /// Generates a writing task.
  Future<WritingTask> generateWritingTask(
    LearningLevel level,
    UserProgress progress, {
    String? focusTopic,
  }) async {
    final exclusions = _buildExclusionBlock(progress);
    final diffLabel = level.label;
    final prompt = '''
Generate an English writing task.

Parameters:
- Level: $diffLabel
- Focus topic: ${focusTopic ?? 'General Writing'}

Provide a JSON object conforming to WritingTask structure:
- "id": unique string
- "prompt": the writing prompt instruction
- "taskType": one of "email", "paragraph", "opinion", "description", "narrative", "processExplanation", "persuasive", "report", "essay"
- "wordCountTarget": integer (around 150-250 depending on level)
- "evaluationCriteria": array of 4 strings (e.g., "Grammar", "Vocabulary", "Coherence")
- "suggestedVocabulary": array of 6-8 useful words
- "sentenceStarters": array of 3-4 sentence starters
- "sampleAnswer": a model answer (optional, can be brief)
- "level": "${level.name}"

$exclusions
''';

    return _generate(prompt, (data) => WritingTask.fromJson(data));
  }

  /// Generates speaking prompts.
  Future<List<SpeakingPrompt>> generateSpeakingPrompts(
    LearningLevel level,
    UserProgress progress, {
    int count = 3,
  }) async {
    final exclusions = _buildExclusionBlock(progress);
    final diffLabel = level.label;
    final prompt = '''
Generate speaking prompts for English practice.

Parameters:
- Level: $diffLabel
- Count: $count

Provide a JSON object with a single field "prompts" which is an array of $count objects, each with:
- "id": unique string
- "prompt": the speaking topic or question
- "preparationTimeSeconds": integer (e.g., 60)
- "speakingTimeSeconds": integer (e.g., 120)
- "bulletPoints": array of 3-4 bullet points to cover
- "usefulPhrases": array of 4-6 helpful phrases
- "sampleAnswer": a model transcript (optional)

$exclusions
''';

    return _generate(prompt, (data) {
      final list = data['prompts'] as List<dynamic>;
      return list.map((e) => SpeakingPrompt.fromJson(Map<String, dynamic>.from(e))).toList();
    });
  }

  // ─── Evaluation Methods ───────────────────────────────────────

  /// Evaluates a writing submission against IELTS criteria.
  Future<WritingEvaluation> evaluateWriting(
    String userText,
    String taskPrompt,
  ) async {
    final prompt = '''
Evaluate this English writing response using IELTS-style criteria.

Task: $taskPrompt
User's text: $userText
Word count: ${userText.split(' ').length}

Provide a JSON object with:
- "taskAchievement": score 0-9 (0.5 increments)
- "coherenceCohesion": score 0-9
- "lexicalResource": score 0-9
- "grammaticalRange": score 0-9
- "overallBand": average of above scores
- "strengths": array of 3-5 specific strengths
- "weaknesses": array of 3-5 areas for improvement
- "grammarErrors": array of objects with "original", "correction", "explanation"
- "correctedVersion": improved version of user's text
- "suggestions": array of improvement tips
- "detailedFeedback": paragraph of constructive feedback

Tone: Supportive and educational.
''';

    return _generate(prompt, (data) => WritingEvaluation.fromJson(data));
  }

  /// Evaluates a speech transcript.
  Future<SpeakingEvaluation> evaluateSpeech(
    String transcript,
    String expectedTopic,
  ) async {
    final prompt = '''
Evaluate this spoken English response (transcribed from speech).

Topic: $expectedTopic
Transcription: $transcript

Provide a JSON object with:
- "fluencyCoherence": score 0-9
- "lexicalResource": score 0-9
- "grammaticalRange": score 0-9
- "pronunciation": score 0-9
- "overallBand": average
- "transcription": cleaned up version of transcript
- "feedback": array of specific feedback points
- "pronunciationIssues": array of pronunciation concerns
- "sampleAnswer": example Band 7-8 response

Note: Be realistic about speech-to-text limitations.
''';

    return _generate(prompt, (data) => SpeakingEvaluation.fromJson(data));
  }

  /// Validates a user's answer with AI (for open-ended / spelling-flexible answers).
  Future<ExerciseResult> validateAnswer(
    String userAnswer,
    Exercise exercise,
  ) async {
    final prompt = '''
Validate this answer for an English exercise.

Question: ${exercise.question}
Expected answer: ${exercise.correctAnswer}
User's answer: $userAnswer

Check if acceptable considering spelling variations, synonyms, and capitalization.

Provide JSON:
- "exerciseId": "${exercise.id}"
- "userAnswer": "$userAnswer"
- "isCorrect": boolean
- "scoreEarned": ${exercise.points} if correct, 0 if wrong
- "feedback": brief explanation
''';

    return _generate(prompt, (data) => ExerciseResult.fromJson(data));
  }

  // ─── Analysis & Suggestions ───────────────────────────────────

  /// Analyzes user performance and identifies weaknesses.
  Future<WeaknessAnalysis> analyzePerformance(
    UserProgress progress,
  ) async {
    final skillData = progress.skillScores.map(
      (k, v) => MapEntry(k, '${v.currentScore}/100'),
    );
    final prompt = '''
Analyze English learning performance and identify weaknesses.

User Profile:
- Level: ${progress.currentLevel.label}
- CEFR: ${progress.cefrLevel.shortLabel}
- Total XP: ${progress.totalXp}
- Lessons completed: ${progress.totalLessonsCompleted}
- Skill scores: $skillData

Provide JSON:
- "criticalWeaknesses": array (max 5) of objects with "skill", "area", "description", "evidence", "impactOnScore" (double), "urgency" ("high"/"medium"/"low")
- "moderateWeaknesses": array (max 5)
- "hiddenPatterns": array of pattern strings
- "strengthsToLeverage": array of strength strings
- "skillBalance": object mapping skill names to scores (0-100)
''';

    return _generate(prompt, (data) => WeaknessAnalysis.fromJson(data));
  }

  /// Generates a personalized learning roadmap.
  Future<LearningRoadmap> generateRoadmap(
    UserProgress progress,
    String goal,
    String timeline,
  ) async {
    final prompt = '''
Create a personalized English learning roadmap.

User:
- Level: ${progress.currentLevel.label}
- Goal: $goal
- Timeline: $timeline
- Available time: 1 hour/day

Provide JSON:
- "id": unique string
- "goal": "$goal"
- "overallStrategy": strategy description
- "phases": array of phase objects with "name", "durationWeeks", "objectives" (array), "focusSkills" (array), "dailyActivities" (map day→activity), "expectedImprovement"
- "weeklySchedule": map of day→activities
- "milestones": array of milestone strings
- "successMetrics": array of metric strings
''';

    return _generate(prompt, (data) => LearningRoadmap.fromJson(data));
  }

  /// Generates daily practice suggestions.
  Future<DailySuggestion> generateDailySuggestion(
    UserProgress progress,
  ) async {
    final prompt = '''
Generate a daily personalized practice suggestion.

User:
- Level: ${progress.currentLevel.label}
- Streak: ${progress.streak.currentStreak} days
- Last practice topics: ${progress.recentTopics.take(5).join(', ')}

Provide JSON:
- "mainActivity": object with "type", "topic", "durationMinutes", "reason", "difficulty"
- "secondaryActivity": same structure (or null)
- "bonusActivity": same structure (or null)
- "motivationalMessage": encouraging message (50-80 words, mention streak)
- "expectedOutcome": what completing today's practice will achieve
''';

    return _generate(prompt, (data) => DailySuggestion.fromJson(data));
  }

  /// Generates an AI motivational message.
  Future<String> generateMotivation(UserProgress progress) async {
    final prompt =
        'Generate a short motivational message (2-3 sentences) for an English learner '
        'on a ${progress.streak.currentStreak}-day streak at ${progress.currentLevel.label} level. '
        'Be encouraging and mention their progress.';

    try {
      final response = await _callGroqText(prompt);
      return response ?? 'Keep up the great work! 🎉';
    } catch (e) {
      return 'Every day of practice brings you closer to fluency! 🌟';
    }
  }

  // ─── Audio Transcription (Whisper) ────────────────────────────

  /// Transcribes audio bytes using Groq's Whisper API.
  ///
  /// [audioBytes] is the raw audio data (e.g., WAV/WebM from recording).
  /// [fileName] should include the extension (e.g., 'recording.webm').
  /// Returns the transcribed text.
  Future<String> transcribeAudioBytes(
    Uint8List audioBytes, {
    String fileName = 'recording.webm',
    String language = 'en',
  }) async {
    if (audioBytes.isEmpty) {
      throw Exception('Audio data is empty. Please record again.');
    }

    try {
      final uri = Uri.parse(_groqWhisperEndpoint);
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $_apiKey';

      // Determine MIME type from file extension
      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'wav' => 'audio/wav',
        'mp3' => 'audio/mpeg',
        'ogg' => 'audio/ogg',
        'webm' => 'audio/webm',
        'mp4' || 'm4a' => 'audio/mp4',
        'flac' => 'audio/flac',
        _ => 'audio/webm',
      };

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: fileName,
        contentType: _parseMediaType(mimeType),
      ));
      request.fields['model'] = _whisperModel;
      request.fields['language'] = language;
      request.fields['response_format'] = 'json';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (data['text'] as String?)?.trim() ?? '';
        if (text.isEmpty) {
          throw Exception('Whisper returned empty transcription. Please speak more clearly.');
        }
        return text;
      } else {
        final errorBody = response.body;
        throw Exception(
          'Whisper API error (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Audio transcription failed: $e');
    }
  }

  /// Simple MIME type parser helper.
  MediaType _parseMediaType(String mimeType) {
    final parts = mimeType.split('/');
    return MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream');
  }

  // ─── Helpers ──────────────────────────────────────────────────

  /// Calls Groq with JSON response mode and parses the result.
  Future<T> _generate<T>(
    String prompt,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final data = await _callGroqJson(prompt);
      if (data != null) {
        return parser(data);
      }
      throw Exception('Empty AI response');
    } catch (e) {
      rethrow;
    }
  }

  /// Sends a JSON-mode request to Groq and returns parsed JSON.
  Future<Map<String, dynamic>?> _callGroqJson(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an expert English language teacher and educational content creator. '
              'You always respond with valid JSON only.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.4,
      'max_tokens': 4096,
    });

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content =
            data['choices'][0]['message']['content'] as String;
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        print('Groq API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error calling Groq API: $e');
    }
    return null;
  }

  /// Sends a plain text request to Groq and returns the response string.
  Future<String?> _callGroqText(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an encouraging English language learning mentor.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.7,
      'max_tokens': 512,
    });

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('Groq API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error calling Groq text API: $e');
    }
    return null;
  }

  String _buildExclusionBlock(UserProgress progress) {
    final topics = progress.recentTopics;
    final ids = progress.recentContentIds;

    if (topics.isEmpty && ids.isEmpty) return '';

    return '''
UNIQUENESS REQUIREMENTS:
- Do NOT reuse these topics: ${topics.take(20).join(', ')}
- Do NOT reuse content IDs: ${ids.take(30).join(', ')}
- Generate entirely original content
- Use fresh perspectives and new examples
- Avoid clichéd examples
''';
  }
}
