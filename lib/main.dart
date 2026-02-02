import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'services/permission_service.dart';
import 'theme/app_theme.dart';
import 'views/interview_copilot_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ContentView(),
    );
  }
}

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  static const _channel = MethodChannel('interx/screen_capture');

  bool forceHideForShare = false;

  bool get _isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  bool get isHiding => forceHideForShare;

  @override
  void initState() {
    super.initState();

    // Wait until the first frame so macOS channel is registered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWindow();
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    if (!_isMacOS) return;

    // Add a small delay to ensure the app is fully initialized
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('=== Requesting macOS Permissions ===');

    try {
      // Request microphone first
      final micStatus = await PermissionService.requestMicrophonePermission();
      debugPrint('Microphone: $micStatus');

      // Check speech recognition status first (don't request yet)
      final speechCheckStatus =
          await PermissionService.checkSpeechRecognitionPermission();
      debugPrint('Speech Recognition Status: $speechCheckStatus');

      // Don't request speech recognition for now to avoid crash
      debugPrint(
        'Note: Please grant Speech Recognition permission manually in System Settings > Privacy & Security > Speech Recognition',
      );
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _syncWindow() async {
    if (!_isMacOS) return;
    try {
      await _channel.invokeMethod('setHidden', isHiding);
    } on MissingPluginException {
      // Ignore if platform channel isn't ready (or not running on macOS).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('interx'),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() {
                forceHideForShare = !forceHideForShare;
              });
              await _syncWindow();
            },
            child: Text(
              isHiding ? 'Show' : 'Hide for Share',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isHiding ? _hiddenView() : _contentView(),
      ),
    );
  }

  Widget _hiddenView() {
    return const InterviewCopilotView(key: ValueKey('hidden'));
  }

  Widget _contentView() {
    return const Center(
      key: ValueKey('content'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, size: 48),
          SizedBox(height: 12),
          Text('Hello, world!'),
        ],
      ),
    );
  }
}
