import 'flashcard.dart';
import 'flashcard_rating.dart';

class ReviewSchedule {
  const ReviewSchedule({
    required this.nextReviewAt,
    required this.intervalDays,
    required this.repetitions,
  });

  final DateTime nextReviewAt;
  final int intervalDays;
  final int repetitions;
}

class ReviewScheduleCalculator {
  const ReviewScheduleCalculator();

  ReviewSchedule calculate({
    required Flashcard card,
    required FlashcardRating rating,
    required DateTime reviewedAt,
  }) {
    if (rating == FlashcardRating.again) {
      return ReviewSchedule(
        nextReviewAt: reviewedAt.add(const Duration(minutes: 10)),
        intervalDays: 0,
        repetitions: 0,
      );
    }

    final int intervalDays = _nextInterval(card.intervalDays, rating);
    return ReviewSchedule(
      nextReviewAt: reviewedAt.add(Duration(days: intervalDays)),
      intervalDays: intervalDays,
      repetitions: card.repetitions + 1,
    );
  }

  int _nextInterval(int previousDays, FlashcardRating rating) {
    if (previousDays == 0) {
      return switch (rating) {
        FlashcardRating.again => 0,
        FlashcardRating.hard => 1,
        FlashcardRating.good => 3,
        FlashcardRating.easy => 7,
      };
    }

    final double factor = switch (rating) {
      FlashcardRating.again => 0,
      FlashcardRating.hard => 1.2,
      FlashcardRating.good => 2,
      FlashcardRating.easy => 2.5,
    };
    return (previousDays * factor).round().clamp(1, 3650).toInt();
  }
}
