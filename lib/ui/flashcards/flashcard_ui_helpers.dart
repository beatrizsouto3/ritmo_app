import 'package:flutter/material.dart';

const Color flashcardCanvas = Color(0xFFF8F9FF);
const Color flashcardNavy = Color(0xFF001C38);
const Color flashcardPrimary = Color(0xFF0A4174);
const Color flashcardSecondary = Color(0xFF33628A);
const Color flashcardTint = Color(0xFFE6EEFF);
const Color flashcardPaleBlue = Color(0xFFEFF4FF);
const Color flashcardOutline = Color(0xFFC2C6D1);

class FlashcardImagePreview extends StatelessWidget {
  const FlashcardImagePreview({
    required this.imageUrl,
    this.height = 150,
    super.key,
  });

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          alignment: Alignment.center,
          color: flashcardPaleBlue,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: flashcardSecondary),
              SizedBox(height: 6),
              Text('Não foi possível carregar a imagem.'),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashcardErrorMessage extends StatelessWidget {
  const FlashcardErrorMessage(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message!, style: const TextStyle(color: Color(0xFF93000A))),
    );
  }
}

class FlashcardEmptyState extends StatelessWidget {
  const FlashcardEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: flashcardSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: flashcardNavy, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
