import 'package:flutter/material.dart';

import '../live_chat_theme.dart';

class RatingPreview extends StatefulWidget {
  const RatingPreview({super.key, this.onSubmit});

  final void Function(int rating, String note)? onSubmit;

  @override
  State<RatingPreview> createState() => _RatingPreviewState();
}

class _RatingPreviewState extends State<RatingPreview> {
  final _noteController = TextEditingController();
  int? _selectedRating;
  bool _submitted = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
    ),
    child: _submitted
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'Terima kasih atas penilaianmu!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          )
        : Column(
            children: [
              const Text(
                'Bagaimana layanan kami?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Berikan penilaian untuk percakapan ini',
                style: TextStyle(color: LiveChatTheme.muted),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return Semantics(
                    button: true,
                    label: 'Rating $rating dari 5',
                    selected: _selectedRating == rating,
                    child: InkWell(
                      onTap: () => setState(() => _selectedRating = rating),
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          ['😠', '🙁', '😐', '😊', '😍'][index],
                          style: TextStyle(
                            fontSize: 28,
                            color: _selectedRating == rating
                                ? LiveChatTheme.orange
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Bagaimana pengalamanmu? (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedRating == null
                      ? null
                      : () {
                          widget.onSubmit?.call(
                            _selectedRating!,
                            _noteController.text.trim(),
                          );
                          setState(() => _submitted = true);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: LiveChatTheme.orange,
                  ),
                  child: const Text('Kirim Penilaian'),
                ),
              ),
            ],
          ),
  );
}
