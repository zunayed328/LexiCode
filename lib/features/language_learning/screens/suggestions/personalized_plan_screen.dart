import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/suggestion_model.dart';
import '../../providers/progress_provider.dart';
import '../../services/content_generation_service.dart';
import '../../models/exercise_model.dart';
import '../intermediate/practice_session_screen.dart';

/// Personalized daily plan based on AI suggestions.
class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  final ContentGenerationService _contentService = ContentGenerationService();
  DailySuggestion? _suggestion;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestion();
  }

  Future<void> _loadSuggestion() async {
    try {
      final progress = context.read<ProgressProvider>().userProgress;
      final suggestion = await _contentService.getDailySuggestion(progress);
      if (mounted) {
        setState(() {
          _suggestion = suggestion;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate personalized plan: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            if (_isLoading)
              SliverToBoxAdapter(child: _buildLoading(isDark))
            else if (_error != null)
              SliverToBoxAdapter(child: _buildError(context, isDark))
            else if (_suggestion != null) ...[
              SliverToBoxAdapter(child: _buildHero(isDark, _suggestion!)),
              SliverToBoxAdapter(
                child: _buildSectionTitle('Morning Focus', isDark),
              ),
              SliverToBoxAdapter(
                child: _buildActivityCard(
                  isDark,
                  _suggestion!.mainActivity,
                  AppColors.primary,
                ),
              ),
              if (_suggestion!.secondaryActivity != null) ...[
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Afternoon Continuation', isDark),
                ),
                SliverToBoxAdapter(
                  child: _buildActivityCard(
                    isDark,
                    _suggestion!.secondaryActivity!,
                    AppColors.info,
                  ),
                ),
              ],
              if (_suggestion!.bonusActivity != null) ...[
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Evening Bonus (Optional)', isDark),
                ),
                SliverToBoxAdapter(
                  child: _buildActivityCard(
                    isDark,
                    _suggestion!.bonusActivity!,
                    AppColors.secondary,
                  ),
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
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
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
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
                  'Personalized Plan',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Your daily AI curriculum',
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

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            const SizedBox(height: 20),
            Text(
              'Curating your daily plan...',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.error),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadSuggestion();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark, DailySuggestion suggestion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Today\'s Objective',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              suggestion.expectedOutcome,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (suggestion.motivationalMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion.motivationalMessage,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${suggestion.totalMinutes} Min Total',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildActivityCard(
    bool isDark,
    SuggestedActivity activity,
    Color accentColor,
  ) {
    IconData icon;
    SessionType sessionType;
    switch (activity.type.toLowerCase()) {
      case 'reading':
        icon = Icons.menu_book_rounded;
        sessionType = SessionType.readingPractice;
        break;
      case 'writing':
        icon = Icons.edit_note_rounded;
        sessionType = SessionType.grammarPractice; // fallback
        break;
      case 'listening':
        icon = Icons.headset_rounded;
        sessionType = SessionType.listeningPractice;
        break;
      case 'speaking':
        icon = Icons.mic_rounded;
        sessionType = SessionType.speakingPractice;
        break;
      case 'grammar':
        icon = Icons.rule_rounded;
        sessionType = SessionType.grammarPractice;
        break;
      default:
        icon = Icons.fitness_center_rounded;
        sessionType = SessionType.mixedSkills;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        borderColor: accentColor.withOpacity(0.2),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.topic,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${activity.type} • ${activity.durationMinutes} min',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activity.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PracticeSessionScreen(
                      sessionType: sessionType,
                      title: activity.topic,
                    ),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
