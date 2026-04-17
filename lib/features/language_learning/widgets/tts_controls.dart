import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../services/speech_service.dart';

/// Text-to-speech controls with speak button, speed toggle, and stop.
class TtsControls extends StatefulWidget {
  final String text;
  final SpeechService? speechService;
  final Color? accentColor;
  final bool compact;

  const TtsControls({
    super.key,
    required this.text,
    this.speechService,
    this.accentColor,
    this.compact = false,
  });

  @override
  State<TtsControls> createState() => _TtsControlsState();
}

class _TtsControlsState extends State<TtsControls>
    with SingleTickerProviderStateMixin {
  late SpeechService _speech;
  bool _isSpeaking = false;
  double _speed = 1.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechService ?? SpeechService();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Listen for when TTS finishes playing (either completion or cancel)
    _speech.onSpeechComplete = _onSpeechFinished;
  }

  @override
  void dispose() {
    // Stop any ongoing speech when this widget is removed
    if (_isSpeaking) {
      _speech.stopSpeaking();
    }
    _speech.onSpeechComplete = null;
    _pulseController.dispose();
    super.dispose();
  }

  /// Called by SpeechService when TTS playback completes or is cancelled.
  void _onSpeechFinished() {
    if (mounted) {
      setState(() => _isSpeaking = false);
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      // STOP the currently playing speech
      await _speech.stopSpeaking();
      setState(() => _isSpeaking = false);
      _pulseController.stop();
      _pulseController.reset();
      return;
    }

    // START speaking
    setState(() => _isSpeaking = true);
    _pulseController.repeat(reverse: true);

    await _speech.speak(widget.text, speed: _speed);
    // NOTE: speak() returns immediately — the onSpeechComplete callback
    // handles resetting state when the audio actually finishes.
  }

  void _cycleSpeed() {
    setState(() {
      if (_speed == 0.5) {
        _speed = 1.0;
      } else if (_speed == 1.0) {
        _speed = 1.5;
      } else {
        _speed = 0.5;
      }
    });
    _speech.setSpeed(_speed);
  }

  String get _speedLabel {
    if (_speed == 0.5) return 'Slow';
    if (_speed == 1.0) return 'Normal';
    return 'Fast';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.accentColor ?? AppColors.info;

    if (widget.compact) {
      return _buildCompact(isDark, color);
    }
    return _buildFull(isDark, color);
  }

  Widget _buildCompact(bool isDark, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _speak,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: _isSpeaking
                        ? 0.15 + _pulseController.value * 0.1
                        : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: color,
                  size: 20,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _cycleSpeed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _speedLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFull(bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Play/Stop button
          GestureDetector(
            onTap: _speak,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: _isSpeaking
                          ? 0.2 + _pulseController.value * 0.1
                          : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isSpeaking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: color,
                    size: 28,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSpeaking ? 'Playing...' : 'Listen',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                Text(
                  'Tap to hear pronunciation',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Speed controls
          _buildSpeedButton(0.5, 'Slow', isDark, color),
          const SizedBox(width: 6),
          _buildSpeedButton(1.0, '1x', isDark, color),
          const SizedBox(width: 6),
          _buildSpeedButton(1.5, 'Fast', isDark, color),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(
    double speed,
    String label,
    bool isDark,
    Color color,
  ) {
    final isActive = _speed == speed;
    return GestureDetector(
      onTap: () {
        setState(() => _speed = speed);
        _speech.setSpeed(speed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? color
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
