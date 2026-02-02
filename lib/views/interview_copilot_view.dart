import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/interview_category.dart';
import '../models/interview_response.dart';
import '../services/interview_service.dart';
import '../services/permission_service.dart';
import '../services/speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/interview_copilot_chat_area.dart';
import '../widgets/interview_copilot_header.dart';
import '../widgets/interview_copilot_input_bar.dart';

/// Full Interview Copilot screen with header, chat area, and input bar.
class InterviewCopilotView extends StatefulWidget {
  const InterviewCopilotView({super.key});

  @override
  State<InterviewCopilotView> createState() => _InterviewCopilotViewState();
}

class _InterviewCopilotViewState extends State<InterviewCopilotView> {
  final _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late InterviewService _interviewService;
  late SpeechService _speechService;
  bool _isLoading = false;
  bool _isHeaderMicListening = false;
  bool _isInputMicListening = false;
  bool _useStreaming = true; // Enable streaming by default
  AIProvider _currentProvider = AIProvider.openai;
  InterviewCategory _currentCategory = InterviewCategory.normal;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _speechService = SpeechService();
    _checkPermissionsAndInitializeSpeech();
  }

  Future<void> _checkPermissionsAndInitializeSpeech() async {
    debugPrint('Checking permissions before initializing speech...');

    // Check if permissions are already granted
    final hasPermissions = await PermissionService.hasAllPermissions();

    if (!hasPermissions) {
      debugPrint('Permissions not granted, requesting...');
      final permissions = await PermissionService.requestAllPermissions();

      if (permissions['allGranted'] != true) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      }
    }

    // Permissions granted, initialize speech service
    await _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    debugPrint('Initializing speech service...');
    final initialized = await _speechService.initialize();
    if (!initialized) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    } else {
      debugPrint('✅ Speech service initialized successfully');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app requires microphone and speech recognition permissions to function.\n\n'
          'To enable:\n'
          '1. Open System Settings\n'
          '2. Go to Privacy & Security\n'
          '3. Enable Microphone access for "musicplayer"\n'
          '4. Enable Speech Recognition for "musicplayer"\n'
          '5. Restart the app',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _initializeService() {
    try {
      _interviewService = InterviewService(provider: _currentProvider);
    } catch (e) {
      debugPrint('Failed to initialize InterviewService: $e');
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _switchProvider(AIProvider provider) {
    if (_currentProvider == provider || _isLoading) return;

    setState(() {
      _currentProvider = provider;
      _messages.add(
        AssistantChatMessage(
          text: 'Switched to ${provider.name.toUpperCase()} AI',
        ),
      );
    });

    _initializeService();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(UserChatMessage(text: text, showDetected: true));
      _isLoading = true;
    });

    _inputController.clear();

    try {
      if (_useStreaming) {
        // Streaming mode with structured sections
        final stream = await _interviewService.askQuestionStream(
          text,
          category: _currentCategory,
        );

        setState(() {
          _messages.add(
            StreamingAssistantMessage(
              responseStream: stream,
              onComplete: (finalResponse) {
                // Replace streaming message with final message
                setState(() {
                  final index = _messages.length - 1;
                  if (index >= 0 &&
                      _messages[index] is StreamingAssistantMessage) {
                    _messages[index] = _buildResponseMessage(finalResponse);
                  }
                  _isLoading = false;
                });
              },
            ),
          );
        });
      } else {
        // Non-streaming mode (original behavior)
        final response = await _interviewService.askQuestion(
          text,
          category: _currentCategory,
        );
        setState(() {
          _messages.add(_buildResponseMessage(response));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(AssistantChatMessage(text: 'Error: ${e.toString()}'));
        _isLoading = false;
      });
    }
  }

  void _copyAllMessages() {
    final buffer = StringBuffer();
    buffer.writeln('=== INTERVIEW COPILOT CHAT TRANSCRIPT ===\n');

    for (final message in _messages) {
      if (message is UserChatMessage) {
        buffer.writeln('USER:');
        buffer.writeln(message.text);
        buffer.writeln();
      } else if (message is AssistantChatMessage) {
        buffer.writeln('ASSISTANT:');
        buffer.writeln(message.text);
        buffer.writeln();
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All messages copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.accentPurple,
      ),
    );
  }

  /// Toggle header microphone (sends directly to AI)
  Future<void> _toggleHeaderMic() async {
    if (_isLoading) return;

    if (_isHeaderMicListening) {
      // Stop listening
      await _speechService.stopListening();
      setState(() => _isHeaderMicListening = false);
    } else {
      // Start listening
      setState(() => _isHeaderMicListening = true);
      await _speechService.startListening(
        onResult: (text) {
          setState(() => _isHeaderMicListening = false);
          if (text.isNotEmpty) {
            _sendMessage(text);
          }
        },
        onPartialResult: (text) {
          // Show partial results in a temporary message
          debugPrint('Partial: $text');
        },
      );
    }
  }

  /// Toggle input microphone (appends to text field)
  Future<void> _toggleInputMic() async {
    if (_isInputMicListening) {
      // Stop listening
      await _speechService.stopListening();
      setState(() => _isInputMicListening = false);
    } else {
      // Start listening
      final currentText = _inputController.text;
      setState(() => _isInputMicListening = true);
      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _isInputMicListening = false;
            // Append new text to existing text with a space
            if (currentText.isNotEmpty) {
              _inputController.text = '$currentText $text';
            } else {
              _inputController.text = text;
            }
          });
        },
        onPartialResult: (text) {
          // Update text field with partial results (appended)
          setState(() {
            if (currentText.isNotEmpty) {
              _inputController.text = '$currentText $text';
            } else {
              _inputController.text = text;
            }
          });
        },
      );
    }
  }

  ChatMessage _buildResponseMessage(InterviewResponse response) {
    final buffer = StringBuffer();
    final useTitles = response.sections.any((s) => s.type.isSystemDesign);

    for (final section in response.sections) {
      if (useTitles) {
        buffer.writeln('**${section.type.title}**');
      }
      _appendSectionContent(buffer, section, useTitles: useTitles);
    }

    return AssistantChatMessage(text: buffer.toString().trim());
  }

  void _appendSectionContent(
    StringBuffer buffer,
    ResponseSection section, {
    required bool useTitles,
  }) {
    if (section.type.isCode) {
      buffer.writeln('```${section.language ?? ''}');
      buffer.writeln(section.content);
      buffer.writeln('```');
      buffer.writeln();
      return;
    }

    final items = _normalizeContent(section.content);
    if (items.isEmpty) {
      return;
    }

    final forceBullets =
        useTitles || section.type == SectionType.details || items.length > 1;

    if (forceBullets) {
      for (final item in items) {
        buffer.writeln('- $item');
      }
      buffer.writeln();
      return;
    }

    buffer.writeln(items.first);
    buffer.writeln();
  }

  List<String> _normalizeContent(dynamic content) {
    if (content == null) return const [];
    if (content is List) {
      return content.map((item) => item.toString()).toList();
    }
    return [content.toString()];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          children: [
            InterviewCopilotHeader(
              isMicListening: _isHeaderMicListening,
              onMicPressed: _toggleHeaderMic,
              onAnalysePressed: () {},
              onClearPressed: () {
                setState(() {
                  _messages.clear();
                });
              },
              onCopyAllPressed: _copyAllMessages,
            ),
            _buildProviderSelector(),
            InterviewCopilotChatArea(
              sessionStartTime: '10:30 AM',
              messages: _messages,
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.accentPurple,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Asking ${_currentProvider.name.toUpperCase()}...',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            InterviewCopilotInputBar(
              controller: _inputController,
              placeholder: 'Ask for a hint, custom response, or pivot...',
              isMicListening: _isInputMicListening,
              onMicPressed: _toggleInputMic,
              onClearPressed: () {
                setState(() {
                  _inputController.clear();
                });
              },
              onSendPressed: () {
                final text = _inputController.text;
                _sendMessage(text);
              },
              onAttachmentPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'AI Provider:',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              _buildProviderChip(AIProvider.openai, 'OpenAI'),
              const SizedBox(width: 8),
              _buildProviderChip(AIProvider.gemini, 'Gemini'),
              const SizedBox(width: 16),
              _buildStreamingToggle(),
            ],
          ),
          Row(
            children: [
              const Text(
                'Category:',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              _buildCategoryDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingToggle() {
    return Row(
      children: [
        Icon(
          Icons.stream,
          size: 14,
          color: _useStreaming ? AppColors.accentPurple : AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: _isLoading
              ? null
              : () {
                  setState(() => _useStreaming = !_useStreaming);
                },
          child: Text(
            _useStreaming ? 'Streaming' : 'Standard',
            style: TextStyle(
              color: _useStreaming
                  ? AppColors.accentPurple
                  : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textMuted.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InterviewCategory>(
          value: _currentCategory,
          dropdownColor: AppColors.backgroundSecondary,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: InterviewCategory.values
              .map(
                (cat) => DropdownMenuItem(value: cat, child: Text(cat.label)),
              )
              .toList(),
          onChanged: _isLoading
              ? null
              : (InterviewCategory? newCategory) {
                  if (newCategory != null) {
                    setState(() => _currentCategory = newCategory);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildProviderChip(AIProvider provider, String label) {
    final isSelected = _currentProvider == provider;
    return Material(
      color: isSelected
          ? AppColors.accentPurple
          : AppColors.backgroundTertiary.withOpacity(0.4),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _switchProvider(provider),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
