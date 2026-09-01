import 'package:dio/dio.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/live_chat_exception.dart';
import 'token_coordinator.dart';

/// Instance-scoped REST client. Never make this class global or static.
final class ApiClient {
  ApiClient(
    this._dio, {
    required AuthProvider authProvider,
    this.ownsDio = true,
  }) : _authProvider = authProvider,
       _tokenCoordinator = TokenCoordinator(authProvider);

  final Dio _dio;
  final bool ownsDio;
  final AuthProvider _authProvider;
  final TokenCoordinator _tokenCoordinator;
  bool _closed = false;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'GET',
    queryParameters: queryParameters,
    cancelToken: cancelToken,
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) => request<T>(
    path,
    method: 'POST',
    data: data,
    queryParameters: queryParameters,
    cancelToken: cancelToken,
  );

  Future<Response<T>> request<T>(
    String path, {
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    if (_closed) throw const NetworkException('API client is disposed.');

    var hasRetriedAfterRefresh = false;
    while (true) {
      final token = await _authProvider.getAccessToken();
      if (token == null || token.isEmpty) throw const AuthException();

      try {
        return await _dio.request<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          options: Options(
            method: method,
            headers: <String, String>{'Authorization': 'Bearer $token'},
          ),
        );
      } on DioException catch (error) {
        if (error.response?.statusCode == 401 && !hasRetriedAfterRefresh) {
          hasRetriedAfterRefresh = true;
          final refreshedToken = await _tokenCoordinator.refresh();
          if (refreshedToken == null || refreshedToken.isEmpty) {
            throw const AuthException('Token refresh failed.');
          }
          continue;
        }
        throw _mapError(error);
      }
    }
  }

  Future<void> close() async {
    _closed = true;
    _tokenCoordinator.clear();
    if (ownsDio) _dio.close(force: true);
  }

  LiveChatException _mapError(DioException error) {
    final status = error.response?.statusCode;
    final requestId = error.response?.headers.value('x-request-id');
    if (status != null) {
      if (status == 422) return const ValidationException();
      if (status == 401) return const AuthException('Authentication failed.');
      return ApiException(statusCode: status, requestId: requestId);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const TimeoutException();
    }
    if (error.type == DioExceptionType.cancel) {
      return const NetworkException('Request was cancelled.');
    }
    return const NetworkException();
  }
}
