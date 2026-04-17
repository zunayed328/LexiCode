import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.gradient,
    this.onTap,
    this.borderRadius = 20,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient:
              gradient ??
              LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkCard.withValues(alpha: 0.8),
                        AppColors.darkSurface.withValues(alpha: 0.6),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color:
                borderColor ??
                (isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.5)
                    : AppColors.lightBorder.withValues(alpha: 0.5)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
