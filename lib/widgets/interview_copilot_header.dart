import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Header bar for Interview Copilot with logo, title, status, and control buttons.
class InterviewCopilotHeader extends StatelessWidget {
  const InterviewCopilotHeader({
    super.key,
    this.isMicListening = true,
    this.onMicPressed,
    this.onAnalysePressed,
    this.onClearPressed,
    this.onCopyAllPressed,
  });

  final bool isMicListening;
  final VoidCallback? onMicPressed;
  final VoidCallback? onAnalysePressed;
  final VoidCallback? onClearPressed;
  final VoidCallback? onCopyAllPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundTertiary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildLogoAndTitle(),
          const Spacer(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildLogoAndTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'INTERVIEW COPILOT',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.statusActive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppColors.statusActive.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderButton(
          icon: Icons.content_copy_rounded,
          label: 'Copy All',
          onPressed: onCopyAllPressed,
        ),
        const SizedBox(width: 6),
        _HeaderButton(
          icon: Icons.mic_rounded,
          label: 'Microphone',
          isActive: isMicListening,
          onPressed: onMicPressed,
        ),
        const SizedBox(width: 6),
        _HeaderButton(
          icon: Icons.monitor_rounded,
          label: 'Analyse',
          onPressed: onAnalysePressed,
        ),
        const SizedBox(width: 6),
        _HeaderButton(
          icon: Icons.delete_outline_rounded,
          label: 'Clear',
          onPressed: onClearPressed,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    this.label,
    required this.icon,
    this.isActive = false,
    this.onPressed,
  });

  final String? label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label ?? '',
      child: Material(
        color: AppColors.backgroundTertiary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppColors.textPrimary),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.statusActive,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
