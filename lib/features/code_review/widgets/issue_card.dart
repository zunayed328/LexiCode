import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/code_review_model.dart';
import '../theme/code_review_theme.dart';

/// Expandable issue card with color-coded severity border.
class IssueCard extends StatelessWidget {
  final CodeIssue issue;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  const IssueCard({
    super.key,
    required this.issue,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: CodeReviewTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? issue.severityColor.withValues(alpha: 0.3)
                : CodeReviewTheme.borderSubtle,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left severity bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 4,
                decoration: BoxDecoration(
                  color: issue.severityColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          // Severity icon
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: issue.severityColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              issue.severityIcon,
                              size: 16,
                              color: issue.severityColor,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: issue.typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              issue.typeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: issue.typeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Title
                          Expanded(
                            child: Text(
                              issue.title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CodeReviewTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Line number badge
                          if (issue.lineNumber != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CodeReviewTheme.textMuted.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'L${issue.lineNumber}',
                                style: GoogleFonts.firaCode(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: CodeReviewTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],

                          // Expand chevron
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: CodeReviewTheme.textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Expanded content
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: _buildExpandedContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(height: 1, color: CodeReviewTheme.borderSubtle),
          const SizedBox(height: 12),

          // Description
          Text(
            issue.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CodeReviewTheme.textSecondary,
              height: 1.5,
            ),
          ),

          // Simple explanation
          if (issue.simpleExplanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CodeReviewTheme.accentInfo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CodeReviewTheme.accentInfo.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 16,
                    color: CodeReviewTheme.accentInfo.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.simpleExplanation,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CodeReviewTheme.accentInfo,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Suggestion
          if (issue.suggestion != null && issue.suggestion!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  size: 14,
                  color: CodeReviewTheme.accentWarning.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    issue.suggestion!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CodeReviewTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Code example
          if (issue.codeExample != null && issue.codeExample!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CodeReviewTheme.codeBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CodeReviewTheme.borderSubtle),
              ),
              child: Text(
                issue.codeExample!,
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  color: CodeReviewTheme.textPrimary.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section header for grouped issues (e.g., "Critical", "High").
class IssueSectionHeader extends StatelessWidget {
  final String severity;
  final int count;

  const IssueSectionHeader({
    super.key,
    required this.severity,
    required this.count,
  });

  String get _label {
    switch (severity) {
      case 'critical':
        return 'Critical';
      case 'error':
        return 'High';
      case 'warning':
        return 'Medium';
      case 'info':
        return 'Low';
      default:
        return severity;
    }
  }

  Color get _color => CodeReviewTheme.severityColor(severity);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CodeReviewTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
