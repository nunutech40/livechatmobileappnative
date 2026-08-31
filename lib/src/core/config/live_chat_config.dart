import 'package:dio/dio.dart';

final class LiveChatConfig {
  const LiveChatConfig({
    required this.restBaseUrl,
    required this.websocketUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
  });

  final String restBaseUrl;
  final String websocketUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  BaseOptions toBaseOptions() => BaseOptions(
    baseUrl: restBaseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    sendTimeout: sendTimeout,
    headers: const <String, Object>{'Accept': 'application/json'},
  );
}
