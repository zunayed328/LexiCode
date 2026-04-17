import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/suggestion_model.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/skill_radar_chart.dart';
import 'roadmap_screen.dart';
import 'personalized_plan_screen.dart';
import 'weakness_analysis_screen.dart';

/// AI-powered weakness analysis and personalized suggestion screen.
class AiSuggestionsScreen extends StatefulWidget {
  const AiSuggestionsScreen({super.key});

  @override
  State<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends State<AiSuggestionsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProgressProvider>();
      if (provider.weaknessAnalysis != null) {
        // Already has analysis
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressProvider = context.watch<ProgressProvider>();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            if (progressProvider.weaknessAnalysis == null)
              SliverToBoxAdapter(child: _buildAnalyzePrompt(isDark, progressProvider))
            else ...[
              SliverToBoxAdapter(
                  child: _buildSkillRadar(isDark, progressProvider)),
              if (progressProvider.weaknessAnalysis!.criticalWeaknesses.isNotEmpty ||
                  progressProvider.weaknessAnalysis!.moderateWeaknesses.isNotEmpty)
                SliverToBoxAdapter(
                    child: _buildWeaknesses(isDark, progressProvider.weaknessAnalysis!)),
              if (progressProvider.weaknessAnalysis!.strengthsToLeverage.isNotEmpty)
                SliverToBoxAdapter(
                    child: _buildStrengths(isDark, progressProvider.weaknessAnalysis!)),
              if (progressProvider.weaknessAnalysis!.hiddenPatterns.isNotEmpty)
                SliverToBoxAdapter(
                    child: _buildHiddenPatterns(isDark, progressProvider.weaknessAnalysis!)),
              SliverToBoxAdapter(
                  child: _buildPersonalizedPlanCTA(context, isDark)),
              SliverToBoxAdapter(
                  child: _buildRoadmapCTA(context, isDark, progressProvider)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
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
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Suggestions',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Personalized learning analysis',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzePrompt(bool isDark, ProgressProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 28),
          Text(
            'AI Learning Analysis',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'Let AI analyze your learning patterns, identify weaknesses, and create a personalized improvement roadmap.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: provider.isAnalyzing ? null : () => provider.getWeaknessAnalysis(),
              icon: provider.isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                provider.isAnalyzing ? 'Analyzing your progress...' : 'Run AI Analysis',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(provider.error!, style: GoogleFonts.inter(color: AppColors.error)),
            )
        ],
      ),
    );
  }

  Widget _buildSkillRadar(bool isDark, ProgressProvider provider) {
    if (provider.weaknessAnalysis != null && provider.weaknessAnalysis!.skillBalance.isNotEmpty) {
      final balance = provider.weaknessAnalysis!.skillBalance;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: GlassCard(
          child: Column(
            children: [
              Text('Skills Balance', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: SkillRadarChart(
                  grammar: balance['Grammar'] ?? balance['grammar'] ?? 0.0,
                  pronunciation: balance['Pronunciation'] ?? balance['pronunciation'] ?? 0.0,
                  spelling: balance['Spelling'] ?? balance['spelling'] ?? 0.0,
                  reading: balance['Reading'] ?? balance['reading'] ?? 0.0,
                  writing: balance['Writing'] ?? balance['writing'] ?? 0.0,
                  listening: balance['Listening'] ?? balance['listening'] ?? 0.0,
                  speaking: balance['Speaking'] ?? balance['speaking'] ?? 0.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progress = provider.userProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GlassCard(
        child: Column(
          children: [
            Text('Skills Balance', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SkillRadarChart(
                grammar: progress.skills.grammar.currentScore,
                pronunciation: progress.skills.pronunciation.currentScore,
                spelling: progress.skills.spelling.currentScore,
                reading: progress.skills.reading.currentScore,
                writing: progress.skills.writing.currentScore,
                listening: progress.skills.listening.currentScore,
                speaking: progress.skills.speaking.currentScore,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaknesses(bool isDark, WeaknessAnalysis analysis) {
    final List<Weakness> allWeaknesses = [
      ...analysis.criticalWeaknesses,
      ...analysis.moderateWeaknesses,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⚠️ Areas to Improve', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeaknessAnalysisScreen())),
                child: Text('Deep Dive', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...allWeaknesses.map((w) {
            final color = w.urgency.name.toLowerCase() == 'high' || w.urgency.name.toLowerCase() == 'critical'
                ? AppColors.error
                : AppColors.warning;
            return GlassCard(
              borderColor: color.withValues(alpha: 0.2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.track_changes_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(w.area,
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                w.urgency.name.toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(w.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? Colors.white60 : Colors.black54,
                            )),
                        if (w.evidence.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(w.evidence, style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.white54 : Colors.grey)),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStrengths(bool isDark, WeaknessAnalysis analysis) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💪 Your Strengths', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GlassCard(
            borderColor: AppColors.success.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: analysis.strengthsToLeverage.asMap().entries.map((entry) {
                return Column(
                  children: [
                    if (entry.key > 0) const Divider(height: 20),
                    _strengthItem(entry.value),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strengthItem(String title) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildHiddenPatterns(bool isDark, WeaknessAnalysis analysis) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔍 Hidden Patterns', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GlassCard(
            borderColor: AppColors.info.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: analysis.hiddenPatterns.map((pattern) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _patternItem(pattern),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patternItem(String pattern) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•', style: TextStyle(fontSize: 18, color: AppColors.info)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(pattern,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
              )),
        ),
      ],
    );
  }

  Widget _buildPersonalizedPlanCTA(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalizedPlanScreen())),
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
            children: [
              const Icon(Icons.person_outline_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 12),
              Text('Daily Personalized Plan',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Get your optimal mix of reading, writing, speaking, and grammar for today.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('View Action Plan',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF6D28D9))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoadmapCTA(BuildContext context, bool isDark, ProgressProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.map_rounded, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text('Your Learning Roadmap',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'AI has created a personalized study plan based on your strengths and weaknesses.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _openRoadmapDialog(context, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD97706),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Generate & View Roadmap',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoadmapDialog(BuildContext context, ProgressProvider provider) {
    String goal = '';
    String timeline = '4 weeks';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Design Your Action Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Your Goal (e.g. IELTS 7.5, Fluent Speaking)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => goal = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: timeline,
                decoration: InputDecoration(
                  labelText: 'Timeline',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['2 weeks', '4 weeks', '8 weeks', '12 weeks']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) timeline = v;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (goal.trim().isEmpty) return;
                Navigator.pop(ctx);
                provider.generateRoadmap(goal: goal.trim(), timeline: timeline);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RoadmapScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Generate AI Roadmap', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
