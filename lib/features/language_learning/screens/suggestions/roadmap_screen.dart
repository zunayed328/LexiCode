import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../providers/progress_provider.dart';
import '../../models/suggestion_model.dart';

/// AI-generated personalized learning roadmap with phases, milestones, and schedule.
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressProvider = context.watch<ProgressProvider>();

    return Scaffold(
      body: SafeArea(
        child: progressProvider.isGeneratingRoadmap
            ? _buildLoadingState(isDark)
            : progressProvider.roadmap == null
                ? _buildErrorState(context, isDark)
                : _buildRoadmapContent(context, isDark, progressProvider.roadmap!),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Designing Your AI Roadmap',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing weaknesses, distributing skill exercises,\nand compiling milestones...',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          Text('Failed to generate roadmap.', style: GoogleFonts.inter(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          )
        ],
      ),
    );
  }

  Widget _buildRoadmapContent(BuildContext context, bool isDark, LearningRoadmap roadmap) {
    // Determine overall progress and timeline
    int totalWeeks = roadmap.phases.fold(0, (sum, p) => sum + p.durationWeeks);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
        SliverToBoxAdapter(child: _buildGoalHeader(isDark, totalWeeks)),
        SliverToBoxAdapter(child: _buildSectionTitle('Learning Phases', isDark)),
        SliverToBoxAdapter(child: _buildPhases(isDark, roadmap.phases)),
        SliverToBoxAdapter(child: _buildSectionTitle('Weekly Schedule Overview', isDark)),
        SliverToBoxAdapter(child: _buildWeeklySchedule(isDark, roadmap.phases)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
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
            child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Learning Roadmap', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Personalized AI plan',
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

  Widget _buildGoalHeader(bool isDark, int totalWeeks) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(20),
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
            const Icon(Icons.flag_rounded, color: Colors.white, size: 36),
            const SizedBox(height: 10),
            Text('Action Plan Ready', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
            Text('$totalWeeks-Week Strategy',
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Customized to eliminate your specific weaknesses',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildPhases(bool isDark, List<RoadmapPhase> phases) {
    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: phases.asMap().entries.map((entry) {
          final index = entry.key;
          final phase = entry.value;
          final isLast = index == phases.length - 1;
          final color = colors[index % colors.length];

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: phase.isCompleted ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: phase.progress >= 1 ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: phase.isCompleted
                                ? color.withValues(alpha: 0.4)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GlassCard(
                      borderColor: color.withValues(alpha: 0.2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Phase ${index + 1}: ${phase.name}',
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${phase.durationWeeks} Weeks',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (phase.expectedImprovement.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text('🎯 ${phase.expectedImprovement}',
                                    style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w500))),
                          ...phase.objectives.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ', style: TextStyle(color: color)),
                                    Expanded(
                                      child: Text(item,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.3,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                          )),
                                    ),
                                  ],
                                ),
                              )),
                          if (phase.focusSkills.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: phase.focusSkills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(skill,
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
                                );
                              }).toList(),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklySchedule(bool isDark, List<RoadmapPhase> phases) {
    // Show schedule of the first phase just as an overview
    if (phases.isEmpty || phases.first.dailyActivities.isEmpty) return const SizedBox();

    final schedule = phases.first.dailyActivities;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          children: schedule.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
