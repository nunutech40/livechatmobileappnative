import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../../domain/models/chat_models.dart';
import '../live_chat_theme.dart';
import '../shared/agent_avatar.dart';

class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E2E2)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: const TextStyle(color: LiveChatTheme.muted, fontSize: 16),
      ),
    ),
  );
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.onDownload});
  final ChatMessage message;
  final ValueChanged<AttachmentData>? onDownload;

  @override
  Widget build(BuildContext context) {
    final outgoing = message.variant == MessageBubbleVariant.outgoing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: outgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!outgoing)
            const Padding(
              padding: EdgeInsets.only(left: 58, bottom: 6),
              child: Text(
                'Customer Service Agent',
                style: TextStyle(fontSize: 16),
              ),
            ),
          Row(
            mainAxisAlignment: outgoing
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!outgoing)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: AgentAvatar(size: 48),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: outgoing
                        ? LiveChatTheme.peach
                        : const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(17),
                      topRight: const Radius.circular(17),
                      bottomLeft: Radius.circular(outgoing ? 17 : 2),
                      bottomRight: Radius.circular(outgoing ? 2 : 17),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(message.contents.length, (index) {
                      final content = message.contents[index];
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                        child: MessageContentView(
                          content: content,
                          onDownload: onDownload,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: outgoing ? 0 : 58,
              right: outgoing ? 4 : 0,
              top: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: const TextStyle(
                    color: LiveChatTheme.muted,
                    fontSize: 14,
                  ),
                ),
                if (outgoing)
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(
                      Icons.done_all_rounded,
                      color: LiveChatTheme.orange,
                      size: 17,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageContentView extends StatelessWidget {
  const MessageContentView({super.key, required this.content, this.onDownload});

  final MessageContent content;
  final ValueChanged<AttachmentData>? onDownload;

  @override
  Widget build(BuildContext context) => switch (content) {
    TextContent(:final value) => Text(
      value,
      style: const TextStyle(fontSize: 19, height: 1.3),
    ),
    AttachmentContent(:final data) => AttachmentCard(
      data: data,
      onDownload: onDownload,
    ),
    UnsupportedContent(:final label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline_rounded, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    ),
  };
}

class AttachmentCard extends StatelessWidget {
  const AttachmentCard({super.key, required this.data, this.onDownload});
  final AttachmentData data;
  final ValueChanged<AttachmentData>? onDownload;

  @override
  Widget build(BuildContext context) {
    if (data.kind == AttachmentKind.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: AspectRatio(
          aspectRatio: 0.82,
          child: data.bytes != null
              ? Image.memory(data.bytes!, fit: BoxFit.cover)
              : CustomPaint(
                  painter: _MockQrPainter(),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 100,
                      color: Colors.black54,
                    ),
                  ),
                ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              data.extension.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4C83E8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${data.size} • ${data.extension.toUpperCase()}',
                  style: const TextStyle(
                    color: LiveChatTheme.muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDownload == null ? null : () => onDownload!(data),
            tooltip: 'Unduh lampiran',
            icon: const Icon(
              Icons.download_rounded,
              color: LiveChatTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paper = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, paper);
    final accent = Paint()..color = const Color(0xFFFF2D4D);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .2)
        ..lineTo(size.width * .2, size.height * .33)
        ..lineTo(0, size.height * .47)
        ..close(),
      accent,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height * .75)
        ..lineTo(size.width * .72, size.height)
        ..lineTo(size.width, size.height)
        ..close(),
      accent,
    );
    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AttachmentMenu extends StatelessWidget {
  const AttachmentMenu({
    super.key,
    required this.onPhotoTap,
    required this.onFileTap,
  });

  final VoidCallback onPhotoTap;
  final VoidCallback onFileTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 18, bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14)],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: onPhotoTap,
          leading: Icon(Icons.image_outlined),
          title: Text('Tambah Foto'),
        ),
        ListTile(
          onTap: onFileTap,
          leading: Icon(Icons.insert_drive_file_outlined),
          title: Text('Tambah File'),
        ),
      ],
    ),
  );
}

class PendingAttachmentPreview extends StatelessWidget {
  const PendingAttachmentPreview({
    super.key,
    required this.data,
    required this.onRemove,
  });

  final AttachmentData data;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: LiveChatTheme.orange,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          if (data.kind == AttachmentKind.image)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: data.bytes != null
                  ? Image.memory(data.bytes!, fit: BoxFit.cover)
                  : const Icon(Icons.image_outlined, size: 30),
            )
          else
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                data.extension.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF4C83E8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '31 Aug 2026 • ${data.size}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            color: Colors.white,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class EmojiPickerPanel extends StatelessWidget {
  const EmojiPickerPanel({
    required this.controller,
    required this.onEmojiSelected,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onEmojiSelected;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: EmojiPicker(
      textEditingController: controller,
      onEmojiSelected: (category, emoji) => onEmojiSelected(),
      config: Config(
        height: 310,
        emojiViewConfig: const EmojiViewConfig(
          columns: 8,
          emojiSizeMax: 29,
          backgroundColor: Color(0xFFFAFAFA),
          verticalSpacing: 6,
          horizontalSpacing: 2,
          gridPadding: EdgeInsets.fromLTRB(12, 6, 12, 16),
        ),
        categoryViewConfig: const CategoryViewConfig(
          backgroundColor: Color(0xFFFAFAFA),
          indicatorColor: LiveChatTheme.blue,
          iconColor: LiveChatTheme.muted,
          iconColorSelected: LiveChatTheme.blue,
          backspaceColor: LiveChatTheme.muted,
          dividerColor: Color(0xFFE6E6E6),
        ),
        searchViewConfig: const SearchViewConfig(
          backgroundColor: Color(0xFFFAFAFA),
          buttonIconColor: LiveChatTheme.muted,
          hintText: 'Search',
          hintTextStyle: TextStyle(color: LiveChatTheme.muted, fontSize: 18),
        ),
        bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
      ),
    ),
  );
}

class ConversationEndedSection extends StatelessWidget {
  const ConversationEndedSection({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(20),
    child: Center(
      child: Text(
        'Sesi obrolan telah berakhir.',
        style: TextStyle(color: LiveChatTheme.muted, fontSize: 17),
      ),
    ),
  );
}
