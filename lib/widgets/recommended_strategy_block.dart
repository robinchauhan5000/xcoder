import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Recommended strategy block with optional key concept section.
class RecommendedStrategyBlock extends StatelessWidget {
  const RecommendedStrategyBlock({
    super.key,
    required this.strategyText,
    this.keyConceptText,
    this.boldSpans = const [],
  });

  final String strategyText;
  final String? keyConceptText;
  final List<String> boldSpans;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.backgroundTertiary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.accentYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recommended Strategy',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRichText(strategyText, boldSpans),
          if (keyConceptText != null) ...[
            const SizedBox(height: 16),
            _KeyConceptSection(text: keyConceptText!),
          ],
        ],
      ),
    );
  }

  Widget _buildRichText(String text, List<String> boldSpans) {
    const baseStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.5,
    );
    const boldStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.bold,
    );

    if (boldSpans.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final firstBold = boldSpans.first;
    final index = text.indexOf(firstBold);
    if (index == -1) {
      return Text(text, style: baseStyle);
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(text: firstBold, style: boldStyle),
          TextSpan(text: text.substring(index + firstBold.length)),
        ],
      ),
    );
  }
}

class _KeyConceptSection extends StatelessWidget {
  const _KeyConceptSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'KEY CONCEPT',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
