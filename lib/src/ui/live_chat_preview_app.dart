import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live_chat_page.dart';
import 'live_chat_theme.dart';

class LiveChatPreviewApp extends StatelessWidget {
  const LiveChatPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Komerce Live Chat',
        theme: LiveChatTheme.theme,
        home: const LiveChatPage(),
      ),
    );
  }
}
