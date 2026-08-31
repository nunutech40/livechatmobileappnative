import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_models.dart';

/// Scoped by an SDK/page instance key so multiple Live Chat widgets do not
/// share their selected tab.
final selectedTabProvider = StateProvider.autoDispose
    .family<LiveChatTab, Object>(
      (ref, instanceKey) => LiveChatTab.conversations,
    );

/// UI fixture data. Replaced by controller/repository providers in the API
/// integration phase without changing component contracts.
final conversationsProvider = Provider<List<ConversationPreview>>((ref) {
  return const [
    ConversationPreview(
      id: '623',
      status: ConversationStatus.open,
      preview: 'testing testing',
      ticket: 'No Ticket: 623',
      time: '13:04',
      unread: true,
    ),
    ConversationPreview(
      id: '619',
      status: ConversationStatus.open,
      preview: 'wkwk',
      ticket: 'No Ticket: 619',
      time: '12:47',
    ),
    ConversationPreview(
      id: '622',
      status: ConversationStatus.open,
      preview: 'Oke kak ada kendala apa di Komship...',
      ticket: 'No Ticket: 622',
      time: '12:46',
    ),
    ConversationPreview(
      id: '599',
      status: ConversationStatus.escalated,
      preview: 'outruncode2350',
      ticket: 'No Ticket: 599',
      time: '19 Agu 2026',
    ),
    ConversationPreview(
      id: '535',
      status: ConversationStatus.resolved,
      preview: 'hi',
      ticket: 'No Ticket: 535',
      time: '11 Jun 2026',
    ),
    ConversationPreview(
      id: '387',
      status: ConversationStatus.cancelled,
      preview: 'send a file',
      ticket: 'No Ticket: 387',
      time: '3 Jun 2026',
    ),
  ];
});

final messagesProvider = Provider.family<List<ChatMessage>, String>((ref, id) {
  if (id == '623') {
    return const [
      ChatMessage(
        time: '13:04',
        variant: MessageBubbleVariant.incoming,
        contents: [TextContent('Oke kak ada kendala apa di Komcards?')],
      ),
      ChatMessage(
        time: '13:04',
        variant: MessageBubbleVariant.outgoing,
        contents: [TextContent('testing testing')],
      ),
      ChatMessage(
        time: '14:32',
        variant: MessageBubbleVariant.outgoing,
        contents: [
          AttachmentContent(
            AttachmentData(
              name: 'WhatsApp Image 2026-08-31',
              extension: 'jpg',
              size: '98 KB',
              kind: AttachmentKind.image,
            ),
          ),
        ],
      ),
      ChatMessage(
        time: '14:32',
        variant: MessageBubbleVariant.outgoing,
        contents: [
          AttachmentContent(
            AttachmentData(
              name: '[Connect To Websocket]...',
              extension: 'docx',
              size: '0.01 MB',
              kind: AttachmentKind.document,
            ),
          ),
        ],
      ),
    ];
  }
  return const [
    ChatMessage(
      time: '07:00',
      variant: MessageBubbleVariant.incoming,
      contents: [TextContent('Halo Ryan OkSa, Kamu sedang ada kendala apa?')],
    ),
  ];
});
