import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);

  // Secondary Colors
  static const Color secondary = Color(0xFFFF6584);
  static const Color secondaryLight = Color(0xFFFF8FA5);
  static const Color secondaryDark = Color(0xFFE84A6A);

  // Accent Colors
  static const Color accent = Color(0xFF00D2FF);
  static const Color accentGreen = Color(0xFF58CC02);
  static const Color accentOrange = Color(0xFFFF9600);
  static const Color accentGold = Color(0xFFFFD700);

  // Light Theme
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFF3F4F6);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkText = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF2D2D44);
  static const Color darkDivider = Color(0xFF232340);

  // Status Colors
  static const Color success = Color(0xFF58CC02);
  static const Color warning = Color(0xFFFF9600);
  static const Color error = Color(0xFFFF4B4B);
  static const Color info = Color(0xFF1CB0F6);

  // Gamification Colors
  static const Color xpColor = Color(0xFFFFD700);
  static const Color streakColor = Color(0xFFFF9600);
  static const Color levelColor = Color(0xFF6C63FF);
  static const Color badgeColor = Color(0xFF58CC02);

  // Code Review Colors
  static const Color codeBackground = Color(0xFF1E1E2E);
  static const Color codeSurface = Color(0xFF282A36);
  static const Color codeGreen = Color(0xFF50FA7B);
  static const Color codeRed = Color(0xFFFF5555);
  static const Color codeYellow = Color(0xFFF1FA8C);
  static const Color codePurple = Color(0xFFBD93F9);
  static const Color codeBlue = Color(0xFF8BE9FD);
  static const Color codeOrange = Color(0xFFFFB86C);

  // Auth Colors
  static const Color inputBackground = Color(0xFFF5F6FA);
  static const Color textPrimary = Color(0xFF2E3A59);
  static const Color textSecondary = Color(0xFF7C8DB0);
  static const Color accentGreenAuth = Color(0xFF00D68F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient authGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6), Color(0xFFFF6584)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF8FA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
