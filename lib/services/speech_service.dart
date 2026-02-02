import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

/// Service to handle speech-to-text functionality
///
/// On macOS, the speech_to_text package handles permissions internally.
/// When you call initialize(), it will automatically request microphone
/// and speech recognition permissions if needed.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Initialize speech recognition and request permissions
  ///
  /// On macOS, this will trigger system permission dialogs automatically
  /// if permissions haven't been granted yet.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('=== Starting Speech Service Initialization ===');
      debugPrint('Platform: ${defaultTargetPlatform.name}');

      // The speech_to_text package handles permissions internally on macOS
      // It will show system dialogs when needed
      debugPrint('Initializing speech recognition...');
      debugPrint('(System will request permissions if needed)');

      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('❌ Speech recognition error: ${error.errorMsg}');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        debugPrint('✅ Speech recognition initialized successfully');

        // Log available locales
        try {
          final locales = await _speech.locales();
          debugPrint('Available locales: ${locales.length}');
          if (locales.isNotEmpty) {
            debugPrint('System locale: ${locales.first.localeId}');
          }
        } catch (e) {
          debugPrint('Could not get locales: $e');
        }
      } else {
        debugPrint('❌ Failed to initialize speech recognition');
        debugPrint('Possible reasons:');
        debugPrint('  1. Microphone permission was denied');
        debugPrint('  2. Speech recognition permission was denied');
        debugPrint('  3. No microphone is connected');
        debugPrint('  4. Speech recognition is not available on this device');
        debugPrint('');
        debugPrint('To fix:');
        debugPrint(
          '  1. Check System Settings → Privacy & Security → Microphone',
        );
        debugPrint(
          '  2. Check System Settings → Privacy & Security → Speech Recognition',
        );
        debugPrint('  3. Ensure "music" is enabled in both sections');
        debugPrint('  4. Restart the app');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Error initializing speech service: $e');
      return false;
    }
  }

  /// Start listening and convert speech to text
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      debugPrint('Speech service not initialized, initializing now...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Cannot start listening: Speech service not initialized');
        return;
      }
    }

    if (_isListening) {
      debugPrint('Already listening');
      return;
    }

    try {
      _isListening = true;
      debugPrint('Starting to listen...');

      await _speech.listen(
        onResult: (result) {
          debugPrint(
            'Speech result: ${result.recognizedWords} (final: ${result.finalResult})',
          );
          if (result.finalResult) {
            onResult(result.recognizedWords);
            _isListening = false;
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
      debugPrint('✅ Started listening...');
    } catch (e) {
      debugPrint('❌ Error starting speech recognition: $e');
      _isListening = false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      await _speech.stop();
      debugPrint('Stopped listening');
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      await _speech.cancel();
      debugPrint('Cancelled listening');
    } catch (e) {
      debugPrint('Error cancelling speech recognition: $e');
    }
  }

  /// Get available locales for speech recognition
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Check if speech recognition is available on this device
  Future<bool> isAvailable() async {
    try {
      return await _speech.initialize();
    } catch (e) {
      debugPrint('Speech recognition not available: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _isListening = false;
  }
}
