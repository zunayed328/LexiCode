import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/code_review_theme.dart';

/// A copy-to-clipboard button that switches to a checkmark for 2 seconds.
class CopyButton extends StatelessWidget {
  final bool hasCopied;
  final VoidCallback onPressed;
  final bool compact;

  const CopyButton({
    super.key,
    required this.hasCopied,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        splashColor: CodeReviewTheme.accentIndigo.withValues(alpha: 0.15),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 4 : 6,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: hasCopied
                ? Row(
                    key: const ValueKey('copied'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: CodeReviewTheme.accentSuccess,
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 4),
                        Text(
                          'Copied!',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CodeReviewTheme.accentSuccess,
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    key: const ValueKey('copy'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.content_copy_rounded,
                        size: 14,
                        color: CodeReviewTheme.textSecondary,
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: CodeReviewTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
