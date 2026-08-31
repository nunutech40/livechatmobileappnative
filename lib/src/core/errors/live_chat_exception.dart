sealed class LiveChatException implements Exception {
  const LiveChatException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class AuthException extends LiveChatException {
  const AuthException([super.message = 'Authentication is required.']);
}

final class NetworkException extends LiveChatException {
  const NetworkException([super.message = 'Network request failed.']);
}

final class TimeoutException extends LiveChatException {
  const TimeoutException([super.message = 'Network request timed out.']);
}

final class ApiException extends LiveChatException {
  const ApiException({
    required this.statusCode,
    this.requestId,
    String? message,
  }) : super(message ?? 'API request failed with status $statusCode.');

  final int statusCode;
  final String? requestId;
}

final class ValidationException extends LiveChatException {
  const ValidationException([super.message = 'The request is invalid.']);
}
