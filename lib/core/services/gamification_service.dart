import 'package:flutter/material.dart';
import '../../shared/models/user_model.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int requiredXp;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.requiredXp = 0,
  });
}

class GamificationService {
  static const int xpPerLesson = 15;
  static const int xpPerCodeReview = 25;
  static const int xpPerPractice = 10;
  static const int xpStreakBonus = 5;
  static const int dailyGoalXp = 50;

  static final List<Achievement> allAchievements = [
    const Achievement(
      id: 'first_review',
      title: 'First Review',
      description: 'Complete your first code review',
      icon: Icons.rate_review_rounded,
      color: Color(0xFF6C63FF),
      isUnlocked: true,
      requiredXp: 0,
    ),
    const Achievement(
      id: 'first_lesson',
      title: 'Word Warrior',
      description: 'Complete your first English lesson',
      icon: Icons.school_rounded,
      color: Color(0xFF58CC02),
      isUnlocked: true,
      requiredXp: 0,
    ),
    const Achievement(
      id: 'week_streak',
      title: '7-Day Streak',
      description: 'Maintain a 7-day learning streak',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF9600),
      requiredXp: 100,
    ),
    const Achievement(
      id: 'code_master',
      title: 'Code Master',
      description: 'Review 50 code snippets',
      icon: Icons.code_rounded,
      color: Color(0xFF00D2FF),
      requiredXp: 500,
    ),
    const Achievement(
      id: 'polyglot',
      title: 'Polyglot Dev',
      description: 'Review code in 5 different languages',
      icon: Icons.translate_rounded,
      color: Color(0xFFFF6584),
      requiredXp: 300,
    ),
    const Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Get a perfect score on 10 lessons',
      icon: Icons.star_rounded,
      color: Color(0xFFFFD700),
      requiredXp: 400,
    ),
    const Achievement(
      id: 'mentor',
      title: 'AI Mentor Friend',
      description: 'Have 100 conversations with AI mentor',
      icon: Icons.smart_toy_rounded,
      color: Color(0xFF8B5CF6),
      requiredXp: 600,
    ),
    const Achievement(
      id: 'documenter',
      title: 'Documentation Hero',
      description: 'Complete all documentation writing lessons',
      icon: Icons.description_rounded,
      color: Color(0xFF10B981),
      requiredXp: 800,
    ),
  ];

  UserModel addXp(UserModel user, int xp) {
    int newXp = user.xp + xp;
    int newLevel = user.level;

    while (newXp >= newLevel * 500) {
      newXp -= newLevel * 500;
      newLevel++;
    }

    return user.copyWith(xp: newXp, level: newLevel);
  }

  UserModel incrementStreak(UserModel user) {
    final now = DateTime.now();
    final lastActive = user.lastActiveDate;
    final difference = now.difference(lastActive).inDays;

    if (difference == 1) {
      return user.copyWith(
        streak: user.streak + 1,
        lastActiveDate: now,
      );
    } else if (difference > 1) {
      return user.copyWith(streak: 1, lastActiveDate: now);
    }

    return user.copyWith(lastActiveDate: now);
  }

  List<Achievement> getUnlockedAchievements(UserModel user) {
    return allAchievements
        .where((a) => a.isUnlocked || user.xp >= a.requiredXp)
        .toList();
  }

  double getDailyProgress(int todayXp) {
    return (todayXp / dailyGoalXp).clamp(0.0, 1.0);
  }
}
