import '../constants/api_keys.dart';

/// API configuration
class ApiConfig {
  ApiConfig._();

  /// OpenAI API key from constants
  static const String openAiApiKey = ApiKeys.openAiApiKey;

  /// Gemini API key from constants
  static const String geminiApiKey = ApiKeys.geminiApiKey;

  /// Validate OpenAI API key is set
  static bool get isOpenAIConfigured =>
      openAiApiKey.isNotEmpty && !openAiApiKey.startsWith('YOUR_');

  /// Validate Gemini API key is set
  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && !geminiApiKey.startsWith('YOUR_');

  /// Check if any AI provider is configured
  static bool get isConfigured => isOpenAIConfigured || isGeminiConfigured;
}
