import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/exercise_model.dart';
import '../intermediate/practice_session_screen.dart';
import '../../widgets/streak_celebration.dart';
import '../../services/content_generation_service.dart';
import '../../providers/progress_provider.dart';

/// Daily practice screen with dynamically generated phases via AI.
class DailyPracticeScreen extends StatefulWidget {
  const DailyPracticeScreen({super.key});

  @override
  State<DailyPracticeScreen> createState() => _DailyPracticeScreenState();
}

class _DailyPracticeScreenState extends State<DailyPracticeScreen> {
  final ContentGenerationService _contentService = ContentGenerationService();
  bool _isLoading = true;
  String? _error;
  int _currentStep = 0;
  bool _sessionComplete = false;
  List<_PracticeStep> _steps = [];
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyPractice();
  }

  Future<void> _loadDailyPractice() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final session = await _contentService.getDailyPractice(
        DateTime.now(),
        progress,
      );

      if (!mounted) return;

      final exercises = session.exercises;
      final steps = <_PracticeStep>[];

      if (exercises.isNotEmpty) {
        // Partition exercises
        int warmupCount = (exercises.length * 0.2).ceil();
        int challengeCount = (exercises.length * 0.2).ceil();
        int mainCount = exercises.length - warmupCount - challengeCount;

        if (warmupCount > 0) {
          steps.add(
            _PracticeStep(
              title: 'Warm-up',
              subtitle: session.warmupText ?? 'Quick vocabulary review',
              icon: Icons.wb_sunny_rounded,
              color: const Color(0xFFF59E0B),
              duration: '${warmupCount * 2} min',
              type: SessionType.mixedSkills,
              exercises: exercises.sublist(0, warmupCount),
            ),
          );
        }

        if (mainCount > 0) {
          steps.add(
            _PracticeStep(
              title: 'Main Practice',
              subtitle: session.topic ?? 'Core exercises',
              icon: Icons.fitness_center_rounded,
              color: const Color(0xFF3B82F6),
              duration: '${mainCount * 2} min',
              type: SessionType.grammarPractice,
              exercises: exercises.sublist(
                warmupCount,
                warmupCount + mainCount,
              ),
            ),
          );
        }

        if (challengeCount > 0) {
          steps.add(
            _PracticeStep(
              title: 'Challenge',
              subtitle: 'Apply what you learned',
              icon: Icons.bolt_rounded,
              color: const Color(0xFFEF4444),
              duration: '${challengeCount * 2} min',
              type: SessionType.grammarPractice,
              exercises: exercises.sublist(warmupCount + mainCount),
            ),
          );
        }

        // Add Cooldown reflection if present
        if (session.cooldownReflection != null &&
            session.cooldownReflection!.isNotEmpty) {
          steps.add(
            _PracticeStep(
              title: 'Cool-down',
              subtitle: 'Reflection & review',
              icon: Icons.nightlight_rounded,
              color: const Color(0xFF8B5CF6),
              duration: '2 min',
              type: SessionType.readingPractice,
              exercises: [],
              reflectionText: session.cooldownReflection,
            ),
          );
        }
      }

      setState(() {
        _steps = steps;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to generate exercises: $e';
        _isLoading = false;
      });
    }
  }

  void _startStep(_PracticeStep step) async {
    if (step.reflectionText != null) {
      _showReflectionDialog(step.reflectionText!);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          sessionType: step.type,
          title: step.title,
          exercises: step.exercises,
        ),
      ),
    );

    if (mounted) {
      // Add XP from returned session... we mock the completion currently.
      setState(() {
        _xpEarned += (step.exercises.length * 10);
        if (_currentStep < _steps.length - 1) {
          _currentStep++;
        } else {
          _sessionComplete = true;
          context.read<ProgressProvider>().addXp(_xpEarned);
        }
      });
    }
  }

  void _showReflectionDialog(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cool-down Reflection'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _sessionComplete = true;
                context.read<ProgressProvider>().addXp(_xpEarned + 10);
              });
            },
            child: const Text('Complete Session'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(body: _buildLoadingScreen(isDark));
    }
    if (_error != null) {
      return Scaffold(body: _buildErrorScreen(isDark));
    }

    if (_sessionComplete) return _buildCompleteScreen(isDark);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            SliverToBoxAdapter(child: _buildProgress(isDark)),
            SliverToBoxAdapter(child: _buildCurrentStep(isDark)),
            SliverToBoxAdapter(child: _buildStepList(isDark)),
            SliverToBoxAdapter(child: _buildTomorrowPreview(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFEC4899)),
          const SizedBox(height: 24),
          Text(
            'Generating personalized exercises...',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadDailyPractice();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    int totalTime = _steps.fold<int>(
      0,
      (sum, step) => sum + int.parse(step.duration.split(' ')[0]),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.today_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Practice",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '~$totalTime minutes • ${_steps.length} activities',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(bool isDark) {
    if (_steps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          Row(
            children: _steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final isActive = idx == _currentStep;
              final isComplete = idx < _currentStep;

              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? step.color
                        : isActive
                        ? step.color.withOpacity(0.5)
                        : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _steps[_currentStep].color,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentStep * 100 ~/ _steps.length}% complete',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    if (_steps.isEmpty) return const SizedBox.shrink();
    final step = _steps[_currentStep];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [step.color, step.color.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: step.color.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(step.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              step.title,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              step.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.duration,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _startStep(step),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: step.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Start ${step.title}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepList(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final step = entry.value;
          final isComplete = idx < _currentStep;
          final isActive = idx == _currentStep;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? step.color.withOpacity(0.3)
                    : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppColors.success.withOpacity(0.12)
                        : step.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isComplete ? Icons.check_rounded : step.icon,
                    color: isComplete ? AppColors.success : step.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isComplete
                              ? (isDark ? Colors.white54 : Colors.black45)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      Text(
                        step.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  step.duration,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTomorrowPreview(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_rounded,
                color: AppColors.info,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tomorrow's Preview",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Keep building your streak!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteScreen(bool isDark) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreakCelebration(
                  streakDays:
                      context
                          .read<ProgressProvider>()
                          .userProgress
                          .streak
                          .currentStreak +
                      1,
                  onDismiss: () {},
                ),
                const SizedBox(height: 24),
                Text(
                  'Daily Practice Complete! 🎉',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You completed all ${_steps.length} activities today.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompleteStat('+$_xpEarned XP', AppColors.xpColor),
                    _buildCompleteStat('🔥', AppColors.streakColor),
                    _buildCompleteStat(
                      '${_steps.length}/${_steps.length}',
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteStat(String value, Color color) {
    return Text(
      value,
      style: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _PracticeStep {
  final String title, subtitle, duration;
  final IconData icon;
  final Color color;
  final SessionType type;
  final List<Exercise> exercises;
  final String? reflectionText;

  const _PracticeStep({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
    required this.color,
    required this.type,
    required this.exercises,
    this.reflectionText,
  });
}
