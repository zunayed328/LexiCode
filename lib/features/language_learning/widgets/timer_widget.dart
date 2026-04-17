import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Countdown timer widget with circular display and warning thresholds.
class TimerWidget extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback? onTimeUp;
  final int warningThresholdSeconds;
  final bool autoStart;
  final double size;
  final Color? color;

  const TimerWidget({
    super.key,
    required this.totalSeconds,
    this.onTimeUp,
    this.warningThresholdSeconds = 60,
    this.autoStart = true,
    this.size = 80,
    this.color,
  });

  @override
  State<TimerWidget> createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _pulseController;

  int get remaining => _remaining;
  bool get isRunning => _isRunning;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    if (widget.autoStart) start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
        if (_remaining <= widget.warningThresholdSeconds &&
            _remaining > 0 &&
            _remaining % 10 == 0) {
          _pulseController.forward().then((_) => _pulseController.reverse());
        }
      } else {
        _timer?.cancel();
        _isRunning = false;
        widget.onTimeUp?.call();
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    setState(() {});
  }

  void reset() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.totalSeconds;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWarning = _remaining <= widget.warningThresholdSeconds;
    final color = isWarning
        ? AppColors.error
        : (widget.color ?? AppColors.info);
    final progress = _remaining / widget.totalSeconds;
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.05;
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(
                  isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            // Progress circle
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: progress, end: progress),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation(color),
                  );
                },
              ),
            ),
            // Time text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: widget.size * 0.2,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (isWarning)
                  Text(
                    'Hurry!',
                    style: GoogleFonts.inter(
                      fontSize: widget.size * 0.1,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
