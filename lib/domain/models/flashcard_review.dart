import 'flashcard_rating.dart';

class FlashcardReview {
  const FlashcardReview({
    required this.id,
    required this.flashcardId,
    required this.rating,
    required this.reviewedAt,
    required this.nextReviewAt,
    required this.intervalDays,
    required this.repetitions,
  });

  final int id;
  final int flashcardId;
  final FlashcardRating rating;
  final DateTime reviewedAt;
  final DateTime nextReviewAt;
  final int intervalDays;
  final int repetitions;
}
