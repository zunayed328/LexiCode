import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wrapper service for Text-to-Speech and Speech-to-Text functionality.
///
/// Uses [flutter_tts] for TTS and [speech_to_text] for STT.
/// Provides platform-safe abstraction with graceful fallback
/// on platforms where native TTS/STT may not be available.
class SpeechService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  double _speechRate = 0.5; // 0.0 (slow) to 1.0 (fast)

  /// Callback invoked when speech playback completes or is cancelled.
  VoidCallback? onSpeechComplete;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;

  // ─── Initialization ───────────────────────────────────────────

  /// Initializes TTS and STT engines.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Register completion/cancel handlers so we know when speech ends
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeechComplete?.call();
      });
      _tts.setCancelHandler(() {
        _isSpeaking = false;
        onSpeechComplete?.call();
      });

      // Initialize STT (just checks availability)
      await _stt.initialize(
        onError: (error) => debugPrint('STT error: ${error.errorMsg}'),
        onStatus: (status) => debugPrint('STT status: $status'),
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('SpeechService init error: $e');
      _isInitialized = false;
    }
  }

  // ─── Text-to-Speech ───────────────────────────────────────────

  /// Speaks the given text aloud.
  Future<void> speak(String text, {double? speed}) async {
    if (!_isInitialized) await initialize();

    if (speed != null) {
      _speechRate = speed.clamp(0.0, 1.0);
      await _tts.setSpeechRate(_speechRate);
    }

    try {
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS error: $e');
    }
  }

  /// Stops any ongoing speech.
  Future<void> stopSpeaking() async {
    try {
      _isSpeaking = false;
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Sets the speech rate.
  /// [speed]: 0.0 = very slow, 0.5 = normal, 1.0 = fast
  Future<void> setSpeed(double speed) async {
    _speechRate = speed.clamp(0.0, 1.0);
    try {
      await _tts.setSpeechRate(_speechRate);
    } catch (e) {
      debugPrint('TTS setSpeed error: $e');
    }
  }

  // ─── Speech-to-Text ───────────────────────────────────────────

  /// Starts listening for speech input.
  ///
  /// [onResult] is called with the recognized text.
  /// [onListeningStateChanged] notifies when listening starts/stops.
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function(bool isListening)? onListeningStateChanged,
  }) async {
    if (!_isInitialized) await initialize();
    if (_isListening) return;

    try {
      final available = _stt.isAvailable;
      if (!available) {
        debugPrint('[STT] Speech recognition not available');
        return;
      }

      _isListening = true;
      onListeningStateChanged?.call(true);

      await _stt.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            onListeningStateChanged?.call(false);
          }
        },
        localeId: 'en_US',
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      _isListening = false;
      onListeningStateChanged?.call(false);
      debugPrint('STT error: $e');
    }
  }

  /// Stops listening for speech input.
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _stt.stop();
      _isListening = false;
    } catch (e) {
      debugPrint('STT stop error: $e');
    }
  }

  // ─── Platform Checks ─────────────────────────────────────────

  /// Checks if TTS is available on the current platform.
  Future<bool> isTtsAvailable() async {
    // TTS is generally available on mobile but not always on web
    return !kIsWeb;
  }

  /// Checks if STT is available on the current platform.
  Future<bool> isSttAvailable() async {
    if (kIsWeb) return false;
    if (!_isInitialized) await initialize();
    return _stt.isAvailable;
  }

  /// Returns supported TTS languages.
  Future<List<String>> getSupportedLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages is List) {
        return languages.map((l) => l.toString()).toList();
      }
    } catch (e) {
      debugPrint('getSupportedLanguages error: $e');
    }
    return ['en-US', 'en-GB', 'en-AU'];
  }

  /// Disposes resources.
  void dispose() {
    _tts.stop();
    _stt.stop();
    _isInitialized = false;
    _isListening = false;
  }
}
