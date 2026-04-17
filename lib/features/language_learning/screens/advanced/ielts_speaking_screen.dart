import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/exercise_model.dart';
import '../../models/exam_result_model.dart';
import '../../services/content_generation_service.dart';
import '../../services/gemini_learning_service.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/timer_widget.dart';
import 'exam_result_screen.dart';

class IeltsSpeakingScreen extends StatefulWidget {
  final bool isFullExam;
  
  const IeltsSpeakingScreen({super.key, this.isFullExam = false});

  @override
  State<IeltsSpeakingScreen> createState() => _IeltsSpeakingScreenState();
}

class _IeltsSpeakingScreenState extends State<IeltsSpeakingScreen>
    with SingleTickerProviderStateMixin {
  final ContentGenerationService _contentService = ContentGenerationService();
  final GeminiLearningService _gemini = GeminiLearningService();
  final TextEditingController _transcriptController = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isLoading = true;
  bool _isEvaluating = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _error;
  String? _recordingError;
  ExerciseSession? _session;
  int _currentQuestionIndex = 0;
  
  final List<String> _transcripts = [];
  final Color _accentColor = const Color(0xFFEF4444);

  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadSection();
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }
  
  Future<void> _loadSection() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final session = await _contentService.getIELTSSection(
        IELTSSectionType.speaking,
        progress,
      );
      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _nextQuestion() async {
    if (_transcriptController.text.trim().isNotEmpty) {
      _transcripts.add(_transcriptController.text.trim());
    } else {
      _transcripts.add("No response provided.");
    }
    
    _transcriptController.clear();
    setState(() => _recordingError = null);
    
    if (_currentQuestionIndex < _session!.exercises.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      await _submitSpeaking();
    }
  }

  Future<void> _submitSpeaking() async {
    setState(() => _isEvaluating = true);
    
    try {
      final String fullTranscript = _transcripts.join("\n\n");
      final String fullPrompt = _session!.exercises.map((e) => e.question).join("\n\n");
      
      final evaluation = await _gemini.evaluateSpeech(fullTranscript, fullPrompt);
      if (mounted) {
        setState(() => _isEvaluating = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ExamResultScreen(speakingResult: evaluation)),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Evaluation failed: $e');
        setState(() => _isEvaluating = false);
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isTranscribing) return;

    if (_isRecording) {
      await _stopRecordingAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    setState(() => _recordingError = null);

    try {
      // Check microphone permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showError('Microphone permission denied. Please allow microphone access in your browser/device settings.');
        return;
      }

      // Configure recording format: WebM for web, WAV for mobile
      final config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Start recording — on web the path is ignored and a blob URL is returned
      await _recorder.start(config, path: '');

      if (mounted) {
        setState(() => _isRecording = true);
        _pulseController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to start recording: $e');
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    try {
      _pulseController.stop();
      _pulseController.reset();

      // Stop recording and get the path (blob URL on web, file path on mobile)
      final path = await _recorder.stop();
      
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isTranscribing = true;
        });
      }

      if (path == null || path.isEmpty) {
        throw Exception('Recording produced no audio data.');
      }

      // Fetch audio bytes — works for both blob URLs (web) and file URIs
      final audioBytes = await _fetchAudioBytes(path);

      if (audioBytes.isEmpty) {
        throw Exception('Recording is empty. Please try speaking again.');
      }

      // Determine file extension based on platform
      final fileName = kIsWeb ? 'recording.webm' : 'recording.wav';

      // Transcribe via Groq Whisper
      final transcription = await _gemini.transcribeAudioBytes(
        audioBytes,
        fileName: fileName,
      );

      if (mounted) {
        setState(() {
          _transcriptController.text = transcription;
          _isTranscribing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Transcription failed: $e');
        setState(() {
          _isRecording = false;
          _isTranscribing = false;
        });
      }
    }
  }

  /// Fetches audio bytes from the recorded path.
  /// On web this is a blob URL; on mobile/desktop it's a file:// URI or path.
  /// Both can be fetched via HTTP GET.
  Future<Uint8List> _fetchAudioBytes(String pathOrUrl) async {
    try {
      final uri = pathOrUrl.startsWith('http') || pathOrUrl.startsWith('blob')
          ? Uri.parse(pathOrUrl)
          : Uri.parse('file:///$pathOrUrl');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Failed to read audio (HTTP ${response.statusCode})');
    } catch (e) {
      // If HTTP fetch fails on mobile, the path might be a regular file path.
      // We'll re-throw since dart:io is not available on web.
      throw Exception('Could not read recorded audio: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _recordingError = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Practice?'),
        content: const Text('Your session progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(_accentColor),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('IELTS Speaking')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_session == null || _session!.exercises.isEmpty) return const Scaffold();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQ = _session!.exercises[_currentQuestionIndex];
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Part ${_currentQuestionIndex + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _accentColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentQ.question,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Recording area
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Mic button with pulse animation
                              GestureDetector(
                                onTap: _isEvaluating ? null : _toggleRecording,
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final scale = _isRecording
                                        ? 1.0 + _pulseController.value * 0.1
                                        : 1.0;
                                    return Transform.scale(
                                      scale: scale,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: _isRecording
                                              ? LinearGradient(
                                                  colors: [
                                                    _accentColor,
                                                    _accentColor.withValues(alpha: 0.8),
                                                  ],
                                                )
                                              : null,
                                          color: _isRecording
                                              ? null
                                              : _accentColor.withValues(alpha: 0.1),
                                          boxShadow: _isRecording
                                              ? [
                                                  BoxShadow(
                                                    color: _accentColor.withValues(alpha: 0.5),
                                                    blurRadius: 20,
                                                    spreadRadius: 5,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          _isRecording
                                              ? Icons.stop_rounded
                                              : Icons.mic_rounded,
                                          size: 40,
                                          color: _isRecording
                                              ? Colors.white
                                              : _accentColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Status text
                              if (_isTranscribing)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Transcribing your speech...',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: _accentColor,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  _isRecording
                                      ? 'Recording... Tap to stop'
                                      : 'Tap to start speaking',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),

                              // Error message
                              if (_recordingError != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _recordingError!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.error,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Transcript display / edit
                              if (!_isRecording && !_isTranscribing &&
                                  _transcriptController.text.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Transcript',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'You can edit this',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _transcriptController,
                                        maxLines: 4,
                                        minLines: 1,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                        ),
                                        style: GoogleFonts.inter(fontSize: 14),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _showExitDialog,
            icon: const Icon(Icons.close_rounded),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.mic_rounded, color: _accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Speaking',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Text(
            'Q${_currentQuestionIndex + 1}/${_session!.exercises.length}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _accentColor,
            ),
          ),
          const SizedBox(width: 12),
          TimerWidget(
            totalSeconds: 15 * 60,
            size: 50,
            color: _accentColor,
            onTimeUp: _submitSpeaking,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool canProceed = !_isEvaluating && !_isRecording && !_isTranscribing;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: canProceed ? _nextQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            disabledBackgroundColor: _accentColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isEvaluating
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  _currentQuestionIndex < _session!.exercises.length - 1 ? 'Next Question' : 'Submit Evaluation',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
