import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/exam_result_model.dart';
import '../../widgets/score_reveal.dart';

class ExamResultScreen extends StatelessWidget {
  final ExamResult? fullExamResult;
  final SkillResult? listeningResult;
  final SkillResult? readingResult;
  final WritingEvaluation? writingResult;
  final SpeakingEvaluation? speakingResult;

  const ExamResultScreen({
    super.key,
    this.fullExamResult,
    this.listeningResult,
    this.readingResult,
    this.writingResult,
    this.speakingResult,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context)),
            
            // Overall Score for Full Exam
            if (fullExamResult != null)
              SliverToBoxAdapter(child: _buildOverallScore(isDark, fullExamResult!)),

            // Section Scores for Full Exam
            if (fullExamResult != null) ...[
              SliverToBoxAdapter(child: _buildSectionTitle('Section Results', isDark)),
              SliverToBoxAdapter(child: _buildSectionScores(isDark, fullExamResult!)),
              if (fullExamResult!.skillResults[IELTSSectionType.writing]?.writingEvaluation != null) ...[
                SliverToBoxAdapter(child: _buildSectionTitle('Writing Evaluation', isDark)),
                SliverToBoxAdapter(child: _buildWritingDetails(isDark, fullExamResult!.skillResults[IELTSSectionType.writing]!.writingEvaluation!)),
              ],
              if (fullExamResult!.skillResults[IELTSSectionType.speaking]?.speakingEvaluation != null) ...[
                SliverToBoxAdapter(child: _buildSectionTitle('Speaking Evaluation', isDark)),
                SliverToBoxAdapter(child: _buildSpeakingDetails(isDark, fullExamResult!.skillResults[IELTSSectionType.speaking]!.speakingEvaluation!)),
              ],
              if (fullExamResult!.aiReport != null) ...[
                SliverToBoxAdapter(child: _buildSectionTitle('AI Personalized Report', isDark)),
                SliverToBoxAdapter(child: _buildAIReport(isDark, fullExamResult!.aiReport!)),
              ],
            ],

            // Individual Results View
            if (writingResult != null) ...[
              SliverToBoxAdapter(child: _buildIsolatedWritingResult(isDark, writingResult!)),
            ],
            if (speakingResult != null) ...[
              SliverToBoxAdapter(child: _buildIsolatedSpeakingResult(isDark, speakingResult!)),
            ],
            if (listeningResult != null) ...[
              SliverToBoxAdapter(child: _buildIsolatedSkillResult('Listening', Icons.headphones, const Color(0xFF3B82F6), isDark, listeningResult!)),
            ],
            if (readingResult != null) ...[
              SliverToBoxAdapter(child: _buildIsolatedSkillResult('Reading', Icons.menu_book, const Color(0xFF10B981), isDark, readingResult!)),
            ],

            SliverToBoxAdapter(child: _buildActions(context, isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          Text('Results', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildOverallScore(bool isDark, ExamResult result) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text('Overall Band Score', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 8),
            ScoreReveal(
              score: result.overallBand, 
              maxScore: 9,
              isBandScore: true,
              size: 120,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('CEFR Level: ${result.cefrLevel}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSectionScores(bool isDark, ExamResult result) {
    final listening = result.skillResults[IELTSSectionType.listening];
    final reading = result.skillResults[IELTSSectionType.reading];
    final writing = result.skillResults[IELTSSectionType.writing];
    final speaking = result.skillResults[IELTSSectionType.speaking];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (listening != null) Expanded(child: _buildMiniSectionCard('Listening', Icons.headphones_rounded, const Color(0xFF3B82F6), listening, isDark)),
          if (reading != null) Expanded(child: _buildMiniSectionCard('Reading', Icons.menu_book_rounded, const Color(0xFF10B981), reading, isDark)),
          if (writing != null) Expanded(child: _buildMiniSectionCard('Writing', Icons.edit_rounded, const Color(0xFFF59E0B), writing, isDark)),
          if (speaking != null) Expanded(child: _buildMiniSectionCard('Speaking', Icons.mic_rounded, const Color(0xFFEC4899), speaking, isDark)),
        ],
      ),
    );
  }

  Widget _buildMiniSectionCard(String title, IconData icon, Color color, SkillResult result, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(result.bandScore.toString(), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          if (result.totalQuestions > 0) ...[
            const SizedBox(height: 4),
            Text('${result.correctAnswers}/${result.totalQuestions}', style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildWritingDetails(bool isDark, WritingEvaluation writing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCriteriaRow('Task Achievement', writing.taskAchievement, isDark, const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            _buildCriteriaRow('Coherence & Cohesion', writing.coherenceCohesion, isDark, const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            _buildCriteriaRow('Lexical Resource', writing.lexicalResource, isDark, const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            _buildCriteriaRow('Grammatical Range', writing.grammaticalRange, isDark, const Color(0xFFF59E0B)),
            if (writing.detailedFeedback != null) ...[
              const SizedBox(height: 14),
              Text(writing.detailedFeedback!, style: GoogleFonts.inter(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakingDetails(bool isDark, SpeakingEvaluation speaking) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        borderColor: const Color(0xFFEC4899).withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCriteriaRow('Fluency & Coherence', speaking.fluencyCoherence, isDark, const Color(0xFFEC4899)),
            const SizedBox(height: 8),
            _buildCriteriaRow('Pronunciation', speaking.pronunciation, isDark, const Color(0xFFEC4899)),
            const SizedBox(height: 8),
            _buildCriteriaRow('Lexical Resource', speaking.lexicalResource, isDark, const Color(0xFFEC4899)),
            const SizedBox(height: 8),
            _buildCriteriaRow('Grammatical Range', speaking.grammaticalRange, isDark, const Color(0xFFEC4899)),
            if (speaking.feedback.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(speaking.feedback.join('\n'), style: GoogleFonts.inter(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, color: isDark ? Colors.white60 : Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIsolatedWritingResult(bool isDark, WritingEvaluation result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScoreHeader(result.overallBand, 'Writing Band Score', isDark, const Color(0xFFF59E0B)),
          _buildSectionTitle('Detailed Criteria', isDark),
          _buildWritingDetails(isDark, result),
        ],
      ),
    );
  }

  Widget _buildIsolatedSpeakingResult(bool isDark, SpeakingEvaluation result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScoreHeader(result.overallBand, 'Speaking Band Score', isDark, const Color(0xFFEC4899)),
          _buildSectionTitle('Detailed Criteria', isDark),
          _buildSpeakingDetails(isDark, result),
        ],
      ),
    );
  }

  Widget _buildIsolatedSkillResult(String title, IconData icon, Color color, bool isDark, SkillResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScoreHeader(result.bandScore, '$title Band Score', isDark, color),
          const SizedBox(height: 16),
          GlassCard(
            borderColor: color.withValues(alpha: 0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Correct', style: GoogleFonts.inter(fontSize: 14, color: AppColors.success)),
                    Text(result.correctAnswers.toString(), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('Total', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                    Text(result.totalQuestions.toString(), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScoreHeader(double score, String title, bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 12),
          ScoreReveal(score: score, maxScore: 9, isBandScore: true, size: 100),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String label, double score, bool isDark, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        Container(
          width: 44,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(score.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ),
        ),
      ],
    );
  }

  Widget _buildAIReport(bool isDark, String report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        borderColor: AppColors.primary.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('AI Analysis', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            Text(report, style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: isDark ? Colors.white70 : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text('Done', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
