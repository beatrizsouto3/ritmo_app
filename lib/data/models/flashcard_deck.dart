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

  Map<String, Object?> toMap() => {
    'id': id,
    'nome': name,
    'descricao': description,
    'criado_em': createdAt.toIso8601String(),
  };

  factory FlashcardDeck.fromMap(Map<String, Object?> map) {
    return FlashcardDeck(
      id: map['id'] as int,
      name: map['nome'] as String,
      description: map['descricao'] as String?,
      createdAt: DateTime.parse(map['criado_em'] as String),
    );
  }
}
