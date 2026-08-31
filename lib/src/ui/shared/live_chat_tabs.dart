import 'package:flutter/material.dart';

import '../../models/chat_models.dart';
import '../live_chat_theme.dart';

class LiveChatTabs extends StatelessWidget {
  const LiveChatTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.unreadCount = 0,
  });

  final LiveChatTab selectedTab;
  final ValueChanged<LiveChatTab> onTabChanged;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Percakapan',
            selected: selectedTab == LiveChatTab.conversations,
            badge: unreadCount,
            onTap: () => onTabChanged(LiveChatTab.conversations),
          ),
          _TabItem(
            label: 'Artikel',
            selected: selectedTab == LiveChatTab.articles,
            onTap: () => onTabChanged(LiveChatTab.articles),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? [
                      const BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 7,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? LiveChatTheme.ink : LiveChatTheme.muted,
                  ),
                ),
                if (badge != null && badge! > 0) ...[
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF04449),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
