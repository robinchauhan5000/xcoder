import 'package:flutter/material.dart';

/// Interview Copilot design system colors.
/// Dark theme palette with blue, purple, and green accents.
abstract final class AppColors {
  AppColors._();

  // Backgrounds
  static const Color backgroundPrimary = Color(0xFF282A36);
  static const Color backgroundSecondary = Color(0xFF363945);
  static const Color backgroundTertiary = Color(0xFF2F323D);
  static const Color surfaceDark = Color(0xFF1E2029);

  // Accents
  static const Color accentBlue = Color(0xFF4285F4);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentYellow = Color(0xFFFFC107);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B8);
  static const Color textMuted = Color(0xFF8E8E96);

  // Status
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusInactive = Color(0xFF6B6B73);

  // Chat bubbles
  static const Color userBubble = Color(0xFF4285F4);
  static const Color assistantBubble = Color(0xFF363945);
}
