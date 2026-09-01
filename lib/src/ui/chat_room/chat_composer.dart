import 'package:flutter/material.dart';

import '../../domain/models/chat_models.dart';
import '../live_chat_theme.dart';
import 'chat_room_components.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.showAttachmentMenu,
    required this.showEmojiPicker,
    required this.pendingAttachment,
    required this.onToggleAttachment,
    required this.onToggleEmoji,
    required this.onSend,
    required this.onPhotoTap,
    required this.onFileTap,
    required this.onRemoveAttachment,
    required this.onEmojiSelected,
  });

  final TextEditingController controller;
  final bool showAttachmentMenu;
  final bool showEmojiPicker;
  final AttachmentData? pendingAttachment;
  final VoidCallback onToggleAttachment;
  final VoidCallback onToggleEmoji;
  final VoidCallback onSend;
  final VoidCallback onPhotoTap;
  final VoidCallback onFileTap;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onEmojiSelected;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (showAttachmentMenu)
        AttachmentMenu(onPhotoTap: onPhotoTap, onFileTap: onFileTap),
      if (pendingAttachment != null)
        PendingAttachmentPreview(
          data: pendingAttachment!,
          onRemove: onRemoveAttachment,
        ),
      if (showEmojiPicker)
        EmojiPickerPanel(
          controller: controller,
          onEmojiSelected: onEmojiSelected,
        ),
      Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: onToggleAttachment,
              tooltip: 'Tambah lampiran',
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 36,
                color: LiveChatTheme.muted,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => onEmojiSelected(),
                decoration: InputDecoration(
                  hintText: 'Send a message...',
                  hintStyle: const TextStyle(
                    color: LiveChatTheme.muted,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F4),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(18, 13, 8, 13),
                  suffixIcon: IconButton(
                    onPressed: onToggleEmoji,
                    tooltip: 'Pilih emoji',
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: showEmojiPicker
                          ? LiveChatTheme.orange
                          : LiveChatTheme.muted,
                      size: 29,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            IconButton.filled(
              onPressed:
                  controller.text.trim().isEmpty && pendingAttachment == null
                  ? null
                  : onSend,
              tooltip: 'Kirim pesan',
              style: IconButton.styleFrom(
                fixedSize: const Size(58, 58),
                backgroundColor: LiveChatTheme.orange,
                disabledBackgroundColor: const Color(0xFFFFB494),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send_rounded, size: 28),
            ),
          ],
        ),
      ),
    ],
  );
}
