import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/code_review_theme.dart';

/// Premium AI Insight card with gradient background, sparkle icon,
/// and rich text rendering of the AI explanation.
class AiInsightCard extends StatefulWidget {
  final String explanation;
  final String summary;
  final int overallScore;
  final String scoreGrade;
  final Color scoreColor;

  const AiInsightCard({
    super.key,
    required this.explanation,
    required this.summary,
    required this.overallScore,
    required this.scoreGrade,
    required this.scoreColor,
  });

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: CodeReviewTheme.insightCardDecoration,
      child: Stack(
        children: [
          // Subtle glow orb
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CodeReviewTheme.accentPurple.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with sparkle + title + score badge
                Row(
                  children: [
                    // Animated sparkle icon
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: const [
                                CodeReviewTheme.accentIndigo,
                                CodeReviewTheme.accentPurple,
                                Colors.white,
                                CodeReviewTheme.accentIndigo,
                              ],
                              stops: [
                                0.0,
                                _shimmerController.value,
                                _shimmerController.value + 0.1,
                                1.0,
                              ].map((s) => s.clamp(0.0, 1.0)).toList(),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI Analysis',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CodeReviewTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Score badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: widget.scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.scoreColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.scoreGrade,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: widget.scoreColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.overallScore}/100',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: widget.scoreColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary line
                if (widget.summary.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      widget.summary,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CodeReviewTheme.textPrimary.withValues(
                          alpha: 0.9,
                        ),
                        height: 1.5,
                      ),
                    ),
                  ),

                // Rich explanation text
                _buildRichExplanation(widget.explanation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Parses simple markdown-like text into styled [TextSpan]s.
  Widget _buildRichExplanation(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Bullet points
      if (line.trimLeft().startsWith('- ') ||
          line.trimLeft().startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CodeReviewTheme.accentIndigo,
                  ),
                ),
                Expanded(
                  child: _buildInlineFormattedText(
                    line.trimLeft().substring(2),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildInlineFormattedText(line),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Handles **bold**, `inline code`, and plain text.
  Widget _buildInlineFormattedText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|`(.+?)`|([^*`]+)');

    for (final match in regex.allMatches(text)) {
      if (match.group(1) != null) {
        // Bold
        spans.add(
          TextSpan(
            text: match.group(1),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CodeReviewTheme.textPrimary,
              height: 1.6,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // Inline code
        spans.add(
          TextSpan(
            text: ' ${match.group(2)} ',
            style: GoogleFonts.firaCode(
              fontSize: 12,
              color: CodeReviewTheme.accentPurple,
              backgroundColor: CodeReviewTheme.accentPurple.withValues(
                alpha: 0.1,
              ),
              height: 1.6,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // Normal text
        spans.add(
          TextSpan(
            text: match.group(3),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: CodeReviewTheme.textSecondary,
              height: 1.6,
            ),
          ),
        );
      }
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}
