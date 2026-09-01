import 'package:dio/dio.dart';

import '../auth/auth_provider.dart';
import '../../domain/ports/conversation_repository.dart';
import '../config/live_chat_config.dart';
import '../../infrastructure/network/api_client.dart';
import '../../domain/ports/realtime_chat_client.dart';
import '../../infrastructure/repositories/conversation_repository.dart';

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
         ownsDio: dio == null,
       ),
       realtime = realtimeClient ?? NoopRealtimeChatClient() {
    conversations = ConversationRepositoryImpl(
      api: _apiClient,
      identity: identity,
    );
  }

  final LiveChatConfig config;
  final UserIdentity identity;
  final ApiClient _apiClient;
  final RealtimeChatClient realtime;
  late final ConversationRepository conversations;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await realtime.dispose();
    await _apiClient.close();
  }
}
