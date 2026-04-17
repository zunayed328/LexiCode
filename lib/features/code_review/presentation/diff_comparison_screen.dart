import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/code_review_model.dart';

/// Diff comparison screen showing original vs fixed code side by side.
///
/// Green lines = added, yellow = modified, red = removed.
class DiffComparisonScreen extends StatelessWidget {
  final CodeReviewResult result;

  const DiffComparisonScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final originalLines = result.originalCode.split('\n');
    final fixedLines = result.fixedCode.split('\n');

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Code Comparison', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('Original vs Fixed · ${result.language}',
                      style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ]),
              ),
            ]),
          ),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
            ),
            child: Row(children: [
              Expanded(
                child: Row(children: [
                  const Icon(Icons.remove_circle_outline_rounded, size: 16, color: Color(0xFFFF4757)),
                  const SizedBox(width: 6),
                  Text('BEFORE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFFF4757))),
                ]),
              ),
              Container(width: 1, height: 20, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('AFTER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF00D68F))),
                  const SizedBox(width: 6),
                  const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF00D68F)),
                ]),
              ),
            ]),
          ),

          // Diff view
          Expanded(
            child: Container(
              color: AppColors.codeBackground,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Unified diff — show all fixed lines, highlight changes
                    ...List.generate(fixedLines.length, (i) {
                      final originalLine = i < originalLines.length ? originalLines[i] : '';
                      final fixedLine = fixedLines[i];
                      final isModified = originalLine != fixedLine;
                      final isAdded = i >= originalLines.length;
                      final isChanged = result.changedLines.contains(i + 1);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                          color: isAdded
                              ? const Color(0xFF00D68F).withValues(alpha: 0.08)
                              : isModified || isChanged
                                  ? const Color(0xFFFFB800).withValues(alpha: 0.08)
                                  : null,
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Original side
                          Expanded(
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  i < originalLines.length ? '${i + 1}' : '',
                                  style: GoogleFonts.firaCode(
                                    fontSize: 11,
                                    color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              if (isModified && !isAdded)
                                const Text('- ', style: TextStyle(fontSize: 12, color: Color(0xFFFF4757), fontWeight: FontWeight.w700)),
                              Expanded(
                                child: Text(
                                  originalLine,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 11,
                                    color: isModified ? const Color(0xFFFF4757) : AppColors.darkText.withValues(alpha: 0.7),
                                    decoration: isModified ? TextDecoration.lineThrough : null,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                          // Divider
                          Container(
                            width: 1, height: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            color: AppColors.darkBorder.withValues(alpha: 0.3),
                          ),
                          // Fixed side
                          Expanded(
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.firaCode(
                                    fontSize: 11,
                                    color: AppColors.darkTextSecondary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              if (isModified || isAdded)
                                Text(
                                  isAdded ? '+ ' : '~ ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isAdded ? const Color(0xFF00D68F) : const Color(0xFFFFB800),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  fixedLine,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 11,
                                    color: isAdded
                                        ? const Color(0xFF00D68F)
                                        : isModified
                                            ? const Color(0xFFFFB800)
                                            : AppColors.darkText.withValues(alpha: 0.7),
                                    fontWeight: (isModified || isAdded) ? FontWeight.w600 : FontWeight.w400,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ]),
                      );
                    }),
                    // Handle extra original lines (deleted)
                    if (originalLines.length > fixedLines.length)
                      ...List.generate(originalLines.length - fixedLines.length, (i) {
                        final idx = fixedLines.length + i;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFFF4757).withValues(alpha: 0.08)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                SizedBox(
                                  width: 28,
                                  child: Text('${idx + 1}', style: GoogleFonts.firaCode(fontSize: 11, color: AppColors.darkTextSecondary.withValues(alpha: 0.5))),
                                ),
                                const Text('- ', style: TextStyle(fontSize: 12, color: Color(0xFFFF4757), fontWeight: FontWeight.w700)),
                                Expanded(
                                  child: Text(
                                    originalLines[idx],
                                    style: GoogleFonts.firaCode(fontSize: 11, color: const Color(0xFFFF4757), decoration: TextDecoration.lineThrough, height: 1.6),
                                  ),
                                ),
                              ]),
                            ),
                            Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 4), color: AppColors.darkBorder.withValues(alpha: 0.3)),
                            const Expanded(child: SizedBox()),
                          ]),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _legendItem('Added', const Color(0xFF00D68F)),
              const SizedBox(width: 16),
              _legendItem('Modified', const Color(0xFFFFB800)),
              const SizedBox(width: 16),
              _legendItem('Removed', const Color(0xFFFF4757)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3), border: Border.all(color: color, width: 1.5))),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    ]);
  }
}
