import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chat_models.dart';
import '../../application/state/live_chat_fixture_providers.dart';
import '../live_chat_theme.dart';
import '../shared/agent_avatar.dart';

class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({
    super.key,
    required this.onConversationTap,
    required this.onNewChat,
    this.conversations,
    this.isLoading = false,
  });

  final ValueChanged<ConversationPreview> onConversationTap;
  final VoidCallback onNewChat;
  final List<ConversationPreview>? conversations;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ConversationPreview> resolvedConversations =
        conversations ?? ref.watch(conversationsProvider);
    final conversationCards = resolvedConversations
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ConversationCard(
              conversation: item,
              onTap: () => onConversationTap(item),
            ),
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const Text(
          'Mulai Pesan Baru',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        NewChatCard(onPressed: onNewChat),
        const SizedBox(height: 32),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Baru-baru ini',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Buat Pesan Baru'),
              style: TextButton.styleFrom(
                foregroundColor: LiveChatTheme.orange,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 20),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ...conversationCards,
      ],
    );
  }
}

class NewChatCard extends StatelessWidget {
  const NewChatCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E1E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AgentAvatar(size: 58),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Agent kami siap membalas\npesanmu secepatnya.',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.send_rounded, size: 22),
            label: const Text('Buat Pesan Baru'),
            style: FilledButton.styleFrom(
              backgroundColor: LiveChatTheme.orange,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ConversationPreview conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _statusLabel(conversation.status),
                  style: TextStyle(
                    color: _statusColor(conversation.status),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (conversation.unread)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: LiveChatTheme.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Text(
                    conversation.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(conversation.ticket, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                Text(conversation.time, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(ConversationStatus status) => switch (status) {
  ConversationStatus.open => 'Open',
  ConversationStatus.handling => 'Handling',
  ConversationStatus.escalated => 'Escalated',
  ConversationStatus.resolved => 'Resolved',
  ConversationStatus.cancelled => 'Cancelled',
};

Color _statusColor(ConversationStatus status) => switch (status) {
  ConversationStatus.open => const Color(0xFF2864E8),
  ConversationStatus.handling => const Color(0xFF2864E8),
  ConversationStatus.escalated => LiveChatTheme.orange,
  ConversationStatus.resolved => const Color(0xFF13A44A),
  ConversationStatus.cancelled => const Color(0xFFF04449),
};
