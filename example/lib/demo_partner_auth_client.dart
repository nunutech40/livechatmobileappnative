import 'package:dio/dio.dart';
import 'package:livechatmobileappnative/live_chat_sdk.dart';

final class DemoAuthSession {
  const DemoAuthSession({required this.accessToken, required this.email});

  final String accessToken;
  final String email;
}

/// Affiliate auth adapter used only by the example host app.
final class DemoPartnerAuthClient {
  DemoPartnerAuthClient({
    Dio? dio,
    this.baseUrl = 'https://dev.affiliate-api.komerce.my.id',
    this.fcmToken = 'live-chat-sdk-example',
  }) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;
  final String fcmToken;

  Future<DemoAuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/v1/auth/login',
        data: <String, String>{
          'username_email': email,
          'password': password,
          'fcm_token': fcmToken,
        },
      );
      final data = _asMap(response.data?['data']);
      final token = data['access_token'];
      if (token is! String || token.isEmpty) {
        throw const AuthException(
          'Login response did not contain an access token.',
        );
      }
      return DemoAuthSession(accessToken: token, email: email);
    } on LiveChatException {
      rethrow;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 422) {
        throw const AuthException('Email atau password tidak valid.');
      }
      final body = _asMap(error.response?.data);
      final message = body['message'];
      final detail = message is String
          ? message
          : error.message ?? error.type.name;
      throw NetworkException('Login service tidak dapat diakses: $detail');
    }
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};
}
