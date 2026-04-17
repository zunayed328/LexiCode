import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Animated score reveal with counting-up animation and color-coding.
///
/// Used for session results and IELTS band score display.
class ScoreReveal extends StatefulWidget {
  final double score;
  final double maxScore;
  final String? label;
  final String? subtitle;
  final bool isBandScore;
  final double size;

  const ScoreReveal({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.label,
    this.subtitle,
    this.isBandScore = false,
    this.size = 140,
  });

  @override
  State<ScoreReveal> createState() => _ScoreRevealState();
}

class _ScoreRevealState extends State<ScoreReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _countAnimation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (widget.isBandScore) {
      if (score >= 8.0) return const Color(0xFF10B981);
      if (score >= 7.0) return const Color(0xFF34D399);
      if (score >= 6.0) return const Color(0xFFFBBF24);
      if (score >= 5.0) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }
    final ratio = score / widget.maxScore;
    if (ratio >= 0.8) return AppColors.success;
    if (ratio >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final currentScore = _countAnimation.value;
        final color = _getScoreColor(currentScore);
        final progress = currentScore / widget.maxScore;

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circle with score
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        valueColor: AlwaysStoppedAnimation(
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    // Progress ring
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    // Score text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isBandScore
                              ? currentScore.toStringAsFixed(1)
                              : '${currentScore.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: widget.size * 0.28,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        if (!widget.isBandScore)
                          Text(
                            '/${widget.maxScore.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: widget.size * 0.12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.label != null) ...[
                const SizedBox(height: 14),
                Text(
                  widget.label!,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
              ],
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
              // Performance message
              const SizedBox(height: 10),
              _buildPerformanceMessage(currentScore, color),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMessage(double score, Color color) {
    String message;
    String emoji;
    if (widget.isBandScore) {
      if (score >= 8.0) {
        message = 'Expert User';
        emoji = '🏆';
      } else if (score >= 7.0) {
        message = 'Good User';
        emoji = '⭐';
      } else if (score >= 6.0) {
        message = 'Competent User';
        emoji = '👍';
      } else if (score >= 5.0) {
        message = 'Modest User';
        emoji = '📚';
      } else {
        message = 'Keep Practicing';
        emoji = '💪';
      }
    } else {
      final ratio = score / widget.maxScore;
      if (ratio >= 0.9) {
        message = 'Outstanding!';
        emoji = '🏆';
      } else if (ratio >= 0.7) {
        message = 'Great job!';
        emoji = '⭐';
      } else if (ratio >= 0.5) {
        message = 'Good effort!';
        emoji = '👍';
      } else {
        message = 'Keep going!';
        emoji = '💪';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $message',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
