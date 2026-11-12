import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard_rating.dart';
import '../models/flashcard_review.dart';
import '../services/flashcard_service.dart';

/// Fachada única da área de flashcards para os ViewModels.
/// A implementação do Service pode ser substituída pela versão SQLite.
class FlashcardRepository {
  const FlashcardRepository(this._service);

  final FlashcardService _service;

  Future<List<FlashcardDeck>> getDecks() => _service.fetchDecks();

  Future<FlashcardDeck> createDeck({
    required String name,
    String? description,
  }) {
    return _service.createDeck(name: name, description: description);
  }

  Future<FlashcardDeck> updateDeck(FlashcardDeck deck) {
    return _service.updateDeck(deck);
  }

  Future<void> deleteDeck(int deckId) => _service.deleteDeck(deckId);

  Future<List<Flashcard>> getCards(int deckId) {
    return _service.fetchCardsForDeck(deckId);
  }

  Future<Flashcard> createCard({
    required int deckId,
    required String front,
    required String back,
    String? imageUrl,
  }) {
    return _service.createCard(
      deckId: deckId,
      front: front,
      back: back,
      imageUrl: imageUrl,
    );
  }

  Future<Flashcard> updateCard(Flashcard card) => _service.updateCard(card);

  Future<void> deleteCard(int cardId) => _service.deleteCard(cardId);

  Future<List<Flashcard>> getDueCards(int deckId, {DateTime? at}) {
    return _service.fetchDueCards(deckId, at: at);
  }

  Future<FlashcardReview> reviewCard({
    required int cardId,
    required FlashcardRating rating,
    DateTime? reviewedAt,
  }) {
    return _service.recordReview(
      cardId: cardId,
      rating: rating,
      reviewedAt: reviewedAt,
    );
  }

  Future<List<FlashcardReview>> getReviewHistory(int cardId) {
    return _service.fetchReviewHistory(cardId);
  }
}
