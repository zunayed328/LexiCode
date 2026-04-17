import 'package:flutter/material.dart';

/// Centralized theme constants for the code result screen.
class CodeReviewTheme {
  CodeReviewTheme._();

  // ─── Background Colors ──────────────────────────────────────────
  static const Color primaryBg = Color(0xFF0D0D0D);
  static const Color secondaryBg = Color(0xFF1A1A1A);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color codeBg = Color(0xFF1E1E1E);
  static const Color codeHeaderBg = Color(0xFF282A36);

  // ─── Accent Colors ──────────────────────────────────────────────
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentSuccess = Color(0xFF10B981);
  static const Color accentError = Color(0xFFEF4444);
  static const Color accentWarning = Color(0xFFF59E0B);
  static const Color accentInfo = Color(0xFF3B82F6);

  // ─── Text Colors ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8F9FA);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // ─── Border Colors ──────────────────────────────────────────────
  static const Color border = Color(0xFF2D2D44);
  static const Color borderSubtle = Color(0x1AFFFFFF); // 10% white

  // ─── Severity Colors ────────────────────────────────────────────
  static Color severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return accentError;
      case 'high':
      case 'error':
        return const Color(0xFFFF6B47);
      case 'medium':
      case 'warning':
        return accentWarning;
      case 'low':
      case 'info':
        return accentInfo;
      default:
        return accentInfo;
    }
  }

  // ─── Gradients ──────────────────────────────────────────────────
  static const LinearGradient insightGradient = LinearGradient(
    colors: [Color(0xFF1A1035), Color(0xFF0F1A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient insightBorderGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentIndigo, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tabActiveGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shimmer Colors ─────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1E1E2E);
  static const Color shimmerHighlight = Color(0xFF2A2A3E);

  // ─── Shadows ────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accentIndigo.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── Decorations ────────────────────────────────────────────────
  static BoxDecoration get insightCardDecoration => BoxDecoration(
    gradient: insightGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: accentPurple.withValues(alpha: 0.25)),
    boxShadow: glowShadow,
  );

  static BoxDecoration get codeBlockDecoration => BoxDecoration(
    color: codeBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderSubtle),
    boxShadow: cardShadow,
  );
}
