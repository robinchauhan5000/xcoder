import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to handle macOS permissions for microphone and speech recognition
class PermissionService {
  static const _channel = MethodChannel('com.musicplayer/permissions');

  /// Check microphone permission status
  /// Returns: 'authorized', 'denied', or 'notDetermined'
  static Future<String> checkMicrophonePermission() async {
    if (!_isMacOS) return 'authorized';

    try {
      final result = await _channel.invokeMethod<String>(
        'checkMicrophonePermission',
      );
      return result ?? 'notDetermined';
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return 'notDetermined';
    }
  }

  /// Request microphone permission
  /// Returns: 'authorized' or 'denied'
  static Future<String> requestMicrophonePermission() async {
    if (!_isMacOS) return 'authorized';

    try {
      final result = await _channel.invokeMethod<String>(
        'requestMicrophonePermission',
      );
      return result ?? 'denied';
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      return 'denied';
    }
  }

  /// Check speech recognition permission status
  /// Returns: 'authorized', 'denied', or 'notDetermined'
  static Future<String> checkSpeechRecognitionPermission() async {
    if (!_isMacOS) return 'authorized';

    try {
      final result = await _channel.invokeMethod<String>(
        'checkSpeechRecognitionPermission',
      );
      return result ?? 'notDetermined';
    } catch (e) {
      debugPrint('Error checking speech recognition permission: $e');
      return 'notDetermined';
    }
  }

  /// Request speech recognition permission
  /// Returns: 'authorized', 'denied', or 'notDetermined'
  static Future<String> requestSpeechRecognitionPermission() async {
    if (!_isMacOS) return 'authorized';

    try {
      final result = await _channel.invokeMethod<String>(
        'requestSpeechRecognitionPermission',
      );
      return result ?? 'denied';
    } catch (e) {
      debugPrint('Error requesting speech recognition permission: $e');
      return 'denied';
    }
  }

  /// Request all required permissions (microphone + speech recognition)
  /// Returns a map with permission statuses
  static Future<Map<String, dynamic>> requestAllPermissions() async {
    if (!_isMacOS) {
      return {
        'microphone': 'authorized',
        'speechRecognition': 'authorized',
        'allGranted': true,
      };
    }

    try {
      final result = await _channel.invokeMethod<Map>('requestAllPermissions');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Error requesting all permissions: $e');
      return {
        'microphone': 'denied',
        'speechRecognition': 'denied',
        'allGranted': false,
      };
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    if (!_isMacOS) return true;

    final micStatus = await checkMicrophonePermission();
    final speechStatus = await checkSpeechRecognitionPermission();

    return micStatus == 'authorized' && speechStatus == 'authorized';
  }

  static bool get _isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
}
