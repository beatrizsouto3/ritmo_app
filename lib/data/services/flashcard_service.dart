import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard_rating.dart';
import '../models/flashcard_review.dart';
import '../models/review_schedule.dart';

/// Fonte provisória em memória enquanto a camada SQLite é integrada.
///
/// O contrato da classe permite trocar esta implementação por uma fonte SQL
/// sem mudar o ViewModel ou as Views. Os dados atuais se perdem ao encerrar o
/// processo, portanto esta implementação não é o critério final de persistência.
class FlashcardService {
  FlashcardService({ReviewScheduleCalculator? scheduleCalculator})
    : _scheduleCalculator =
          scheduleCalculator ?? const ReviewScheduleCalculator();

  final ReviewScheduleCalculator _scheduleCalculator;
  final Map<int, FlashcardDeck> _decks = {};
  final Map<int, Flashcard> _cards = {};
  final List<FlashcardReview> _reviews = [];
  int _nextDeckId = 1;
  int _nextCardId = 1;
  int _nextReviewId = 1;

  Future<List<FlashcardDeck>> fetchDecks() async {
    final decks = _decks.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return decks;
  }

  Future<FlashcardDeck> createDeck({
    required String name,
    String? description,
    DateTime? createdAt,
  }) async {
    final deck = FlashcardDeck(
      id: _nextDeckId++,
      name: name.trim(),
      description: _normalizeOptionalText(description),
      createdAt: createdAt ?? DateTime.now(),
    );
    _decks[deck.id] = deck;
    return deck;
  }

  Future<FlashcardDeck> updateDeck(FlashcardDeck deck) async {
    if (!_decks.containsKey(deck.id)) {
      throw StateError('O baralho não foi encontrado.');
    }
    final updated = deck.copyWith(
      name: deck.name.trim(),
      description: _normalizeOptionalText(deck.description),
      clearDescription: _normalizeOptionalText(deck.description) == null,
    );
    _decks[deck.id] = updated;
    return updated;
  }

  Future<void> deleteDeck(int deckId) async {
    if (_decks.remove(deckId) == null) {
      return;
    }
    final cardIds = _cards.values
        .where((card) => card.deckId == deckId)
        .map((card) => card.id)
        .toSet();
    _cards.removeWhere((_, card) => card.deckId == deckId);
    _reviews.removeWhere((review) => cardIds.contains(review.flashcardId));
  }

  Future<List<Flashcard>> fetchCardsForDeck(int deckId) async {
    if (!_decks.containsKey(deckId)) {
      throw StateError('O baralho não foi encontrado.');
    }
    final cards = _cards.values.where((card) => card.deckId == deckId).toList()
      ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return cards;
  }

  Future<Flashcard> createCard({
    required int deckId,
    required String front,
    required String back,
    String? imageUrl,
    DateTime? createdAt,
  }) async {
    if (!_decks.containsKey(deckId)) {
      throw StateError('O baralho selecionado não existe.');
    }
    final now = createdAt ?? DateTime.now();
    final card = Flashcard(
      id: _nextCardId++,
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
      imageUrl: _normalizeOptionalText(imageUrl),
      createdAt: now,
      nextReviewAt: now,
    );
    _cards[card.id] = card;
    return card;
  }

  Future<Flashcard> updateCard(Flashcard card) async {
    if (!_cards.containsKey(card.id)) {
      throw StateError('O cartão não foi encontrado.');
    }
    if (!_decks.containsKey(card.deckId)) {
      throw StateError('O baralho selecionado não existe.');
    }
    _cards[card.id] = card.copyWith(
      front: card.front.trim(),
      back: card.back.trim(),
      imageUrl: _normalizeOptionalText(card.imageUrl),
      clearImageUrl: _normalizeOptionalText(card.imageUrl) == null,
    );
    return _cards[card.id]!;
  }

  Future<void> deleteCard(int cardId) async {
    _cards.remove(cardId);
    _reviews.removeWhere((review) => review.flashcardId == cardId);
  }

  Future<List<Flashcard>> fetchDueCards(int deckId, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    final cards = await fetchCardsForDeck(deckId);
    return cards.where((card) => card.isDueAt(now)).toList();
  }

  Future<FlashcardReview> recordReview({
    required int cardId,
    required FlashcardRating rating,
    DateTime? reviewedAt,
  }) async {
    final card = _cards[cardId];
    if (card == null) {
      throw StateError('O cartão não foi encontrado.');
    }
    final now = reviewedAt ?? DateTime.now();
    final schedule = _scheduleCalculator.calculate(
      card: card,
      rating: rating,
      reviewedAt: now,
    );
    _cards[cardId] = card.copyWith(
      nextReviewAt: schedule.nextReviewAt,
      intervalDays: schedule.intervalDays,
      repetitions: schedule.repetitions,
    );
    final review = FlashcardReview(
      id: _nextReviewId++,
      flashcardId: cardId,
      rating: rating,
      reviewedAt: now,
      nextReviewAt: schedule.nextReviewAt,
      intervalDays: schedule.intervalDays,
    );
    _reviews.add(review);
    return review;
  }

  Future<List<FlashcardReview>> fetchReviewHistory(int cardId) async {
    return _reviews.where((review) => review.flashcardId == cardId).toList()
      ..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
  }

  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
