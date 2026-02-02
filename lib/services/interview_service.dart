import '../config/api_config.dart';
import '../models/interview_category.dart';
import '../models/interview_response.dart';
import '../models/streaming_response.dart';
import 'ai_model.dart';
import 'gemini_service.dart';
import 'openai_service.dart';

/// AI Provider enum
enum AIProvider { openai, gemini }

/// High-level service for interview assistant functionality
class InterviewService {
  late final AIModel _aiModel;
  final AIProvider provider;

  InterviewService({AIProvider? provider, String? apiKey})
    : provider = provider ?? AIProvider.openai {
    switch (this.provider) {
      case AIProvider.openai:
        final key = apiKey ?? ApiConfig.openAiApiKey;
        if (key.isEmpty) {
          throw Exception('OpenAI API key not configured');
        }
        _aiModel = OpenAIService(apiKey: key);
        break;

      case AIProvider.gemini:
        final key = apiKey ?? ApiConfig.geminiApiKey;
        if (key.isEmpty) {
          throw Exception('Gemini API key not configured');
        }
        _aiModel = GeminiService(apiKey: key);
        break;
    }
  }

  /// Get interview response for a given prompt
  Future<InterviewResponse> askQuestion(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  }) async {
    if (prompt.trim().isEmpty) {
      throw ArgumentError('Prompt cannot be empty');
    }

    return await _aiModel.getInterviewResponse(prompt, category: category);
  }

  /// Stream interview response for real-time updates with structured sections
  Future<Stream<StreamingInterviewResponse>> askQuestionStream(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
    bool includeOptionalCodePhase = false,
  }) async {
    if (prompt.trim().isEmpty) {
      throw ArgumentError('Prompt cannot be empty');
    }

    return await _aiModel.streamInterviewResponse(
      prompt,
      category: category,
      includeOptionalCodePhase: includeOptionalCodePhase,
    );
  }

  /// Format response for display
  String formatResponse(InterviewResponse response) {
    final buffer = StringBuffer();
    buffer.writeln('# ${response.title}\n');
    final useTitles = response.sections.any((s) => s.type.isSystemDesign);

    for (final section in response.sections) {
      if (useTitles) {
        buffer.writeln('**${section.type.title}**');
      }
      _appendSectionContent(buffer, section, useTitles: useTitles);
    }

    return buffer.toString();
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
}
