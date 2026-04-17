import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/exercise_model.dart';
import '../../models/exam_result_model.dart';
import '../../services/content_generation_service.dart';
import '../../services/gemini_learning_service.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/timer_widget.dart';
import 'exam_result_screen.dart';

class IeltsWritingScreen extends StatefulWidget {
  final bool isFullExam;
  
  const IeltsWritingScreen({super.key, this.isFullExam = false});

  @override
  State<IeltsWritingScreen> createState() => _IeltsWritingScreenState();
}

class _IeltsWritingScreenState extends State<IeltsWritingScreen> {
  final ContentGenerationService _contentService = ContentGenerationService();
  final GeminiLearningService _gemini = GeminiLearningService();
  final TextEditingController _textController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEvaluating = false;
  String? _error;
  ExerciseSession? _session;
  
  final Color _accentColor = const Color(0xFFEC4899);
  
  @override
  void initState() {
    super.initState();
    _loadSection();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSection() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final session = await _contentService.getIELTSSection(
        IELTSSectionType.writing,
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

  Future<void> _submitWriting() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _session == null || _session!.exercises.isEmpty) return;
    
    final prompt = _session!.exercises.first.context ?? _session!.exercises.first.question;
    
    setState(() => _isEvaluating = true);
    
    try {
      final evaluation = await _gemini.evaluateWriting(text, prompt);
      if (mounted) {
        setState(() => _isEvaluating = false);
        // Navigate or handle evaluation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ExamResultScreen(writingResult: evaluation)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evaluation failed: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _isEvaluating = false);
      }
    }
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
        appBar: AppBar(title: const Text('IELTS Writing')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_session == null || _session!.exercises.isEmpty) return const Scaffold();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exercise = _session!.exercises.first;
    final String promptText = exercise.context ?? exercise.question;
    final String? imageUrl = exercise.imageUrl;
    final int wordCount = _textController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(wordCount),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      flex: 0,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: GlassCard(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prompt',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _accentColor.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  promptText,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.lightText,
                                  ),
                                ),
                                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxHeight: 250),
                                      child: Image.asset(
                                        imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            width: double.infinity,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.05)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.broken_image_rounded,
                                                    color: Colors.grey, size: 32),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Image failed to load',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Write your essay here...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: _accentColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        style: GoogleFonts.inter(fontSize: 16, height: 1.5),
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

  Widget _buildHeader(int wordCount) {
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
            child: Icon(Icons.create_rounded, color: _accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Writing',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Text(
            '$wordCount words',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: wordCount >= 150 ? AppColors.success : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          TimerWidget(
            totalSeconds: 60 * 60,
            size: 50,
            color: _accentColor,
            onTimeUp: () {
              if (_textController.text.isNotEmpty) {
                _submitWriting();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isEvaluating || _textController.text.trim().isEmpty ? null : _submitWriting,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            disabledBackgroundColor: _accentColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isEvaluating
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Submit for Evaluation', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
