import 'package:dio/dio.dart';

import 'core/auth/auth_provider.dart';
import 'core/config/live_chat_config.dart';
import 'core/network/api_client.dart';
import 'core/realtime/realtime_chat_client.dart';

/// Composition root for one authenticated host-app user.
///
/// Create a new instance when the host logs out or switches user. This keeps
/// auth context, REST client, realtime connection, and in-memory runtime state
/// isolated from the previous user.
final class LiveChatSdk {
  LiveChatSdk({
    required this.config,
    required AuthProvider authProvider,
    required this.identity,
    Dio? dio,
    RealtimeChatClient? realtimeClient,
  }) : _apiClient = ApiClient(
         dio ?? Dio(config.toBaseOptions()),
         authProvider: authProvider,
       ),
       realtime = realtimeClient ?? NoopRealtimeChatClient();

  final LiveChatConfig config;
  final UserIdentity identity;
  final ApiClient _apiClient;
  final RealtimeChatClient realtime;
  bool _disposed = false;

  ApiClient get api => _apiClient;

  bool get isDisposed => _disposed;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await realtime.dispose();
    await _apiClient.close();
  }
}
