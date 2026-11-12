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

  Map<String, Object?> toMap() => {
    'id': id,
    'baralho_id': deckId,
    'frente': front,
    'verso': back,
    'imagem_url': imageUrl,
    'criado_em': createdAt.toIso8601String(),
    'proxima_revisao_em': nextReviewAt.toIso8601String(),
    'intervalo_dias': intervalDays,
    'repeticoes': repetitions,
  };

  factory Flashcard.fromMap(Map<String, Object?> map) {
    return Flashcard(
      id: map['id'] as int,
      deckId: map['baralho_id'] as int,
      front: map['frente'] as String,
      back: map['verso'] as String,
      imageUrl: map['imagem_url'] as String?,
      createdAt: DateTime.parse(map['criado_em'] as String),
      nextReviewAt: DateTime.parse(map['proxima_revisao_em'] as String),
      intervalDays: map['intervalo_dias'] as int? ?? 0,
      repetitions: map['repeticoes'] as int? ?? 0,
    );
  }
}
