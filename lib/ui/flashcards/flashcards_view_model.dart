import 'package:flutter/foundation.dart';

import '../../domain/models/flashcard.dart';
import '../../domain/models/flashcard_deck.dart';
import '../../domain/models/flashcard_rating.dart';
import '../../domain/models/review_schedule.dart';
import '../../data/repositories/flashcard_repository.dart';
import '../../core/errors/request_error.dart';

class DeckStatistics {
  const DeckStatistics({
    required this.total,
    required this.due,
    required this.newCards,
    required this.retained,
  });

  final int total;
  final int due;
  final int newCards;
  final int retained;
}

class FlashcardsViewModel extends ChangeNotifier {
  FlashcardsViewModel(this._repository);

  final FlashcardRepository _repository;
  List<FlashcardDeck> _decks = [];
  final Map<int, List<Flashcard>> _cardsByDeck = {};
  List<Flashcard> _reviewQueue = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  bool _isAnswerVisible = false;
  String? _errorMessage;
  String? _notice;
  int _reviewedCount = 0;
  int _reviewTotal = 0;

  List<FlashcardDeck> get decks => List.unmodifiable(_decks);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isBusy => _isLoading || _isSaving;
  bool get isAnswerVisible => _isAnswerVisible;
  String? get errorMessage => _errorMessage;
  String? get notice => _notice;
  int get reviewRemaining => _reviewQueue.length;
  int get reviewCompleted => _reviewedCount;
  int get reviewTotal => _reviewTotal;
  Flashcard? get activeReviewCard =>
      _reviewQueue.isEmpty ? null : _reviewQueue.first;

  List<Flashcard> cardsForDeck(int deckId) =>
      List.unmodifiable(_cardsByDeck[deckId] ?? []);

  FlashcardDeck? deckById(int deckId) {
    for (final deck in _decks) {
      if (deck.id == deckId) return deck;
    }
    return null;
  }

  DeckStatistics statisticsForDeck(int deckId, {DateTime? at}) {
    final now = at ?? DateTime.now();
    final cards = _cardsByDeck[deckId] ?? [];
    final due = cards.where((card) => card.isDueAt(now)).length;
    return DeckStatistics(
      total: cards.length,
      due: due,
      newCards: cards
          .where((card) => card.repetitions == 0 && card.isDueAt(now))
          .length,
      retained: cards.length - due,
    );
  }

  String reviewIntervalLabel(FlashcardRating rating) {
    final card = activeReviewCard;
    if (card == null) return '';
    final now = DateTime.now();
    final schedule = const ReviewScheduleCalculator().calculate(
      card: card,
      rating: rating,
      reviewedAt: now,
    );
    if (schedule.intervalDays == 0) {
      return '${schedule.nextReviewAt.difference(now).inMinutes} min';
    }
    return schedule.intervalDays == 1
        ? '1 dia'
        : '${schedule.intervalDays} dias';
  }

