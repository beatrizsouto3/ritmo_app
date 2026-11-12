import '../../domain/models/flashcard.dart';
import '../../domain/models/flashcard_deck.dart';
import '../../domain/models/flashcard_rating.dart';
import '../../domain/models/flashcard_review.dart';
import '../../domain/models/review_schedule.dart';
import '../services/flashcard_contract.dart';
import '../services/flashcard_service.dart';

class FlashcardRepository {
  const FlashcardRepository(this._service);

  final FlashcardService _service;

  Future<List<FlashcardDeck>> getDecks() async {
    return (await _service.fetchDecks()).map(_deckFromRow).toList();
  }

  Future<FlashcardDeck> createDeck({
    required String name,
    String? description,
  }) async {
    _validateDeck(name, description);
    return _deckFromRow(
      await _service.createDeck(
        name: name.trim(),
        description: _optionalText(description),
      ),
    );
  }

  Future<FlashcardDeck> updateDeck(FlashcardDeck deck) async {
    _validateDeck(deck.name, deck.description);
    return _deckFromRow(
      await _service.updateDeck(
        deck.id,
        name: deck.name.trim(),
        description: _optionalText(deck.description),
      ),
    );
  }

  Future<void> deleteDeck(int deckId) => _service.deleteDeck(deckId);

  Future<List<Flashcard>> getCards(int deckId) async {
    return (await _service.fetchCardsForDeck(deckId))
        .map(_cardFromRow)
        .toList();
  }

  Future<Flashcard> createCard({
    required int deckId,
    required String front,
    required String back,
    String? imageUrl,
  }) async {
    _validateCard(front, back, imageUrl);
    return _cardFromRow(
      await _service.createCard(
        deckId: deckId,
        front: front.trim(),
        back: back.trim(),
        imageUrl: _optionalText(imageUrl),
      ),
    );
  }

  Future<Flashcard> updateCard(Flashcard card) async {
    _validateCard(card.front, card.back, card.imageUrl);
    return _cardFromRow(
      await _service.updateCard(
        card.id,
        front: card.front.trim(),
        back: card.back.trim(),
        imageUrl: _optionalText(card.imageUrl),
      ),
    );
  }

  Future<void> deleteCard(int cardId) => _service.deleteCard(cardId);

  Future<List<Flashcard>> getDueCards(int deckId, {DateTime? at}) async {
    return (await _service.fetchCardsForDeck(
      deckId,
      dueAt: at ?? DateTime.now(),
    )).map(_cardFromRow).toList();
  }

  Future<FlashcardReview> reviewCard({
    required int cardId,
    required FlashcardRating rating,
    DateTime? reviewedAt,
  }) async {
    final card = _cardFromRow(await _service.fetchCard(cardId));
    final time = reviewedAt ?? DateTime.now();
    if (!card.isDueAt(time)) {
      throw ArgumentError('Este cartão já foi agendado. Recarregue o baralho.');
    }
    final schedule = const ReviewScheduleCalculator().calculate(
      card: card,
      rating: rating,
      reviewedAt: time,
    );
    final row = await _service.recordReview({
      'p_card_id': cardId,
      'p_rating': rating.name,
      'p_expected_next_review_at': card.nextReviewAt.toUtc().toIso8601String(),
      'p_expected_interval_days': card.intervalDays,
      'p_expected_repetitions': card.repetitions,
      'p_reviewed_at': time.toUtc().toIso8601String(),
      'p_next_review_at': schedule.nextReviewAt.toUtc().toIso8601String(),
      'p_interval_days': schedule.intervalDays,
      'p_repetitions': schedule.repetitions,
    });
    return _reviewFromRow(row);
  }

  Future<List<FlashcardReview>> getReviewHistory(int cardId) async {
    return (await _service.fetchReviewHistory(cardId))
        .map(_reviewFromRow)
        .toList();
  }

  void _validateDeck(String name, String? description) {
    if (name.trim().isEmpty || name.trim().length > 60) {
      throw ArgumentError('Informe um nome de baralho com até 60 caracteres.');
    }
    if ((description?.trim().length ?? 0) > 120) {
      throw ArgumentError('Use uma descrição com até 120 caracteres.');
    }
  }

  void _validateCard(String front, String back, String? imageUrl) {
    if (front.trim().isEmpty || back.trim().isEmpty) {
      throw ArgumentError('Preencha a frente e o verso do cartão.');
    }
    if (front.trim().length > 500 || back.trim().length > 1000) {
      throw ArgumentError('Use até 500 caracteres na frente e 1000 no verso.');
    }
    final url = _optionalText(imageUrl);
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme)) {
        throw ArgumentError(
          'Informe uma URL de imagem iniciada por http:// ou https://.',
        );
      }
    }
  }

  String? _optionalText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  FlashcardDeck _deckFromRow(Map<String, Object?> row) => FlashcardDeck(
    id: row[FlashcardContract.idColumn] as int,
    name: row[FlashcardContract.nameColumn] as String,
    description: row[FlashcardContract.descriptionColumn] as String?,
    createdAt: DateTime.parse(row[FlashcardContract.createdAtColumn] as String),
  );

  Flashcard _cardFromRow(Map<String, Object?> row) => Flashcard(
    id: row[FlashcardContract.idColumn] as int,
    deckId: row[FlashcardContract.deckIdColumn] as int,
    front: row[FlashcardContract.frontColumn] as String,
    back: row[FlashcardContract.backColumn] as String,
    imageUrl: row[FlashcardContract.imageUrlColumn] as String?,
    createdAt: DateTime.parse(row[FlashcardContract.createdAtColumn] as String),
    nextReviewAt: DateTime.parse(
      row[FlashcardContract.nextReviewAtColumn] as String,
    ),
    intervalDays: row[FlashcardContract.intervalDaysColumn] as int,
    repetitions: row[FlashcardContract.repetitionsColumn] as int,
  );

  FlashcardReview _reviewFromRow(Map<String, Object?> row) => FlashcardReview(
    id: row[FlashcardContract.idColumn] as int,
    flashcardId: row[FlashcardContract.cardIdColumn] as int,
    rating: FlashcardRating.values.byName(
      row[FlashcardContract.ratingColumn] as String,
    ),
    reviewedAt: DateTime.parse(
      row[FlashcardContract.reviewedAtColumn] as String,
    ),
    nextReviewAt: DateTime.parse(
      row[FlashcardContract.nextReviewAtColumn] as String,
    ),
    intervalDays: row[FlashcardContract.intervalDaysColumn] as int,
    repetitions: row[FlashcardContract.repetitionsColumn] as int,
  );
}
