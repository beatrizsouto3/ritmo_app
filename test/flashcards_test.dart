import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/flashcard_repository.dart';
import 'package:ritmo_app/data/services/flashcard_service.dart';
import 'package:ritmo_app/domain/models/flashcard.dart';
import 'package:ritmo_app/domain/models/flashcard_rating.dart';
import 'package:ritmo_app/domain/models/review_schedule.dart';
import 'package:ritmo_app/ui/flashcards/flashcard_form_view.dart';
import 'package:ritmo_app/ui/flashcards/flashcard_review_view.dart';
import 'package:ritmo_app/ui/flashcards/flashcards_view.dart';
import 'package:ritmo_app/ui/flashcards/flashcards_view_model.dart';

const _config = SupabaseConfig(
  url: 'https://ritmo-test.supabase.co',
  publishableKey: 'public-test-key',
);

void main() {
  test(
    'decks are loaded from the server with the current authentication token',
    () async {
      var token = 'token-a';
      final client = MockClient((request) async {
        expect(request.url.path, '/rest/v1/baralhos');
        expect(request.method, 'GET');
        expect(request.headers['apikey'], _config.publishableKey);
        expect(request.headers['authorization'], 'Bearer $token');
        return _response([_deckRow(name: token)]);
      });
      addTearDown(client.close);
      final repository = FlashcardRepository(
        FlashcardService(
          config: _config,
          client: client,
          accessToken: () async => token,
        ),
      );
      expect((await repository.getDecks()).single.name, 'token-a');
      token = 'token-b';
      expect((await repository.getDecks()).single.name, 'token-b');
    },
  );

  test('deck creation normalizes text and uses ID and timestamps returned by the server', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body), {'nome': 'Biologia', 'descricao': null});
      expect(request.headers['prefer'], 'return=representation');
      return _response([_deckRow(id: 987, name: 'Biologia')], status: 201);
    });
    addTearDown(client.close);
    final deck = await _repository(client)
        .createDeck(name: '  Biologia  ', description: '  ');
    expect(deck.id, 987);
    expect(deck.createdAt, DateTime.utc(2026, 1, 1));
  });

  test(
    'repository rejects invalid deck and card data before sending HTTP',
    () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return _response([]);
      });
      addTearDown(client.close);
      final repository = _repository(client);
      await expectLater(repository.createDeck(name: ' '), throwsArgumentError);
      await expectLater(
        repository.createDeck(name: 'a' * 61),
        throwsArgumentError,
      );
      await expectLater(
        repository.createCard(deckId: 101, front: '', back: 'Resposta'),
        throwsArgumentError,
      );
      await expectLater(
        repository.createCard(
          deckId: 101,
          front: 'Pergunta',
          back: 'Resposta',
          imageUrl: 'file:///tmp/image.png',
        ),
        throwsArgumentError,
      );
      expect(calls, 0);
    },
  );

  test(
    'card creation leaves ownership, IDs and schedule defaults to the server',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/rest/v1/flashcards');
        expect(jsonDecode(request.body), {
          'baralho_id': 101,
          'frente': 'Pergunta',
          'verso': 'Resposta',
          'imagem_url': 'https://example.com/image.png',
        });
        return _response([_cardRow()], status: 201);
      });
      addTearDown(client.close);
      final card = await _repository(client).createCard(
        deckId: 101,
        front: ' Pergunta ',
        back: ' Resposta ',
        imageUrl: ' https://example.com/image.png ',
      );
      expect(card.id, 201);
      expect(card.nextReviewAt, DateTime.utc(2026, 1, 1));
    },
  );

  test('editing card content never resets its review schedule', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.queryParameters['id'], 'eq.201');
      expect(jsonDecode(request.body), {
        'frente': 'Nova pergunta',
        'verso': 'Resposta',
        'imagem_url': null,
      });
      return _response([
        _cardRow(front: 'Nova pergunta', intervalDays: 7, repetitions: 2),
      ]);
    });
    addTearDown(client.close);
    final original = _card().copyWith(
      front: 'Nova pergunta',
      intervalDays: 7,
      repetitions: 2,
    );
    final edited = await _repository(client).updateCard(original);
    expect(edited.intervalDays, 7);
    expect(edited.repetitions, 2);
  });

  test('due card requests use an explicit UTC cutoff', () async {
    final cutoff = DateTime.utc(2026, 11, 12, 14);
    final client = MockClient((request) async {
      expect(request.url.queryParameters['baralho_id'], 'eq.101');
      expect(
        request.url.queryParameters['proxima_revisao_em'],
        'lte.${cutoff.toIso8601String()}',
      );
      return _response([_cardRow()]);
    });
    addTearDown(client.close);
    expect(
      await _repository(client).getDueCards(101, at: cutoff),
      hasLength(1),
    );
  });

  test('unavailable records and denied requests are never treated as successful changes', () async {
    final empty = MockClient((_) async => _response([]));
    final denied = MockClient(
      (_) async => _response({'message': 'denied'}, status: 403),
    );
    addTearDown(empty.close);
    addTearDown(denied.close);
    await expectLater(
      _repository(empty).deleteDeck(101),
      throwsA(isA<FlashcardRequestException>()),
    );
    await expectLater(
      _repository(empty).updateCard(_card()),
      throwsA(isA<FlashcardRequestException>()),
    );
    await expectLater(
      _repository(denied).getDecks(),
      throwsA(isA<FlashcardRequestException>()),
    );
  });

  test('SRS retains initial intervals, growth, reset and upper bound', () {
    const calculator = ReviewScheduleCalculator();
    final now = DateTime.utc(2026, 11, 12);
    for (final entry in {
      FlashcardRating.hard: 1,
      FlashcardRating.good: 3,
      FlashcardRating.easy: 7,
    }.entries) {
      final schedule = calculator.calculate(
        card: _card(),
        rating: entry.key,
        reviewedAt: now,
      );
      expect(schedule.intervalDays, entry.value);
      expect(schedule.nextReviewAt, now.add(Duration(days: entry.value)));
      expect(schedule.repetitions, 1);
    }
    final reset = calculator.calculate(
      card: _card().copyWith(intervalDays: 8, repetitions: 3),
      rating: FlashcardRating.again,
      reviewedAt: now,
    );
    expect(reset.nextReviewAt, now.add(const Duration(minutes: 10)));
    expect(reset.repetitions, 0);
    expect(
      calculator
          .calculate(
            card: _card().copyWith(intervalDays: 3),
            rating: FlashcardRating.good,
            reviewedAt: now,
          )
          .intervalDays,
      6,
    );
    expect(
      calculator
          .calculate(
            card: _card().copyWith(intervalDays: 3650),
            rating: FlashcardRating.easy,
            reviewedAt: now,
          )
          .intervalDays,
      3650,
    );
  });

  test('review sends schedule and history to one atomic RPC with the expected previous state', () async {
    final requests = <String>[];
    final time = DateTime.utc(2026, 11, 12, 14);
    final client = MockClient((request) async {
      requests.add(request.method);
      if (request.method == 'GET') return _response([_cardRow()]);
      expect(request.url.path, '/rest/v1/rpc/record_flashcard_review');
      final body = jsonDecode(request.body) as Map;
      expect(body['p_card_id'], 201);
      expect(body['p_rating'], 'good');
      expect(body['p_expected_repetitions'], 0);
      expect(
        body['p_expected_next_review_at'],
        DateTime.utc(2026, 1, 1).toIso8601String(),
      );
      expect(body['p_interval_days'], 3);
      expect(body['p_repetitions'], 1);
      expect(
        body['p_next_review_at'],
        time.add(const Duration(days: 3)).toIso8601String(),
      );
      return _response([_reviewRow(time)]);
    });
    addTearDown(client.close);
    final review = await _repository(
      client,
    ).reviewCard(cardId: 201, rating: FlashcardRating.good, reviewedAt: time);
    expect(review.intervalDays, 3);
    expect(review.repetitions, 1);
    expect(requests, ['GET', 'POST']);
  });

  test('a card already reviewed elsewhere is rejected before writing a second review', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return _response([_cardRow(nextReviewAt: DateTime.utc(2030))]);
    });
    addTearDown(client.close);
    await expectLater(
      _repository(client).reviewCard(
        cardId: 201,
        rating: FlashcardRating.good,
        reviewedAt: DateTime.utc(2026, 11, 12),
      ),
      throwsArgumentError,
    );
    expect(calls, 1);
  });

  test(
    'failed review keeps the active card and previous cached schedule',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/rpc/')) {
          return _response({
            'code': 'P0001',
            'message': 'O cartão foi alterado. Recarregue o baralho.',
          }, status: 400);
        }
        if (request.url.path.endsWith('/baralhos')) {
          return _response([_deckRow()]);
        }
        return _response([_cardRow()]);
      });
      addTearDown(client.close);
      final viewModel = FlashcardsViewModel(_repository(client));
      addTearDown(viewModel.dispose);
      await viewModel.loadDecks();
      await viewModel.startReview(101);
      viewModel.revealAnswer();
      expect(await viewModel.rateCurrentCard(FlashcardRating.good), isFalse);
      expect(viewModel.reviewRemaining, 1);
      expect(viewModel.reviewCompleted, 0);
      expect(viewModel.cardsForDeck(101).single.intervalDays, 0);
      expect(viewModel.errorMessage, contains('Recarregue'));
      expect(viewModel.isSaving, isFalse);
    },
  );

  test('concurrent creates are blocked and late completions after disposal do not repopulate state', () async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return pending.future;
    });
    addTearDown(client.close);
    final viewModel = FlashcardsViewModel(_repository(client));
    final first = viewModel.createDeck(name: 'Biologia');
    expect(await viewModel.createDeck(name: 'Biologia'), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    viewModel.dispose();
    pending.complete(_response([_deckRow()], status: 201));
    expect(await first, isFalse);
    expect(viewModel.decks, isEmpty);
  });

  testWidgets(
    'Provider connects empty list, deck form and the saved server record',
    (tester) async {
      var created = false;
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          created = true;
          return _response([_deckRow(name: 'Biologia')], status: 201);
        }
        return _response(created ? [_deckRow(name: 'Biologia')] : []);
      });
      addTearDown(client.close);
      final viewModel = FlashcardsViewModel(_repository(client));
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const MaterialApp(home: FlashcardsView()),
        ),
      );
      expect(find.text('Seus estudos começam por um baralho'), findsOneWidget);
      await tester.tap(find.text('Novo baralho'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe o nome do baralho.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Biologia');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Biologia'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(created, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('card form retains entered content when the remote save fails', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => _response({'message': 'failure'}, status: 500),
    );
    addTearDown(client.close);
    final viewModel = FlashcardsViewModel(_repository(client));
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: FlashcardFormView(deckId: 101)),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Pergunta');
    await tester.enterText(find.byType(TextFormField).at(1), 'Resposta');
    await tester.ensureVisible(find.text('Criar cartão'));
    await tester.tap(find.text('Criar cartão'));
    await tester.pumpAndSettle();
    expect(find.text('Pergunta'), findsOneWidget);
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.isSaving, isFalse);
  });

  testWidgets(
    'review shows intervals and updates progress only after successful persistence',
    (tester) async {
      final now = DateTime.now().toUtc();
      final client = MockClient((request) async {
        if (request.url.path.contains('/rpc/')) {
          return _response([_reviewRow(now)]);
        }
        if (request.url.path.endsWith('/baralhos')) {
          return _response([_deckRow()]);
        }
        return _response([_cardRow()]);
      });
      addTearDown(client.close);
      final viewModel = FlashcardsViewModel(_repository(client));
      addTearDown(viewModel.dispose);
      await viewModel.loadDecks();
      await viewModel.startReview(101);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const MaterialApp(home: FlashcardReviewView()),
        ),
      );
      expect(find.text('Pergunta'), findsOneWidget);
      await tester.tap(find.text('Revelar resposta'));
      await tester.pumpAndSettle();
      expect(find.text('Resposta'), findsOneWidget);
      expect(find.text('1 dia'), findsOneWidget);
      expect(find.text('3 dias'), findsOneWidget);
      expect(find.text('7 dias'), findsOneWidget);
      await tester.tap(find.text('Bom'));
      await tester.pumpAndSettle();
      expect(find.text('Revisão concluída!'), findsOneWidget);
      expect(viewModel.reviewCompleted, 1);
      expect(viewModel.cardsForDeck(101).single.intervalDays, 3);
      expect(viewModel.cardsForDeck(101).single.repetitions, 1);
    },
  );
}

