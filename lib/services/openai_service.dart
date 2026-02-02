import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/interview_category.dart';
import '../models/interview_response.dart';
import '../models/streaming_response.dart';
import 'ai_model.dart';
import 'http_client.dart';
import 'prompt_builder.dart';

/// OpenAI API service for interview assistant
class OpenAIService extends AIModel {
  final HttpClient _httpClient;
  final String apiKey;

  static const String _model = 'gpt-5.2';

  OpenAIService({required this.apiKey})
    : _httpClient = HttpClient(
        baseUrl: 'https://api.openai.com/v1',
        defaultHeaders: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        timeout: const Duration(seconds: 120),
      );

  /// -------------------------------
  /// BLOCKING (NON-STREAMING)
  /// -------------------------------
  @override
  Future<InterviewResponse> getInterviewResponse(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  }) async {
    try {
      final systemPrompt =
          category == InterviewCategory.systemDesign
              ? PromptBuilder.buildSystemDesignBasePrompt()
              : PromptBuilder.buildSystemPrompt(category);
      final userPrompt =
          category == InterviewCategory.systemDesign
              ? PromptBuilder.buildSystemDesignFullUserPrompt(question: prompt)
              : prompt;

      final response = await _httpClient.post(
        '/chat/completions',
        body: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'response_format': {'type': 'json_object'},
        },
      );

      if (response.statusCode != 200) {
        throw AIModelException(
          'API request failed with status ${response.statusCode}: ${response.body}',
          provider: 'OpenAI',
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      final jsonResponse = jsonDecode(content);

      return InterviewResponse.fromJson(jsonResponse);
    } on http.ClientException catch (e) {
      throw AIModelException('Network error: $e', provider: 'OpenAI');
    } on FormatException catch (e) {
      throw AIModelException('Invalid JSON response: $e', provider: 'OpenAI');
    } catch (e) {
      if (e is AIModelException) rethrow;
      throw AIModelException('Unexpected error: $e', provider: 'OpenAI');
    }
  }

  /// -------------------------------
  /// STREAMING (SSE) with Section Parsing
  /// -------------------------------
  @override
  Future<Stream<StreamingInterviewResponse>> streamInterviewResponse(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  }) async {
    if (category == InterviewCategory.systemDesign) {
      return _streamPhasedSystemDesign(prompt);
    }

    final systemPrompt = PromptBuilder.buildSystemPrompt(category);
    return _streamOpenAiResponse(systemPrompt: systemPrompt, prompt: prompt);
  }

  Future<Stream<StreamingInterviewResponse>> _streamPhasedSystemDesign(
    String prompt,
  ) async {
    final controller = StreamController<StreamingInterviewResponse>();
    final phaseSections = <int, List<ResponseSection>>{};
    var title = '';
    final baseSystemPrompt = PromptBuilder.buildSystemDesignBasePrompt();

    unawaited(() async {
      try {
        for (var phase = 1; phase <= 4; phase++) {
          final userPrompt = PromptBuilder.buildSystemDesignPhaseUserPrompt(
            phase: phase,
            question: prompt,
          );

          final phaseStream = await _streamOpenAiResponse(
            systemPrompt: baseSystemPrompt,
            prompt: userPrompt,
          );

          await for (final phaseResponse in phaseStream) {
            if (title.isEmpty && phaseResponse.title.isNotEmpty) {
              title = phaseResponse.title;
            }
            phaseSections[phase] = phaseResponse.sections;
            controller.add(
              StreamingInterviewResponse(
                title: title,
                sections: _mergePhaseSections(phaseSections),
                isComplete: false,
              ),
            );
          }
        }

        controller.add(
          StreamingInterviewResponse(
            title: title,
            sections: _mergePhaseSections(phaseSections),
            isComplete: true,
          ),
        );
        await controller.close();
      } catch (e, st) {
        controller.addError(e, st);
        await controller.close();
      }
    }());

    return controller.stream;
  }

  List<ResponseSection> _mergePhaseSections(
    Map<int, List<ResponseSection>> phaseSections,
  ) {
    final merged = <ResponseSection>[];
    final phases = phaseSections.keys.toList()..sort();
    for (final phase in phases) {
      merged.addAll(phaseSections[phase] ?? const []);
    }
    return merged;
  }

  Future<Stream<StreamingInterviewResponse>> _streamOpenAiResponse({
    required String systemPrompt,
    required String prompt,
  }) async {
    final request = http.Request(
      'POST',
      Uri.parse('https://api.openai.com/v1/chat/completions'),
    );

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });

    request.body = jsonEncode({
      'model': _model,
      'stream': true,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
      'response_format': {'type': 'json_object'},
    });

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw AIModelException(
        'Streaming failed with status ${response.statusCode}',
        provider: 'OpenAI',
      );
    }

    // Create parser for incremental JSON parsing
    final parser = StreamingResponseParser();

    // Convert byte stream → text → SSE lines → content tokens → parsed sections
    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: '))
        .map((line) {
          final data = line.substring(6).trim();

          if (data == '[DONE]') {
            return null;
          }

          try {
            final json = jsonDecode(data);
            final delta = json['choices'][0]['delta'];

            if (delta == null || delta['content'] == null) {
              return null;
            }

            return delta['content'] as String;
          } catch (e) {
            return null;
          }
        })
        .where((chunk) => chunk != null)
        .cast<String>()
        .listen(
          (chunk) => parser.addChunk(chunk),
          onDone: () {
            parser.complete();
            client.close();
          },
          onError: (error) {
            parser.addError(error);
            client.close();
          },
          cancelOnError: true,
        );

    return parser.stream;
  }
}
