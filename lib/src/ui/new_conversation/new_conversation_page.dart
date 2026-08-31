import 'package:flutter/material.dart';

import '../shared/live_chat_header.dart';
import 'product_icon.dart';

class NewConversationPage extends StatelessWidget {
  const NewConversationPage({super.key, required this.onCreated});

  final ValueChanged<String> onCreated;

  @override
  Widget build(BuildContext context) {
    const products = [
      'Komads',
      'Komcards',
      'Komchat',
      'Kompack',
      'Komship',
      'Komtim',
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LiveChatHeader(
              showBack: true,
              onBack: () => Navigator.pop(context),
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
                children: [
                  const Text(
                    'Customer Service Agent',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Halo Ryan OkSa, Kamu sedang\nada kendala apa?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 21, height: 1.25),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Pilih produk yang ingin kamu tanyakan',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProductSelectionTile(
                        product: product,
                        onTap: () => onCreated('new-$product'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSelectionTile extends StatelessWidget {
  const ProductSelectionTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  final String product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          ProductIcon(product: product),
          const SizedBox(width: 16),
          Expanded(child: Text(product, style: const TextStyle(fontSize: 20))),
          const Icon(Icons.chevron_right_rounded, size: 28),
        ],
      ),
    ),
  );
}
