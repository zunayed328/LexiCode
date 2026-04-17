import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Progress bar header for exercise/practice sessions.
///
/// Shows question progress, optional timer, session type, and exit button.
class ProgressHeader extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final String? sessionTitle;
  final int? timeRemainingSeconds;
  final VoidCallback? onClose;
  final Color? accentColor;

  const ProgressHeader({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    this.sessionTitle,
    this.timeRemainingSeconds,
    this.onClose,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = totalQuestions > 0 ? currentQuestion / totalQuestions : 0.0;
    final color = accentColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Top row: title + timer + close
          Row(
            children: [
              if (onClose != null)
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              if (onClose != null) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sessionTitle ?? 'Practice',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
              ),
              if (timeRemainingSeconds != null) _buildTimer(isDark),
              const SizedBox(width: 12),
              Text(
                '$currentQuestion/$totalQuestions',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation(color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(bool isDark) {
    final minutes = timeRemainingSeconds! ~/ 60;
    final seconds = timeRemainingSeconds! % 60;
    final isLow = timeRemainingSeconds! < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.error.withValues(alpha: 0.15)
            : (isDark
                ? AppColors.darkCard
                : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 16,
            color: isLow ? AppColors.error : AppColors.info,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isLow ? AppColors.error : AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}
