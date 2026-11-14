import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/errors/request_error.dart';
import 'auth_service.dart';
import 'flashcard_contract.dart';

class FlashcardService {
  FlashcardService({
    required this.config,
    required this.client,
    required this.accessToken,
  });

  final SupabaseConfig config;
  final http.Client client;
  final Future<String> Function() accessToken;

  Future<List<Map<String, Object?>>> fetchDecks() {
    return _request(
      'GET',
      FlashcardContract.decksTable,
      query: {
        'select': '*',
        'order':
            '${FlashcardContract.createdAtColumn}.desc,${FlashcardContract.idColumn}.desc',
      },
    );
  }

  Future<Map<String, Object?>> createDeck({
    required String name,
    String? description,
  }) async {
    return _single(
      await _request(
        'POST',
        FlashcardContract.decksTable,
        body: {
          FlashcardContract.nameColumn: name,
          FlashcardContract.descriptionColumn: description,
        },
      ),
    );
  }

  Future<Map<String, Object?>> updateDeck(
    int id, {
    required String name,
    String? description,
  }) async {
    return _single(
      await _request(
        'PATCH',
        FlashcardContract.decksTable,
        query: {'id': 'eq.$id'},
        body: {
          FlashcardContract.nameColumn: name,
          FlashcardContract.descriptionColumn: description,
        },
      ),
    );
  }

  Future<void> deleteDeck(int id) async {
    _single(
      await _request(
        'DELETE',
        FlashcardContract.decksTable,
        query: {'id': 'eq.$id'},
      ),
    );
  }

  Future<List<Map<String, Object?>>> fetchCardsForDeck(
    int deckId, {
    DateTime? dueAt,
  }) {
    return _request(
      'GET',
      FlashcardContract.cardsTable,
      query: {
        'select': '*',
        FlashcardContract.deckIdColumn: 'eq.$deckId',
        'order':
            '${FlashcardContract.nextReviewAtColumn}.asc,${FlashcardContract.idColumn}.asc',
        if (dueAt != null)
          FlashcardContract.nextReviewAtColumn:
              'lte.${dueAt.toUtc().toIso8601String()}',
      },
    );
  }

  Future<Map<String, Object?>> fetchCard(int id) async {
    return _single(
      await _request(
        'GET',
        FlashcardContract.cardsTable,
        query: {'select': '*', 'id': 'eq.$id'},
      ),
    );
  }

  Future<Map<String, Object?>> createCard({
    required int deckId,
    required String front,
    required String back,
    String? imageUrl,
  }) async {
    return _single(
      await _request(
        'POST',
        FlashcardContract.cardsTable,
        body: {
          FlashcardContract.deckIdColumn: deckId,
          FlashcardContract.frontColumn: front,
          FlashcardContract.backColumn: back,
          FlashcardContract.imageUrlColumn: imageUrl,
        },
      ),
    );
  }

  Future<Map<String, Object?>> updateCard(
    int id, {
    required String front,
    required String back,
    String? imageUrl,
  }) async {
    return _single(
      await _request(
        'PATCH',
        FlashcardContract.cardsTable,
        query: {'id': 'eq.$id'},
        body: {
          FlashcardContract.frontColumn: front,
          FlashcardContract.backColumn: back,
          FlashcardContract.imageUrlColumn: imageUrl,
        },
      ),
    );
  }

  Future<void> deleteCard(int id) async {
    _single(
      await _request(
        'DELETE',
        FlashcardContract.cardsTable,
        query: {'id': 'eq.$id'},
      ),
    );
  }

  Future<Map<String, Object?>> recordReview(
    Map<String, Object?> parameters,
  ) async {
    return _single(
      await _request(
        'POST',
        FlashcardContract.reviewFunction,
        body: parameters,
        rpc: true,
      ),
    );
  }

  Future<List<Map<String, Object?>>> fetchReviewHistory(int cardId) {
    return _request(
      'GET',
      FlashcardContract.reviewsTable,
      query: {
        'select': '*',
        FlashcardContract.cardIdColumn: 'eq.$cardId',
        'order':
            '${FlashcardContract.reviewedAtColumn}.desc,${FlashcardContract.idColumn}.desc',
      },
    );
  }

  Future<List<Map<String, Object?>>> _request(
    String method,
    String resource, {
    Map<String, String> query = const {},
    Map<String, Object?>? body,
    bool rpc = false,
  }) async {
    final uri = rpc
        ? config.rpcUri(resource)
        : config.tableUri(resource, query);
    final token = await accessToken();
    if (token.isEmpty) {
      throw const AuthException('Entre na sua conta para continuar.');
    }
    final request = http.Request(method, uri)
      ..headers.addAll({
        'apikey': config.publishableKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (method != 'GET') 'Prefer': 'return=representation',
      });
    if (body != null) request.body = jsonEncode(body);
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseError = SupabaseError.fromResponse(response);
      throw FlashcardRequestException(
        response.statusCode,
        responseError: responseError,
        conflict:
            responseError.code == 'P0001' &&
            responseError.message ==
                'O cartão foi alterado. Recarregue o baralho.',
      );
    }
    if (response.bodyBytes.isEmpty) return [];
    final rows = jsonDecode(utf8.decode(response.bodyBytes));
    if (rows is! List) {
      throw const FormatException('Resposta inválida de flashcards.');
    }
    return rows.map((row) => Map<String, Object?>.from(row as Map)).toList();
  }

  Map<String, Object?> _single(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) throw const FlashcardRequestException(404);
    if (rows.length != 1) {
      throw const FormatException('Resposta inválida de flashcards.');
    }
    return rows.single;
  }
}

class FlashcardRequestException extends SupabaseRequestException {
  const FlashcardRequestException(
    int statusCode, {
    this.conflict = false,
    super.responseError,
  }) : super('', statusCode: statusCode);

  final bool conflict;

  @override
  String get message {
    if (conflict) {
      return 'O cartão foi alterado. Recarregue o baralho antes de revisar.';
    }
    if (responseError?.code == 'P0001') {
      final description = switch (responseError?.message) {
        'Entre na sua conta para continuar.' =>
          'Entre na sua conta para continuar.',
        'O cartão não está disponível para esta conta.' =>
          'O cartão não está disponível para esta conta.',
        'Avaliação de revisão inválida.' => 'A avaliação de revisão é inválida. Escolha uma das opções disponíveis.',
        _ => null,
      };
      if (description != null) return description;
    }
    if (responseError != null) {
      return responseError!.userMessage(
        'Não foi possível acessar os flashcards.',
      );
    }
    if (statusCode == 404) {
      return 'O registro não foi encontrado ou não está disponível para sua conta.';
    }
    return 'Não foi possível acessar os flashcards. Tente novamente.';
  }
}
