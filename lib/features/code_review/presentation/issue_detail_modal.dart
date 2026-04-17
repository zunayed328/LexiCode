import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/code_review_model.dart';

/// Bottom sheet showing full issue detail with severity, code snippets,
/// explanation, fix example, pro tip, and related vocabulary.
class IssueDetailModal extends StatelessWidget {
  final CodeIssue issue;
  final String language;

  const IssueDetailModal({
    super.key,
    required this.issue,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Icon(
                      issue.severityIcon,
                      color: issue.severityColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        issue.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    // Badges row
                    Row(
                      children: [
                        _badge(
                          'Severity',
                          issue.severityLabel,
                          issue.severityColor,
                        ),
                        const SizedBox(width: 8),
                        _badge('Type', issue.typeLabel, issue.typeColor),
                        if (issue.lineNumber != null) ...[
                          const SizedBox(width: 8),
                          _badge('Line', '${issue.lineNumber}', Colors.grey),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Your Code section
                    if (issue.lineNumber != null) ...[
                      _sectionHeader('❌ Your Code', isDark),
                      const SizedBox(height: 8),
                      _codeBlock(
                        issue.codeExample ??
                            'Line ${issue.lineNumber}: [code at this line]',
                        const Color(0xFFFF4757),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // What's Wrong
                    _sectionHeader('📖 What\'s Wrong?', isDark),
                    const SizedBox(height: 8),
                    Text(
                      issue.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Why This Matters
                    if (issue.explanation != null) ...[
                      _sectionHeader('🎯 Why This Matters', isDark),
                      const SizedBox(height: 8),
                      Text(
                        issue.explanation!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // How to Fix
                    _sectionHeader('✅ How to Fix', isDark),
                    const SizedBox(height: 8),
                    if (issue.suggestion != null)
                      Text(
                        issue.suggestion!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (issue.exampleFix != null)
                      _codeBlock(issue.exampleFix!, const Color(0xFF00D68F)),

                    // Pro Tip
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 Pro Tip',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            issue.simpleExplanation,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(context, '📋 Copy Fix', () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    issue.exampleFix ?? issue.suggestion ?? '',
                              ),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Fix copied to clipboard!'),
                                backgroundColor: const Color(0xFF00D68F),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _codeBlock(String code, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        code,
        style: GoogleFonts.firaCode(
          fontSize: 12,
          color: AppColors.darkText,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
