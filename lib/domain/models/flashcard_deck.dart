class FlashcardDeck {
  const FlashcardDeck({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;

  FlashcardDeck copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
  }) {
    return FlashcardDeck(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : description ?? this.description,
      createdAt: createdAt,
    );
  }
}
