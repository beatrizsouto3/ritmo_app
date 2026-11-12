enum FlashcardRating { again, hard, good, easy }

extension FlashcardRatingLabel on FlashcardRating {
  String get label => switch (this) {
    FlashcardRating.again => 'Errei',
    FlashcardRating.hard => 'Difícil',
    FlashcardRating.good => 'Bom',
    FlashcardRating.easy => 'Fácil',
  };
}
