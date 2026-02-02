import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/interview_category.dart';
import '../models/interview_response.dart';
import '../models/streaming_response.dart';
import 'ai_model.dart';
import 'http_client.dart';
import 'prompt_builder.dart';

/// Gemini AI API service for interview assistant
class GeminiService extends AIModel {
  final HttpClient _httpClient;
  final String apiKey;

  static const String _model = 'gemini-3-flash-preview';

  GeminiService({required this.apiKey})
    : _httpClient = HttpClient(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        defaultHeaders: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        timeout: const Duration(seconds: 60),
      );

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
        '/models/$_model:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': '$systemPrompt\n\nUser Question: $userPrompt'},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'responseMimeType': 'application/json',
          },
        },
      );

      if (response.statusCode != 200) {
        throw AIModelException(
          'API request failed with status ${response.statusCode}: ${response.body}',
          provider: 'Gemini',
        );
      }

      final data = jsonDecode(response.body);

      // Extract text from Gemini response structure
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw AIModelException(
          'No response candidates returned',
          provider: 'Gemini',
        );
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List;
      if (parts.isEmpty) {
        throw AIModelException(
          'No content parts in response',
          provider: 'Gemini',
        );
      }

      final textContent = parts[0]['text'] as String;
      final jsonResponse = jsonDecode(textContent);

      return InterviewResponse.fromJson(jsonResponse);
    } on http.ClientException catch (e) {
      throw AIModelException('Network error: $e', provider: 'Gemini');
    } on FormatException catch (e) {
      throw AIModelException('Invalid JSON response: $e', provider: 'Gemini');
    } catch (e) {
      if (e is AIModelException) rethrow;
      throw AIModelException('Unexpected error: $e', provider: 'Gemini');
    }
  }

  @override
  Future<Stream<StreamingInterviewResponse>> streamInterviewResponse(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  }) async {
    if (category == InterviewCategory.systemDesign) {
      return _streamPhasedSystemDesign(prompt);
    }

    final systemPrompt = PromptBuilder.buildSystemPrompt(category);
    return _streamGeminiResponse(systemPrompt: systemPrompt, prompt: prompt);
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

          final phaseStream = await _streamGeminiResponse(
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

  Future<Stream<StreamingInterviewResponse>> _streamGeminiResponse({
    required String systemPrompt,
    required String prompt,
  }) async {
    final request = http.Request(
      'POST',
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent?key=$apiKey',
      ),
    );

    request.headers.addAll({'Content-Type': 'application/json'});

    request.body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$systemPrompt\n\nUser Question: $prompt'},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'responseMimeType': 'application/json',
      },
    });

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw AIModelException(
        'Streaming failed with status ${response.statusCode}',
        provider: 'Gemini',
      );
    }

    // Create parser for incremental JSON parsing
    final parser = StreamingResponseParser();

    // Convert byte stream → text → JSON lines → content → parsed sections
    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          try {
            final json = jsonDecode(line);
            final candidates = json['candidates'] as List?;
            if (candidates == null || candidates.isEmpty) return null;

            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts == null || parts.isEmpty) return null;

            return parts[0]['text'] as String?;
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
