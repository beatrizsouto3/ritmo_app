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

/// Calcula intervalos simples e previsíveis para o protótipo do Ritmo.
///
/// Novos cartões: Errei = 10 min, Difícil = 1 dia, Bom = 3 dias, Fácil = 7
/// dias. Depois da primeira revisão, os intervalos crescem com fatores 1.2,
/// 2.0 e 2.5, respectivamente. Essa política pode ser substituída sem alterar
/// as Views quando a dupla decidir outra regra.
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
