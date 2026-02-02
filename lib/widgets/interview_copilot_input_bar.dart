import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom input bar with voice controls, text input, and send actions.
class InterviewCopilotInputBar extends StatelessWidget {
  const InterviewCopilotInputBar({
    super.key,
    this.controller,
    this.onMicPressed,
    this.onClearPressed,
    this.onSendPressed,
    this.onAttachmentPressed,
    this.placeholder = 'Ask for a hint, custom response, or pivot...',
    this.isMicListening = false,
  });

  final TextEditingController? controller;
  final VoidCallback? onMicPressed;
  final VoidCallback? onClearPressed;
  final VoidCallback? onSendPressed;
  final VoidCallback? onAttachmentPressed;
  final String placeholder;
  final bool isMicListening;

  void _handleSubmit() {
    if (onSendPressed != null && controller?.text.trim().isNotEmpty == true) {
      onSendPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppColors.backgroundTertiary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _VoiceButton(
              icon: Icons.mic_rounded,
              onPressed: onMicPressed,
              isListening: isMicListening,
            ),
            const SizedBox(width: 12),
            _IconButton(
              icon: Icons.clear_rounded,
              onPressed: onClearPressed,
              tooltip: 'Clear text',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 200, // Maximum height before scrolling
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.backgroundTertiary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 24,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSubmit(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: placeholder,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 0,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _IconButton(
              icon: Icons.attach_file_rounded,
              onPressed: onAttachmentPressed,
            ),
            const SizedBox(width: 8),
            _IconButton(
              icon: Icons.send_rounded,
              onPressed: onSendPressed,
              backgroundColor: AppColors.accentPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.icon,
    this.onPressed,
    this.isListening = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isListening ? Colors.green : Colors.red,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (isListening)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor ?? AppColors.backgroundTertiary.withOpacity(0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
