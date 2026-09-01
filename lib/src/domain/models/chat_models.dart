import 'dart:typed_data';

enum LiveChatTab { conversations, articles }

enum ConversationStatus { open, handling, escalated, resolved, cancelled }

enum MessageBubbleVariant { incoming, outgoing }

enum AttachmentKind { image, document }

class ConversationPreview {
  const ConversationPreview({
    required this.id,
    required this.status,
    required this.preview,
    required this.ticket,
    required this.time,
    this.unread = false,
  });

  final String id;
  final ConversationStatus status;
  final String preview;
  final String ticket;
  final String time;
  final bool unread;
}

/// Display-ready content that can be rendered inside a message bubble.
sealed class MessageContent {
  const MessageContent();
}

class TextContent extends MessageContent {
  const TextContent(this.value);

  final String value;
}

class AttachmentContent extends MessageContent {
  const AttachmentContent(this.data);

  final AttachmentData data;
}

class UnsupportedContent extends MessageContent {
  const UnsupportedContent({this.label = 'Tipe pesan belum didukung'});

  final String label;
}

class ChatMessage {
  const ChatMessage({
    required this.time,
    required this.variant,
    this.contents = const [],
  });

  final String time;
  final MessageBubbleVariant variant;
  final List<MessageContent> contents;

  // Convenience getters keep simple UI components independent from content
  // ordering while allowing future content types to be added.
  String get text => contents
      .whereType<TextContent>()
      .map((content) => content.value)
      .join('\n');

  AttachmentData? get attachment {
    for (final content in contents) {
      if (content case AttachmentContent(:final data)) return data;
    }
    return null;
  }
}

class AttachmentData {
  const AttachmentData({
    required this.name,
    required this.extension,
    required this.size,
    required this.kind,
    this.bytes,
  });

  final String name;
  final String extension;
  final String size;
  final AttachmentKind kind;
  final Uint8List? bytes;
}
