import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP client for making API requests
class HttpClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  HttpClient({
    required this.baseUrl,
    Map<String, String>? defaultHeaders,
    this.timeout = const Duration(seconds: 30),
  }) : defaultHeaders = defaultHeaders ?? {};

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final mergedHeaders = {...defaultHeaders, ...?headers};

    try {
      final response = await http
          .post(
            uri,
            headers: mergedHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      return response;
    } catch (e) {
      throw HttpException('POST request failed: $e');
    }
  }

  /// GET request
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final mergedHeaders = {...defaultHeaders, ...?headers};

    try {
      final response = await http
          .get(uri, headers: mergedHeaders)
          .timeout(timeout);

      return response;
    } catch (e) {
      throw HttpException('GET request failed: $e');
    }
  }
}

/// Custom exception for HTTP errors
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
