import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Animated feedback overlay for correct/incorrect answers.
///
/// Shows checkmark + confetti for correct, X + explanation for incorrect,
/// with XP earned animation and streak counter.
class AnswerFeedback extends StatefulWidget {
  final bool isCorrect;
  final String? feedback;
  final int xpEarned;
  final int streakCount;
  final VoidCallback onContinue;

  const AnswerFeedback({
    super.key,
    required this.isCorrect,
    this.feedback,
    this.xpEarned = 0,
    this.streakCount = 0,
    required this.onContinue,
  });

  @override
  State<AnswerFeedback> createState() => _AnswerFeedbackState();
}

class _AnswerFeedbackState extends State<AnswerFeedback>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _confettiController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isCorrect) {
      _generateConfetti();
      _confettiController.forward();
    }

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _bounceController.forward();
    });
  }

  void _generateConfetti() {
    final random = Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(
        _ConfettiParticle(
          x: random.nextDouble() * 400,
          y: -random.nextDouble() * 100,
          velocityX: (random.nextDouble() - 0.5) * 6,
          velocityY: random.nextDouble() * 8 + 2,
          color: [
            AppColors.primary,
            AppColors.secondary,
            AppColors.accentGreen,
            AppColors.xpColor,
            AppColors.info,
            AppColors.accent,
          ][random.nextInt(6)],
          size: random.nextDouble() * 8 + 4,
          rotation: random.nextDouble() * pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: BoxDecoration(
          color: widget.isCorrect
              ? (isDark ? const Color(0xFF0A2E1A) : const Color(0xFFECFDF5))
              : (isDark ? const Color(0xFF2E0A0A) : const Color(0xFFFEF2F2)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: (widget.isCorrect ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon + status
            ScaleTransition(
              scale: _bounceAnimation,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          (widget.isCorrect
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: widget.isCorrect
                          ? AppColors.success
                          : AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isCorrect ? 'Correct!' : 'Not quite right',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: widget.isCorrect
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        if (widget.isCorrect && widget.xpEarned > 0)
                          Text(
                            '+${widget.xpEarned} XP',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.xpColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.isCorrect && widget.streakCount >= 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.streakCount}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Feedback text
            if (widget.feedback != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      (widget.isCorrect ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.feedback!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isCorrect
                      ? AppColors.success
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
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
    );
  }
}

class _ConfettiParticle {
  double x, y, velocityX, velocityY, size, rotation;
  Color color;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
  });
}
