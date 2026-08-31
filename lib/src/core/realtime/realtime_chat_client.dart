sealed class RealtimeEvent {
  const RealtimeEvent(this.conversationId);

  final String conversationId;
}

final class UnknownRealtimeEvent extends RealtimeEvent {
  const UnknownRealtimeEvent(super.conversationId, this.rawPayload);

  final Object? rawPayload;
}

/// WebSocket boundary. The concrete protocol implementation is intentionally
/// separate because the backend handshake and event envelope are not final.
abstract interface class RealtimeChatClient {
  Stream<RealtimeEvent> get events;

  Future<void> connect({required String conversationId});

  Future<void> disconnect();

  Future<void> dispose();
}

final class NoopRealtimeChatClient implements RealtimeChatClient {
  @override
  Stream<RealtimeEvent> get events => const Stream<RealtimeEvent>.empty();

  @override
  Future<void> connect({required String conversationId}) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {}
}
