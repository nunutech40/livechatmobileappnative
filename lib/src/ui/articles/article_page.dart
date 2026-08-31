import 'package:flutter/material.dart';

import '../live_chat_theme.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, this.onArticleTap});

  final ValueChanged<String>? onArticleTap;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  static const _articles = [
    'Kirim Paket Ke Luar Negeri Pakai Komship',
    'Pengaturan Pembayaran Kompay dan Komship',
    'Cara Membagikan Akses Melalui Fitur Komerce',
  ];

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articles = _articles
        .where((title) => title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Cari pusat bantuan kami...',
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.clear_rounded),
                  ),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Artikel Terpopuler',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (articles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('Artikel tidak ditemukan')),
          ),
        ...articles.map(
          (title) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ArticleCard(
              title: title,
              onTap: () => widget.onArticleTap?.call(title),
            ),
          ),
        ),
      ],
    );
  }
}

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.title, this.onTap});
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(17),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E1E1)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: LiveChatTheme.peach,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'Komship',
              style: TextStyle(
                color: LiveChatTheme.orange,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pelajari panduan lengkap dan cara menggunakan fitur ini...',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: LiveChatTheme.muted,
              fontSize: 16,
              height: 1.25,
            ),
          ),
        ],
      ),
    ),
  );
}
