import 'package:http/http.dart' as http;

/// Custom exception for API errors with user-friendly messages
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final ApiExceptionType type;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    required this.type,
  });

  @override
  String toString() => message;

  /// Factory to create exception from HTTP response
  factory ApiException.fromResponse(http.Response response, String operation) {
    final statusCode = response.statusCode;
    
    switch (statusCode) {
      case 400:
        return ApiException(
          message: 'Invalid data provided. Please check and try again.',
          statusCode: statusCode,
          type: ApiExceptionType.validation,
        );
      case 401:
        return ApiException(
          message: 'Session expired. Please log in again.',
          statusCode: statusCode,
          type: ApiExceptionType.authentication,
        );
      case 403:
        return ApiException(
          message: 'You do not have permission to perform this action.',
          statusCode: statusCode,
          type: ApiExceptionType.permission,
        );
      case 404:
        return ApiException(
          message: 'The requested item was not found.',
          statusCode: statusCode,
          type: ApiExceptionType.notFound,
        );
      case 409:
        return ApiException(
          message: 'This item already exists.',
          statusCode: statusCode,
          type: ApiExceptionType.conflict,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
          type: ApiExceptionType.server,
        );
      default:
        return ApiException(
          message: 'Something went wrong. Please try again.',
          statusCode: statusCode,
          type: ApiExceptionType.unknown,
        );
    }
  }

  /// Factory for network errors
  factory ApiException.network(String operation) {
    return ApiException(
      message: 'No internet connection. Please check your network.',
      type: ApiExceptionType.network,
    );
  }

  /// Factory for timeout errors
  factory ApiException.timeout(String operation) {
    return ApiException(
      message: 'Request timed out. Please try again.',
      type: ApiExceptionType.timeout,
    );
  }
}

enum ApiExceptionType {
  validation,
  authentication,
  permission,
  notFound,
  conflict,
  server,
  network,
  timeout,
  unknown,
}