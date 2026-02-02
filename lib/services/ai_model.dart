import '../models/interview_category.dart';
import '../models/interview_response.dart';
import '../models/streaming_response.dart';

/// Abstract base class for AI model services
abstract class AIModel {
  /// Send a prompt and get structured interview response
  Future<InterviewResponse> getInterviewResponse(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  });

  /// Stream response for real-time updates with structured sections
  /// Returns a stream of StreamingInterviewResponse that builds incrementally
  Future<Stream<StreamingInterviewResponse>> streamInterviewResponse(
    String prompt, {
    InterviewCategory category = InterviewCategory.normal,
  }) {
    throw UnimplementedError('Streaming not implemented for this model');
  }
}

/// Custom exception for AI model errors
class AIModelException implements Exception {
  final String message;
  final String? provider;

  AIModelException(this.message, {this.provider});

  @override
  String toString() => provider != null
      ? 'AIModelException ($provider): $message'
      : 'AIModelException: $message';
}
