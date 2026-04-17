import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/constants/app_colors.dart';

class XpProgressRing extends StatelessWidget {
  final int currentXp;
  final int maxXp;
  final int level;
  final double size;
  final double lineWidth;
  final bool showLabel;

  const XpProgressRing({
    super.key,
    required this.currentXp,
    required this.maxXp,
    required this.level,
    this.size = 80,
    this.lineWidth = 8,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: lineWidth,
      percent: progress,
      animation: true,
      animationDuration: 1200,
      circularStrokeCap: CircularStrokeCap.round,
      linearGradient: AppColors.primaryGradient,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBorder
          : AppColors.lightBorder,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          if (showLabel)
            Text(
              '$currentXp/$maxXp',
              style: TextStyle(
                fontSize: size * 0.11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
        ],
      ),
    );
  }
}
