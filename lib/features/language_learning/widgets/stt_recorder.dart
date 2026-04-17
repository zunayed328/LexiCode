import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../services/speech_service.dart';

/// Speech-to-text recorder with mic button, waveform, and timer.
class SttRecorder extends StatefulWidget {
  final SpeechService? speechService;
  final ValueChanged<String> onResult;
  final ValueChanged<bool>? onListeningChanged;
  final Color? accentColor;
  final int? maxDurationSeconds;

  const SttRecorder({
    super.key,
    this.speechService,
    required this.onResult,
    this.onListeningChanged,
    this.accentColor,
    this.maxDurationSeconds,
  });

  @override
  State<SttRecorder> createState() => _SttRecorderState();
}

class _SttRecorderState extends State<SttRecorder>
    with TickerProviderStateMixin {
  late SpeechService _speech;
  bool _isListening = false;
  String _recognizedText = '';
  int _recordingSeconds = 0;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechService ?? SpeechService();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    if (_isListening) _speech.stopListening();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isListening) {
      await _speech.stopListening();
      _pulseController.stop();
      _waveController.stop();
      setState(() => _isListening = false);
      widget.onListeningChanged?.call(false);
      if (_recognizedText.isNotEmpty) {
        widget.onResult(_recognizedText);
      }
    } else {
      setState(() {
        _recognizedText = '';
        _recordingSeconds = 0;
        _isListening = true;
      });
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      widget.onListeningChanged?.call(true);

      _startTimer();

      await _speech.startListening(
        onResult: (text) {
          setState(() => _recognizedText = text);
        },
        onListeningStateChanged: (listening) {
          if (!listening && mounted) {
            setState(() => _isListening = false);
            _pulseController.stop();
            _waveController.stop();
            widget.onListeningChanged?.call(false);
            if (_recognizedText.isNotEmpty) {
              widget.onResult(_recognizedText);
            }
          }
        },
      );
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isListening) return false;
      setState(() => _recordingSeconds++);

      if (widget.maxDurationSeconds != null &&
          _recordingSeconds >= widget.maxDurationSeconds!) {
        _toggleRecording();
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.accentColor ?? AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isListening
              ? color.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: _isListening ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Waveform visualization
          if (_isListening) ...[
            SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 60),
                    painter: _WaveformPainter(
                      progress: _waveController.value,
                      color: color,
                      isActive: _isListening,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Mic button
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isListening
                    ? 1.0 + _pulseController.value * 0.08
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: _isListening
                          ? LinearGradient(
                              colors: [color, color.withValues(alpha: 0.8)],
                            )
                          : null,
                      color: _isListening
                          ? null
                          : color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      boxShadow: _isListening
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isListening ? Colors.white : color,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Timer
          if (_isListening) ...[
            Text(
              _formatTimer(_recordingSeconds),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (widget.maxDurationSeconds != null)
              Text(
                'Max ${widget.maxDurationSeconds}s',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
          ] else ...[
            Text(
              'Tap to record',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],

          // Recognized text
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You said:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recognizedText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isActive;

  _WaveformPainter({
    required this.progress,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final random = Random(42);
    final barCount = 30;
    final barWidth = size.width / (barCount * 2);

    for (int i = 0; i < barCount; i++) {
      final x = i * (size.width / barCount) + barWidth / 2;
      final heightFactor = isActive
          ? (0.3 +
                random.nextDouble() *
                    0.7 *
                    sin((progress * pi * 4) + (i * pi / barCount)).abs())
          : 0.15;
      final barHeight = size.height * heightFactor;
      final y = (size.height - barHeight) / 2;

      canvas.drawLine(Offset(x, y), Offset(x, y + barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.isActive != isActive;
}