FlashcardRepository _repository(http.Client client) => FlashcardRepository(
  FlashcardService(
    config: _config,
    client: client,
    accessToken: () async => 'user-token',
  ),
);

Map<String, Object?> _deckRow({int id = 101, String name = 'Biologia'}) => {
  'id': id,
  'nome': name,
  'descricao': null,
  'criado_em': '2026-01-01T00:00:00Z',
};

Map<String, Object?> _cardRow({
  String front = 'Pergunta',
  int intervalDays = 0,
  int repetitions = 0,
  DateTime? nextReviewAt,
}) => {
  'id': 201,
  'baralho_id': 101,
  'frente': front,
  'verso': 'Resposta',
  'imagem_url': null,
  'criado_em': '2026-01-01T00:00:00Z',
  'proxima_revisao_em': (nextReviewAt ?? DateTime.utc(2026, 1, 1))
      .toIso8601String(),
  'intervalo_dias': intervalDays,
  'repeticoes': repetitions,
};

Flashcard _card() => Flashcard(
  id: 201,
  deckId: 101,
  front: 'Pergunta',
  back: 'Resposta',
  createdAt: DateTime.utc(2026, 1, 1),
  nextReviewAt: DateTime.utc(2026, 1, 1),
);

Map<String, Object?> _reviewRow(DateTime now) => {
  'id': 301,
  'flashcard_id': 201,
  'avaliacao': 'good',
  'revisado_em': now.toIso8601String(),
  'proxima_revisao_em': now.add(const Duration(days: 3)).toIso8601String(),
  'intervalo_dias': 3,
  'repeticoes': 1,
};

http.Response _response(Object body, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);
