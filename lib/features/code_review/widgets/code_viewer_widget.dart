import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/code_review_theme.dart';
import 'copy_button.dart';

/// Dark code display container with line numbers, header bar, and copy.
class CodeViewerWidget extends StatelessWidget {
  final String code;
  final String language;
  final List<int> changedLines;
  final bool hasCopied;
  final VoidCallback onCopy;
  final bool isFixed;

  const CodeViewerWidget({
    super.key,
    required this.code,
    required this.language,
    this.changedLines = const [],
    this.hasCopied = false,
    required this.onCopy,
    this.isFixed = false,
  });

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: CodeReviewTheme.codeBlockDecoration,
      child: Column(
        children: [
          // Header bar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: CodeReviewTheme.codeHeaderBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Language indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: CodeReviewTheme.accentIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: CodeReviewTheme.accentIndigo,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Filename
                Text(
                  isFixed ? 'corrected_code' : 'original_code',
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: CodeReviewTheme.textMuted,
                  ),
                ),
                const Spacer(),
                // Copy button
                CopyButton(hasCopied: hasCopied, onPressed: onCopy),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: CodeReviewTheme.borderSubtle),

          // Code content with line numbers
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(lines.length, (index) {
                      final lineNum = index + 1;
                      final isChanged = changedLines.contains(lineNum);

                      return Container(
                        color: isChanged
                            ? (isFixed
                                  ? CodeReviewTheme.accentSuccess.withValues(
                                      alpha: 0.06,
                                    )
                                  : CodeReviewTheme.accentError.withValues(
                                      alpha: 0.06,
                                    ))
                            : null,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Line number
                            SizedBox(
                              width: 48,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(
                                  '$lineNum',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 13,
                                    color: isChanged
                                        ? CodeReviewTheme.textSecondary
                                        : CodeReviewTheme.textMuted.withValues(
                                            alpha: 0.5,
                                          ),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),

                            // Change indicator
                            if (isChanged)
                              Container(
                                width: 3,
                                height: 20,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isFixed
                                      ? CodeReviewTheme.accentSuccess
                                      : CodeReviewTheme.accentError,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                            else
                              const SizedBox(width: 11),

                            // Code text
                            Text(
                              lines[index],
                              style: GoogleFonts.firaCode(
                                fontSize: 13,
                                color: isChanged
                                    ? CodeReviewTheme.textPrimary
                                    : CodeReviewTheme.textPrimary.withValues(
                                        alpha: 0.75,
                                      ),
                                height: 1.6,
                                fontWeight: isChanged
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // Footer with line count
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: CodeReviewTheme.codeHeaderBg.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${lines.length} lines',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: CodeReviewTheme.textMuted,
                  ),
                ),
                if (changedLines.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CodeReviewTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${changedLines.length} changed',
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: isFixed
                          ? CodeReviewTheme.accentSuccess
                          : CodeReviewTheme.accentError,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
