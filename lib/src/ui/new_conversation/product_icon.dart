import 'package:flutter/material.dart';
import 'package:full_svg_flutter/full_svg_flutter.dart';

import '../live_chat_theme.dart';

class ProductIcon extends StatelessWidget {
  const ProductIcon({required this.product, super.key});

  final String product;

  static const assets = <String, String>{
    'Komads': 'assets/icons/komads.svg',
    'Komcards': 'assets/icons/komcards.svg',
    'Komchat': 'assets/icons/komchat.svg',
    'Kompack': 'assets/icons/kompack.svg',
    'Komship': 'assets/icons/komship.svg',
    'Komtim': 'assets/icons/komtim.svg',
    'Komplace': 'assets/icons/komplace.svg',
    'RajaOngkir': 'assets/icons/rajaongkir.svg',
    'Open Api': 'assets/icons/rajaongkir.svg',
    'Affiliate': 'assets/icons/affiliate.svg',
  };

  @override
  Widget build(BuildContext context) {
    final asset = assets[product];
    if (asset == null) {
      return _fallbackIcon(product);
    }
    return FSvgPicture.asset(
      asset,
      width: 30,
      height: 30,
      fit: BoxFit.contain,
      semanticsLabel: '$product icon',
      placeholderBuilder: (_) => _fallbackIcon(product),
      errorBuilder: (_, error, stackTrace) => _fallbackIcon(product),
    );
  }

  Widget _fallbackIcon(String product) =>
      Icon(Icons.widgets_rounded, color: productColor(product), size: 30);
}

Color productColor(String product) =>
    <String, Color>{
      'Komads': Colors.grey,
      'Komcards': const Color(0xFF777777),
      'Komchat': const Color(0xFFE84B3B),
      'Kompack': const Color(0xFF3E7CF2),
      'Komship': const Color(0xFFF2B400),
      'Komtim': const Color(0xFF36A85A),
    }[product] ??
    LiveChatTheme.orange;
