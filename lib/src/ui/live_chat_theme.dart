import 'package:flutter/material.dart';

class LiveChatTheme {
  static const orange = Color(0xFFFF5A16);
  static const peach = Color(0xFFFFE7D8);
  static const ink = Color(0xFF141414);
  static const muted = Color(0xFF777777);
  static const blue = Color(0xFF2864E8);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(seedColor: orange).copyWith(
      primary: orange,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: ink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Arial',
    );
  }
}
