import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'exam_result_screen.dart';
import 'ielts_listening_screen.dart';
import 'ielts_reading_screen.dart';
import 'ielts_writing_screen.dart';
import 'ielts_speaking_screen.dart';

/// Advanced IELTS dashboard with exam overview, section practice, and history.
class AdvancedDashboard extends StatelessWidget {
  const AdvancedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            SliverToBoxAdapter(child: _buildExamOverview(context, isDark)),
            SliverToBoxAdapter(
                child: _buildSectionTitle('Practice by Section', isDark)),
            SliverToBoxAdapter(child: _buildSectionCards(context, isDark)),
            SliverToBoxAdapter(
                child: _buildSectionTitle('Target Band Score', isDark)),
            SliverToBoxAdapter(child: _buildTargetBand(isDark)),
            SliverToBoxAdapter(
                child: _buildSectionTitle('Exam History', isDark)),
            SliverToBoxAdapter(child: _buildExamHistory(context, isDark)),
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
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Advanced Level',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                Text('C1–C2 • IELTS-Style Assessment',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamOverview(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('IELTS Practice',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                ),
                const Spacer(),
                Text('~2h 45min',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    )),
              ],
            ),
            const SizedBox(height: 20),
            Text('Full IELTS Mock Exam',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                )),
            const SizedBox(height: 8),
            Text(
              'Complete all 4 sections: Listening, Reading, Writing, and Speaking. Get AI-powered band score evaluation.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Section icons
            Row(
              children: [
                _SectionIcon(Icons.headphones_rounded, 'Listening'),
                const SizedBox(width: 12),
                _SectionIcon(Icons.menu_book_rounded, 'Reading'),
                const SizedBox(width: 12),
                _SectionIcon(Icons.edit_rounded, 'Writing'),
                const SizedBox(width: 12),
                _SectionIcon(Icons.mic_rounded, 'Speaking'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IeltsListeningScreen(isFullExam: true)),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Start Full Exam',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(title,
          style:
              GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSectionCards(BuildContext context, bool isDark) {
    final sections = [
      _SectionInfo(
        'Listening', Icons.headphones_rounded,
        [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        '30 min', '40 questions',
        'Fill-blank, MCQ, note completion from audio passages',
      ),
      _SectionInfo(
        'Reading', Icons.menu_book_rounded,
        [const Color(0xFF10B981), const Color(0xFF059669)],
        '60 min', '40 questions',
        'True/False, MCQ, matching from academic passages',
      ),
      _SectionInfo(
        'Writing', Icons.edit_rounded,
        [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        '60 min', '2 tasks',
        'Task 1: 150 words (data description) • Task 2: 250 words (essay)',
      ),
      _SectionInfo(
        'Speaking', Icons.mic_rounded,
        [const Color(0xFFEC4899), const Color(0xFFDB2777)],
        '15 min', '3 parts',
        'Introduction, cue card, discussion with AI interviewer',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: sections.map((section) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  switch (section.title.toLowerCase()) {
                    case 'listening':
                      return const IeltsListeningScreen();
                    case 'reading':
                      return const IeltsReadingScreen();
                    case 'writing':
                      return const IeltsWritingScreen();
                    case 'speaking':
                      return const IeltsSpeakingScreen();
                    default:
                      return const Scaffold();
                  }
                },
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    section.gradient.first.withValues(alpha: 0.12),
                    section.gradient.last.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: section.gradient.first.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: section.gradient),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(section.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(section.title,
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(section.duration,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: section.gradient.first,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(section.questionCount,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            )),
                        const SizedBox(height: 4),
                        Text(section.description,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTargetBand(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BandTarget('Current', 5.5, AppColors.warning),
                SizedBox(
                  width: 60,
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary, size: 28),
                ),
                _BandTarget('Target', 7.0, AppColors.success),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Complete practice sessions to improve your estimated band score',
              textAlign: TextAlign.center,
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
    );
  }

  Widget _buildExamHistory(BuildContext context, bool isDark) {
    final history = [
      _ExamRecord('Mock Exam #3', '2 days ago', 6.5, true),
      _ExamRecord('Listening Only', '5 days ago', 7.0, false),
      _ExamRecord('Mock Exam #2', '1 week ago', 6.0, true),
    ];

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassCard(
          child: Column(
            children: [
              const Icon(Icons.history_rounded, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text('No exams taken yet',
                  style: GoogleFonts.inter(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: history.map((exam) {
          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ExamResultScreen())),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getBandColor(exam.bandScore)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        exam.bandScore.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _getBandColor(exam.bandScore),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exam.title,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(exam.date,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            )),
                      ],
                    ),
                  ),
                  if (exam.isFullExam)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Full',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B5CF6),
                          )),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getBandColor(double band) {
    if (band >= 8.0) return AppColors.success;
    if (band >= 7.0) return const Color(0xFF34D399);
    if (band >= 6.0) return AppColors.warning;
    return AppColors.error;
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionIcon(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

class _BandTarget extends StatelessWidget {
  final String label;
  final double band;
  final Color color;
  const _BandTarget(this.label, this.band, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(band.toString(),
            style: GoogleFonts.inter(
                fontSize: 36, fontWeight: FontWeight.w800, color: color)),
        Text('Band',
            style: GoogleFonts.inter(fontSize: 12, color: color)),
      ],
    );
  }
}

class _SectionInfo {
  final String title, duration, questionCount, description;
  final IconData icon;
  final List<Color> gradient;
  const _SectionInfo(this.title, this.icon, this.gradient,
      this.duration, this.questionCount, this.description);
}

class _ExamRecord {
  final String title, date;
  final double bandScore;
  final bool isFullExam;
  const _ExamRecord(this.title, this.date, this.bandScore, this.isFullExam);
}