  Future<void> loadDecks() async {
    if (_isDisposed || isBusy) return;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final decks = await _repository.getDecks();
      final cards = await Future.wait(
        decks.map((deck) => _repository.getCards(deck.id)),
      );
      if (_isDisposed) return;
      _decks = decks;
      _cardsByDeck.clear();
      for (var index = 0; index < decks.length; index++) {
        _cardsByDeck[decks[index].id] = cards[index];
      }
    } catch (error, stackTrace) {
      _errorMessage = requestErrorMessage(error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> loadCardsForDeck(int deckId) async {
    if (_isDisposed || isBusy) return;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final cards = await _repository.getCards(deckId);
      if (!_isDisposed) _cardsByDeck[deckId] = cards;
    } catch (error, stackTrace) {
      _errorMessage = requestErrorMessage(error, stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<bool> createDeck({required String name, String? description}) =>
      _save(() async {
        final deck = await _repository.createDeck(
          name: name,
          description: description,
        );
        if (_isDisposed) return;
        _decks = [deck, ..._decks];
        _cardsByDeck[deck.id] = [];
        _notice = 'Baralho criado.';
      });

  Future<bool> updateDeck(FlashcardDeck deck) => _save(() async {
    final updated = await _repository.updateDeck(deck);
    if (_isDisposed) return;
    _decks = _decks
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    _notice = 'Baralho atualizado.';
  });

  Future<bool> deleteDeck(int deckId) => _save(() async {
    await _repository.deleteDeck(deckId);
    if (_isDisposed) return;
    _decks = _decks.where((deck) => deck.id != deckId).toList();
    _cardsByDeck.remove(deckId);
    _notice = 'Baralho excluído.';
  });

  Future<bool> createCard({
    required int deckId,
    required String front,
    required String back,
    String? imageUrl,
  }) => _save(() async {
    final card = await _repository.createCard(
      deckId: deckId,
      front: front,
      back: back,
      imageUrl: imageUrl,
    );
    if (_isDisposed) return;
    _cardsByDeck[deckId] = [...cardsForDeck(deckId), card];
    _notice = 'Cartão criado. Ele já está pronto para uma revisão.';
  });

  Future<bool> updateCard(Flashcard card) => _save(() async {
    final updated = await _repository.updateCard(card);
    if (_isDisposed) return;
    _cardsByDeck[updated.deckId] = cardsForDeck(updated.deckId)
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    _notice = 'Cartão atualizado.';
  });

  Future<bool> deleteCard(int cardId) => _save(() async {
    await _repository.deleteCard(cardId);
    if (_isDisposed) return;
    for (final id in _cardsByDeck.keys.toList()) {
      _cardsByDeck[id] = cardsForDeck(id)
          .where((card) => card.id != cardId)
          .toList();
    }
    _notice = 'Cartão excluído.';
  });

  Future<bool> startReview(int deckId, {DateTime? at}) async {
    if (_isDisposed || isBusy) return false;
    _isLoading = true;
    _errorMessage = null;
    _notice = null;
    _notify();
    try {
      final cards = await _repository.getDueCards(deckId, at: at);
      if (_isDisposed) return false;
      _reviewQueue = cards;
      _reviewedCount = 0;
      _reviewTotal = cards.length;
      _isAnswerVisible = false;
      if (cards.isEmpty) _notice = 'Não há cartões para revisar agora.';
      return cards.isNotEmpty;
    } catch (error, stackTrace) {
      _errorMessage = requestErrorMessage(error, stackTrace: stackTrace);
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void revealAnswer() {
    if (_isDisposed || isBusy || activeReviewCard == null) return;
    _isAnswerVisible = true;
    _notify();
  }

  Future<bool> rateCurrentCard(FlashcardRating rating) => _save(() async {
    final card = activeReviewCard;
    if (card == null || !_isAnswerVisible) {
      throw ArgumentError('Revele a resposta antes de avaliar.');
    }
    final review = await _repository.reviewCard(
      cardId: card.id,
      rating: rating,
    );
    if (_isDisposed) return;
    _cardsByDeck[card.deckId] = cardsForDeck(card.deckId)
        .map(
          (item) => item.id == card.id
              ? item.copyWith(
                  nextReviewAt: review.nextReviewAt,
                  intervalDays: review.intervalDays,
                  repetitions: review.repetitions,
                )
              : item,
        )
        .toList();
    _reviewQueue = _reviewQueue.skip(1).toList();
    _reviewedCount++;
    _isAnswerVisible = false;
    final date = review.nextReviewAt.toLocal();
    _notice = 'Próxima revisão: ${date.day}/${date.month}/${date.year}.';
  });

  void clearMessages() {
    _errorMessage = null;
    _notice = null;
    _notify();
  }

  Future<bool> _save(Future<void> Function() operation) async {
    if (_isDisposed || isBusy) return false;
    _isSaving = true;
    _errorMessage = null;
    _notice = null;
    _notify();
    try {
      await operation();
      return !_isDisposed;
    } catch (error, stackTrace) {
      _errorMessage = requestErrorMessage(error, stackTrace: stackTrace);
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _decks = [];
    _cardsByDeck.clear();
    _reviewQueue = [];
    super.dispose();
  }
}
