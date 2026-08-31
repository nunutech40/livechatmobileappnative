import 'package:flutter/material.dart';

import '../live_chat_theme.dart';

class LiveChatHeader extends StatelessWidget {
  const LiveChatHeader({
    super.key,
    this.showBack = false,
    this.onBack,
    this.onClose,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiveChatTheme.orange,
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack,
              tooltip: 'Kembali',
              color: Colors.white,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Komerce',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            tooltip: 'Tutup Live Chat',
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              backgroundColor: const Color(0xFFFFF3EA),
              foregroundColor: LiveChatTheme.orange,
            ),
            icon: const Icon(Icons.close_rounded, size: 26),
          ),
        ],
      ),
    );
  }
}
