import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 7-axis radar chart for skill balance visualization.
///
/// Displays: grammar, pronunciation, spelling, reading, writing, listening, speaking.
class SkillRadarChart extends StatelessWidget {
  final double grammar;
  final double pronunciation;
  final double spelling;
  final double reading;
  final double writing;
  final double listening;
  final double speaking;
  final double maxValue;

  const SkillRadarChart({
    super.key,
    required this.grammar,
    required this.pronunciation,
    required this.spelling,
    required this.reading,
    required this.writing,
    required this.listening,
    required this.speaking,
    this.maxValue = 100,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final values = [grammar, pronunciation, spelling, reading, writing, listening, speaking];
    final labels = ['Grammar', 'Pronunciation', 'Spelling', 'Reading', 'Writing', 'Listening', 'Speaking'];

    return CustomPaint(
      size: const Size(double.infinity, 250),
      painter: _RadarPainter(
        values: values,
        labels: labels,
        maxValue: maxValue,
        isDark: isDark,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxValue;
  final bool isDark;

  _RadarPainter({
    required this.values,
    required this.labels,
    required this.maxValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final sides = values.length;
    final angle = 2 * pi / sides;

    // Draw grid rings
    for (int ring = 1; ring <= 4; ring++) {
      final ringRadius = radius * ring / 4;
      final ringPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final ringPath = Path();
      for (int i = 0; i <= sides; i++) {
        final idx = i % sides;
        final x = center.dx + ringRadius * cos(angle * idx - pi / 2);
        final y = center.dy + ringRadius * sin(angle * idx - pi / 2);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, ringPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * cos(angle * i - pi / 2);
      final y = center.dy + radius * sin(angle * i - pi / 2);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // Draw data polygon
    final dataPath = Path();
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i <= sides; i++) {
      final idx = i % sides;
      final value = (values[idx] / maxValue).clamp(0.0, 1.0);
      final x = center.dx + radius * value * cos(angle * idx - pi / 2);
      final y = center.dy + radius * value * sin(angle * idx - pi / 2);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw data points
    for (int i = 0; i < sides; i++) {
      final value = (values[i] / maxValue).clamp(0.0, 1.0);
      final x = center.dx + radius * value * cos(angle * i - pi / 2);
      final y = center.dy + radius * value * sin(angle * i - pi / 2);

      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = AppColors.primary,
      );
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = Colors.white,
      );
    }

    // Draw labels
    for (int i = 0; i < sides; i++) {
      final labelRadius = radius + 20;
      final x = center.dx + labelRadius * cos(angle * i - pi / 2);
      final y = center.dy + labelRadius * sin(angle * i - pi / 2);

      final textSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textX = x - textPainter.width / 2;
      final textY = y - textPainter.height / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.values != values || old.isDark != isDark;
}
