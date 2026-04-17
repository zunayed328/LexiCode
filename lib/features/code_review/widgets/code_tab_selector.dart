import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/code_review_theme.dart';

/// Segmented tab selector for toggling between Original and Corrected code.
class CodeTabSelector extends StatelessWidget {
  final int selectedTab;
  final int issueCount;
  final ValueChanged<int> onTabSelected;

  const CodeTabSelector({
    super.key,
    required this.selectedTab,
    required this.issueCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CodeReviewTheme.secondaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CodeReviewTheme.borderSubtle),
      ),
      child: Row(
        children: [
          _buildTab(
            index: 0,
            label: 'Original Code',
            icon: Icons.code_rounded,
            badge: issueCount > 0 ? '$issueCount' : null,
            badgeColor: CodeReviewTheme.accentError,
          ),
          const SizedBox(width: 4),
          _buildTab(
            index: 1,
            label: 'Corrected Code',
            icon: Icons.check_circle_outline_rounded,
            checkmark: true,
            badgeColor: CodeReviewTheme.accentSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
    String? badge,
    bool checkmark = false,
    Color? badgeColor,
  }) {
    final isActive = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? CodeReviewTheme.tabActiveGradient : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: CodeReviewTheme.accentIndigo.withValues(
                        alpha: 0.25,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : CodeReviewTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : CodeReviewTheme.textMuted,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.2)
                        : (badgeColor ?? CodeReviewTheme.accentError)
                              .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : badgeColor ?? CodeReviewTheme.accentError,
                    ),
                  ),
                ),
              ],
              if (checkmark && isActive) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
