import 'package:dio/dio.dart';

import '../models/chat_models.dart';

final class ConversationPage {
  const ConversationPage({required this.items, this.nextCursor});

  final List<ConversationPreview> items;
  final String? nextCursor;
}

final class MessagePage {
  const MessagePage({required this.items, this.nextCursor});

  final List<ChatMessage> items;
  final String? nextCursor;
}

abstract interface class ConversationRepository {
  Future<ConversationPage> getUserConversations({
    int limit = 20,
    String? lastId,
    CancelToken? cancelToken,
  });

  Future<MessagePage> getConversationMessages({
    required String conversationId,
    int limit = 20,
    String? lastId,
    CancelToken? cancelToken,
  });
}
