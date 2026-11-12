import 'package:flutter/foundation.dart';

import '../../data/models/flashcard.dart';
import '../../data/models/flashcard_deck.dart';
import '../../data/models/flashcard_rating.dart';
import '../../data/repositories/flashcard_repository.dart';

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
  List<FlashcardDeck> _decks = const [];
  final Map<int, List<Flashcard>> _cardsByDeck = {};
  List<Flashcard> _reviewQueue = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isAnswerVisible = false;
  String? _errorMessage;
  String? _notice;
  int _reviewedCount = 0;
  int _reviewTotal = 0;

  List<FlashcardDeck> get decks => List.unmodifiable(_decks);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isAnswerVisible => _isAnswerVisible;
  String? get errorMessage => _errorMessage;
  String? get notice => _notice;
  int get reviewRemaining => _reviewQueue.length;
  int get reviewCompleted => _reviewedCount;
  int get reviewTotal => _reviewTotal;
  Flashcard? get activeReviewCard =>
      _reviewQueue.isEmpty ? null : _reviewQueue.first;

  List<Flashcard> cardsForDeck(int deckId) =>
      List.unmodifiable(_cardsByDeck[deckId] ?? const []);

  FlashcardDeck? deckById(int deckId) {
    for (final deck in _decks) {
      if (deck.id == deckId) return deck;
    }
    return null;
  }

  DeckStatistics statisticsForDeck(int deckId, {DateTime? at}) {
    final now = at ?? DateTime.now();
    final cards = _cardsByDeck[deckId] ?? const <Flashcard>[];
    final due = cards.where((card) => card.isDueAt(now)).length;
    final newCards = cards
        .where((card) => card.repetitions == 0 && card.isDueAt(now))
        .length;
    return DeckStatistics(
      total: cards.length,
      due: due,
      newCards: newCards,
      retained: cards.length - due,
    );
  }

  Future<void> loadDecks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _reloadDeckData();
    } catch (error) {
      _errorMessage = 'Não foi possível carregar os baralhos: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCardsForDeck(int deckId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _cardsByDeck[deckId] = await _repository.getCards(deckId);
    } catch (error) {
      _errorMessage = 'Não foi possível carregar os cartões: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDeck({required String name, String? description}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      _errorMessage = 'Informe um nome para o baralho.';
      notifyListeners();
      return false;
    }
    return _save(() async {
      await _repository.createDeck(
        name: normalizedName,
        description: description,
      );
      await _reloadDeckData();
      _notice = 'Baralho criado.';
    });
  }

  Future<bool> updateDeck(FlashcardDeck deck) async {
    if (deck.name.trim().isEmpty) {
      _errorMessage = 'Informe um nome para o baralho.';
      notifyListeners();
      return false;
    }
    return _save(() async {
      await _repository.updateDeck(deck);
      await _reloadDeckData();
      _notice = 'Baralho atualizado.';
    });
  }

  Future<bool> deleteDeck(int deckId) async {
    return _save(() async {
      await _repository.deleteDeck(deckId);
      await _reloadDeckData();
      _notice = 'Baralho excluído.';
    });
  }

  Future<bool> createCard({
    required int deckId,
    required String front,
    required String back,
    String? imageUrl,
  }) async {
    if (front.trim().isEmpty || back.trim().isEmpty) {
      _errorMessage = 'Preencha a frente e o verso do cartão.';
      notifyListeners();
      return false;
    }
    return _save(() async {
      await _repository.createCard(
        deckId: deckId,
        front: front,
        back: back,
        imageUrl: imageUrl,
      );
      await _reloadDeckData();
      _notice = 'Cartão criado. Ele já está pronto para uma revisão.';
    });
  }

  Future<bool> updateCard(Flashcard card) async {
    if (card.front.trim().isEmpty || card.back.trim().isEmpty) {
      _errorMessage = 'Preencha a frente e o verso do cartão.';
      notifyListeners();
      return false;
    }
    return _save(() async {
      await _repository.updateCard(card);
      await _reloadDeckData();
      _notice = 'Cartão atualizado.';
    });
  }

  Future<bool> deleteCard(int cardId) async {
    return _save(() async {
      await _repository.deleteCard(cardId);
      await _reloadDeckData();
      _notice = 'Cartão excluído.';
    });
  }

  Future<bool> startReview(int deckId, {DateTime? at}) async {
    _isLoading = true;
    _errorMessage = null;
    _notice = null;
    notifyListeners();
    try {
      _reviewQueue = await _repository.getDueCards(deckId, at: at);
      _reviewedCount = 0;
      _reviewTotal = _reviewQueue.length;
      _isAnswerVisible = false;
      if (_reviewQueue.isEmpty) {
        _notice = 'Não há cartões para revisar agora.';
        return false;
      }
      return true;
    } catch (error) {
      _errorMessage = 'Não foi possível iniciar a revisão: $error';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void revealAnswer() {
    if (activeReviewCard == null) return;
    _isAnswerVisible = true;
    notifyListeners();
  }

  Future<bool> rateCurrentCard(FlashcardRating rating) async {
    final card = activeReviewCard;
    if (card == null || !_isAnswerVisible) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final review = await _repository.reviewCard(
        cardId: card.id,
        rating: rating,
      );
      _reviewQueue = _reviewQueue.skip(1).toList();
      _reviewedCount++;
      _isAnswerVisible = false;
      _notice = 'Próxima revisão: ${_formatDateTime(review.nextReviewAt)}.';
      await _reloadDeckData();
      return true;
    } catch (error) {
      _errorMessage = 'Não foi possível salvar a avaliação: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _notice = null;
    notifyListeners();
  }

  Future<bool> _save(Future<void> Function() operation) async {
    _isSaving = true;
    _errorMessage = null;
    _notice = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } catch (error) {
      _errorMessage = 'Não foi possível salvar: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _reloadDeckData() async {
    _decks = await _repository.getDecks();
    final cardLists = await Future.wait(
      _decks.map((deck) => _repository.getCards(deck.id)),
    );
    _cardsByDeck
      ..clear()
      ..addEntries([
        for (var index = 0; index < _decks.length; index++)
          MapEntry(_decks[index].id, cardLists[index]),
      ]);
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }
}
