import 'package:flutter/material.dart';

import '../live_chat_theme.dart';

class AgentAvatar extends StatelessWidget {
  const AgentAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(size * .25),
    ),
    child: Icon(
      Icons.support_agent_rounded,
      color: LiveChatTheme.orange,
      size: size * .55,
    ),
  );
}
