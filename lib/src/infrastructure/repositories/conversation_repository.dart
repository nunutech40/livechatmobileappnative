import 'package:dio/dio.dart';

import '../../domain/models/chat_models.dart';
import '../../core/auth/auth_provider.dart';
import '../../domain/ports/conversation_repository.dart';
import '../network/api_client.dart';

final class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl({
    required ApiClient api,
    required UserIdentity identity,
  }) : _api = api,
       _identity = identity;

  final ApiClient _api;
  final UserIdentity _identity;

  @override
  Future<ConversationPage> getUserConversations({
    int limit = 20,
    String? lastId,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/v1/conversations/user',
      queryParameters: <String, dynamic>{
        'email': _identity.email,
        'user_id': _identity.userId,
        'limit': limit,
        ...?(lastId == null ? null : <String, dynamic>{'last_id': lastId}),
      },
      cancelToken: cancelToken,
    );
    final body = _map(response.data);
    final data = body['data'] is List
        ? body['data'] as List<Object?>
        : const [];
    final rawItems = data.whereType<Map<String, dynamic>>().toList();
    final items = rawItems.map(_conversation).toList();
    return ConversationPage(
      items: items,
      nextCursor: rawItems.isEmpty ? null : _string(rawItems.last['id']),
    );
  }

  @override
  Future<MessagePage> getConversationMessages({
    required String conversationId,
    int limit = 20,
    String? lastId,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/v1/conversations/$conversationId/messages',
      queryParameters: <String, dynamic>{
        'limit': limit,
        ...?(lastId == null ? null : <String, dynamic>{'last_id': lastId}),
      },
      cancelToken: cancelToken,
    );
    final body = _map(response.data);
    final data = body['data'] is List
        ? body['data'] as List<Object?>
        : const [];
    final rawItems = data.whereType<Map<String, dynamic>>().toList();
    final items = rawItems.map(_message).toList().reversed.toList();
    return MessagePage(
      items: items,
      nextCursor: rawItems.isEmpty ? null : _string(rawItems.last['id']),
    );
  }

  ConversationPreview _conversation(Map<String, dynamic> json) {
    final lastMessage = _map(json['last_message']);
    final messageContents = _messageContents(lastMessage['message']);
    return ConversationPreview(
      id: _string(json['id']) ?? '',
      status: _status(json['status']),
      preview: messageContents.text,
      ticket: 'No Ticket: ${json['ticket_number'] ?? '-'}',
      time: _formatDate(lastMessage['created_at']),
      unread: lastMessage['status'] != 'read',
    );
  }

  ChatMessage _message(Map<String, dynamic> json) {
    final sender = _map(json['sender']);
    final senderEmail = _string(sender['email']);
    return ChatMessage(
      time: _formatDate(json['created_at']),
      variant: senderEmail == _identity.email
          ? MessageBubbleVariant.outgoing
          : MessageBubbleVariant.incoming,
      contents: _messageContents(json['message']).contents,
    );
  }

  _ParsedContents _messageContents(Object? value) {
    final entries = value is List ? value : const <Object?>[];
    final contents = <MessageContent>[];
    for (final raw in entries) {
      final item = _map(raw);
      final type = _string(item['type']);
      final content = item['content'];
      if (type == 'text' && content is String) {
        contents.add(TextContent(content));
      } else if (type == 'image' || type == 'document' || type == 'file') {
        final meta = _map(item['meta']);
        final name = _string(meta['file_name']) ?? 'Lampiran';
        final extension = _string(meta['extension']) ?? type ?? 'file';
        contents.add(
          AttachmentContent(
            AttachmentData(
              name: name,
              extension: extension,
              size: _formatBytes(meta['size']),
              kind: type == 'image'
                  ? AttachmentKind.image
                  : AttachmentKind.document,
            ),
          ),
        );
      } else {
        contents.add(const UnsupportedContent());
      }
    }
    return _ParsedContents(contents);
  }

  ConversationStatus _status(Object? value) => switch (value) {
    'handling' => ConversationStatus.handling,
    'escalated' => ConversationStatus.escalated,
    'resolved' => ConversationStatus.resolved,
    'cancelled' => ConversationStatus.cancelled,
    _ => ConversationStatus.open,
  };

  Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  String? _string(Object? value) => value is String ? value : value?.toString();

  String _formatDate(Object? value) {
    final date = value is String ? DateTime.tryParse(value)?.toLocal() : null;
    if (date == null) return '-';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(Object? value) {
    final bytes = value is num ? value.toInt() : 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

final class _ParsedContents {
  const _ParsedContents(this.contents);

  final List<MessageContent> contents;

  String get text =>
      contents.whereType<TextContent>().map((e) => e.value).join('\n');
}
