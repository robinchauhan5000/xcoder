import 'dart:async';
import 'dart:convert';

import 'interview_response.dart';

/// Represents a streaming interview response that builds incrementally
class StreamingInterviewResponse {
  String title;
  final List<ResponseSection> sections;
  bool isComplete;

  StreamingInterviewResponse({
    this.title = '',
    List<ResponseSection>? sections,
    this.isComplete = false,
  }) : sections = sections ?? [];

  /// Create a copy with updated values
  StreamingInterviewResponse copyWith({
    String? title,
    List<ResponseSection>? sections,
    bool? isComplete,
  }) {
    return StreamingInterviewResponse(
      title: title ?? this.title,
      sections: sections ?? this.sections,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  /// Convert to final InterviewResponse
  InterviewResponse toInterviewResponse() {
    return InterviewResponse(title: title, sections: sections);
  }
}

/// Parses streaming JSON chunks into structured sections
class StreamingResponseParser {
  final _buffer = StringBuffer();
  final _controller = StreamController<StreamingInterviewResponse>();

  StreamingInterviewResponse _currentResponse = StreamingInterviewResponse();
  bool _isParsingStarted = false;
  int _braceCount = 0;

  Stream<StreamingInterviewResponse> get stream => _controller.stream;

  /// Add a chunk of text to parse
  void addChunk(String chunk) {
    if (_controller.isClosed) return;

    _buffer.write(chunk);
    _tryParse();
  }

  /// Signal that streaming is complete
  void complete() {
    _tryParse(force: true);

    if (!_controller.isClosed) {
      _currentResponse.isComplete = true;
      _controller.add(_currentResponse);
      _controller.close();
    }
  }

  /// Handle errors
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_controller.isClosed) {
      _controller.addError(error, stackTrace);
      _controller.close();
    }
  }

  void _tryParse({bool force = false}) {
    final text = _buffer.toString();

    // Try to find complete JSON object
    if (!_isParsingStarted) {
      final startIndex = text.indexOf('{');
      if (startIndex == -1) return;
      _isParsingStarted = true;
    }

    // Count braces to find complete JSON
    _braceCount = 0;
    int? completeJsonEnd;

    for (int i = 0; i < text.length; i++) {
      if (text[i] == '{') {
        _braceCount++;
      } else if (text[i] == '}') {
        _braceCount--;
        if (_braceCount == 0) {
          completeJsonEnd = i + 1;
          break;
        }
      }
    }

    // If we have complete JSON or force parse
    if (completeJsonEnd != null || (force && text.contains('{'))) {
      try {
        final jsonText = completeJsonEnd != null
            ? text.substring(0, completeJsonEnd)
            : text;

        final json = jsonDecode(jsonText);
        _currentResponse = _parseJson(json);

        if (!_controller.isClosed) {
          _controller.add(_currentResponse);
        }

        // Clear parsed content
        if (completeJsonEnd != null) {
          _buffer.clear();
          _buffer.write(text.substring(completeJsonEnd));
        }
      } catch (e) {
        // Not valid JSON yet, wait for more data
        if (force && !_controller.isClosed) {
          // On force, try to extract what we can
          _tryPartialParse(text);
        }
      }
    }
  }

  void _tryPartialParse(String text) {
    // Try to extract title and partial sections
    try {
      // Extract title if present
      final titleMatch = RegExp(r'"title"\s*:\s*"([^"]*)"').firstMatch(text);
      if (titleMatch != null) {
        _currentResponse.title = titleMatch.group(1) ?? '';
      }

      // Extract sections array
      final sectionsMatch = RegExp(
        r'"sections"\s*:\s*\[(.*)\]',
        dotAll: true,
      ).firstMatch(text);
      if (sectionsMatch != null) {
        final sectionsText = sectionsMatch.group(1) ?? '';
        _currentResponse.sections.clear();

        // Try to parse individual sections
        final sectionMatches = RegExp(
          r'\{[^}]*\}',
          dotAll: true,
        ).allMatches(sectionsText);
        for (final match in sectionMatches) {
          try {
            final sectionJson = jsonDecode(match.group(0)!);
            final section = ResponseSection.fromJson(sectionJson);
            _currentResponse.sections.add(section);
          } catch (e) {
            // Skip invalid sections
          }
        }
      }

      if (!_controller.isClosed) {
        _controller.add(_currentResponse);
      }
    } catch (e) {
      // Partial parse failed, that's okay
    }
  }

  StreamingInterviewResponse _parseJson(Map<String, dynamic> json) {
    return StreamingInterviewResponse(
      title: json['title'] as String? ?? '',
      sections:
          (json['sections'] as List?)
              ?.map((s) => ResponseSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      isComplete: false,
    );
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
