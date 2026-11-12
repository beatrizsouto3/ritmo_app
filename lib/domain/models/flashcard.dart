class Flashcard {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.imageUrl,
    required this.createdAt,
    required this.nextReviewAt,
    this.intervalDays = 0,
    this.repetitions = 0,
  });

  final int id;
  final int deckId;
  final String front;
  final String back;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime nextReviewAt;
  final int intervalDays;
  final int repetitions;

  bool isDueAt(DateTime time) => !nextReviewAt.isAfter(time);

  Flashcard copyWith({
    String? front,
    String? back,
    String? imageUrl,
    bool clearImageUrl = false,
    DateTime? nextReviewAt,
    int? intervalDays,
    int? repetitions,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
    );
  }
}
