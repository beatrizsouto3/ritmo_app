import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/core/errors/request_error.dart';
import 'package:ritmo_app/data/repositories/auth_repository.dart';
import 'package:ritmo_app/data/repositories/flashcard_repository.dart';
import 'package:ritmo_app/data/repositories/subject_repository.dart';
import 'package:ritmo_app/data/services/auth_service.dart';
import 'package:ritmo_app/data/services/flashcard_service.dart';
import 'package:ritmo_app/data/services/subject_service.dart';
import 'package:ritmo_app/ui/auth/auth_view_model.dart';
import 'package:ritmo_app/ui/flashcards/flashcards_view_model.dart';
import 'package:ritmo_app/ui/subjects/subjects_view_model.dart';

const _config = SupabaseConfig(
  url: 'https://ritmo-test.supabase.co',
  publishableKey: 'public-test-key',
);

void main() {
  for (final codeField in ['code', 'error_code']) {
    test('auth supports $codeField and retains server diagnostics', () async {
      final client = MockClient(
        (_) async => _response({
          codeField: 'email_not_confirmed',
          'msg': 'Original auth message',
          'details': 'Server diagnostic',
          'hint': 'Server hint',
        }, 400),
      );
      addTearDown(client.close);
      final service = AuthService(config: _config, client: client);
      await expectLater(
        service.signIn('user@example.com', 'password'),
        throwsA(
          isA<AuthException>()
              .having(
                (error) => error.message,
                'message',
                'Confirme seu e-mail antes de entrar.',
              )
              .having((error) => error.statusCode, 'statusCode', 400)
              .having(
                (error) => error.responseError?.code,
                'code',
                'email_not_confirmed',
              )
              .having(
                (error) => error.responseError?.message,
                'serverMessage',
                'Original auth message',
              )
              .having(
                (error) => error.responseError?.details,
                'details',
                'Server diagnostic',
              )
              .having(
                (error) => error.responseError?.hint,
                'hint',
                'Server hint',
              ),
        ),
      );
    });
  }

  final authFailures = <String, (Object, String)>{
    'timeout': (TimeoutException('Timed out'), 'tempo de espera'),
    'connection': (http.ClientException('Failed host lookup'), 'conexão'),
    'DNS': (const SocketException('Failed host lookup'), 'alcançar o servidor'),
    'TLS': (const HandshakeException('Certificate error'), 'conexão segura'),
    'HTTP transport': (
      const HttpException('Incomplete headers'),
      'comunicação HTTP',
    ),
    'invalid JSON': (const FormatException('Invalid JSON'), 'formato esperado'),
    'unexpected exception': (
      StateError('Internal application failure'),
      'erro inesperado',
    ),
  };
  for (final entry in authFailures.entries) {
    test('auth distinguishes ${entry.key} and clears its busy state', () async {
      final client = MockClient((_) async => throw entry.value.$1);
      final viewModel = _authViewModel(client);
      expect(await viewModel.signIn('user@example.com', 'password'), isFalse);
      expect(viewModel.error, contains(entry.value.$2));
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.isAuthenticated, isFalse);
    });
  }

  test(
    'missing configuration is not reported as an internet failure',
    () async {
      final client = MockClient((_) async {
        fail('Não deve enviar uma requisição sem configuração.');
      });
      final viewModel = _authViewModel(
        client,
        config: const SupabaseConfig(url: '', publishableKey: ''),
      );
      expect(await viewModel.signIn('user@example.com', 'password'), isFalse);
      expect(viewModel.error, 'Configure a URL e a chave pública do Supabase.');
    },
  );

  test(
    'a malformed success response is not reported as an internet failure',
    () async {
      final viewModel = _authViewModel(
        MockClient((_) async => _response([], 200)),
      );
      expect(await viewModel.signIn('user@example.com', 'password'), isFalse);
      expect(viewModel.error, contains('formato esperado'));
    },
  );

  test('an unknown auth error retains its code without displaying the raw response', () async {
    final viewModel = _authViewModel(
      MockClient(
        (_) async => _response({
          'code': 'new_server_error',
          'message': 'Sensitive server information',
        }, 500),
      ),
    );
    expect(await viewModel.signIn('user@example.com', 'password'), isFalse);
    expect(viewModel.error, contains('falha no servidor'));
    expect(viewModel.error, contains('HTTP 500'));
    expect(viewModel.error, contains('new_server_error'));
    expect(viewModel.error, isNot(contains('Sensitive')));
  });

  test('non-JSON server failures retain the HTTP status', () async {
    final viewModel = _authViewModel(
      MockClient((_) async => http.Response('<html>Bad gateway</html>', 502)),
    );
    expect(await viewModel.signIn('user@example.com', 'password'), isFalse);
    expect(viewModel.error, contains('falha no servidor'));
    expect(viewModel.error, contains('HTTP 502'));
    expect(viewModel.error, isNot(contains('<html>')));
  });

  final databaseFailures = <String, (int, String)>{
    '42501': (403, 'permissão'),
    '42P01': (404, 'tabela'),
    'PGRST202': (404, 'função'),
    'PGRST204': (400, 'coluna'),
    '23505': (409, 'Já existe'),
    '23503': (409, 'registro relacionado'),
    'PGRST301': (401, 'sessão'),
    'PGRST003': (504, 'banco de dados'),
  };
  for (final entry in databaseFailures.entries) {
    test(
      'database error ${entry.key} reaches subjects and flashcards screens',
      () async {
        final client = MockClient(
          (_) async => _response({
            'code': entry.key,
            'message': 'Original database error',
            'details': 'Private row contents',
          }, entry.value.$1),
        );
        addTearDown(client.close);
        final subjects = SubjectsViewModel(
          SubjectRepository(SubjectService(config: _config, client: client)),
        );
        final flashcards = FlashcardsViewModel(
          FlashcardRepository(
            FlashcardService(
              config: _config,
              client: client,
              accessToken: () async => 'access-token',
            ),
          ),
        );
        addTearDown(subjects.dispose);
        addTearDown(flashcards.dispose);
        await subjects.loadSubjects();
        await flashcards.loadDecks();
        for (final message in [subjects.loadError, flashcards.errorMessage]) {
          expect(message, contains(entry.value.$2));
          expect(message, contains(entry.key));
          expect(message, contains('HTTP ${entry.value.$1}'));
          expect(message, isNot(contains('Private row contents')));
        }
        expect(subjects.isLoading, isFalse);
        expect(flashcards.isLoading, isFalse);
      },
    );
  }

  test('subject save preserves the failure and supports retry', () async {
    var failSave = true;
    final client = MockClient((request) async {
      if (request.method == 'GET') return _response([], 200);
      if (failSave) return _response({'code': '42501'}, 403);
      return _response([
        {'id': 1},
      ], 201);
    });
    addTearDown(client.close);
    final viewModel = SubjectsViewModel(
      SubjectRepository(SubjectService(config: _config, client: client)),
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadSubjects();
    expect(await viewModel.createSubject('Física'), isFalse);
    expect(viewModel.saveError, contains('42501'));
    expect(viewModel.subjects, isEmpty);
    expect(viewModel.isSaving, isFalse);
    failSave = false;
    expect(await viewModel.createSubject('Física'), isTrue);
    expect(viewModel.saveError, isNull);
    expect(viewModel.subjects.single.name, 'Física');
  });

  test('session renewal errors are preserved in flashcards', () async {
    final client = MockClient((_) async => _response([], 200));
    addTearDown(client.close);
    final viewModel = FlashcardsViewModel(
      FlashcardRepository(
        FlashcardService(
          config: _config,
          client: client,
          accessToken: () async =>
              throw const AuthException('Sua sessão expirou. Entre novamente.'),
        ),
      ),
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadDecks();
    expect(viewModel.errorMessage, 'Sua sessão expirou. Entre novamente.');
  });

  test(
    'a business rule rejection is not confused with a concurrent review',
    () async {
      final client = MockClient(
        (_) async => _response({
          'code': 'P0001',
          'message': 'O cartão não está disponível para esta conta.',
        }, 400),
      );
      addTearDown(client.close);
      final service = FlashcardService(
        config: _config,
        client: client,
        accessToken: () async => 'token',
      );
      await expectLater(
        service.recordReview({}),
        throwsA(
          isA<FlashcardRequestException>()
              .having((error) => error.conflict, 'conflict', isFalse)
              .having(
                (error) => error.message,
                'message',
                'O cartão não está disponível para esta conta.',
              ),
        ),
      );
    },
  );

  test('malformed error fields do not mask the original HTTP failure', () {
    final error = SupabaseError.fromResponse(
      _response({
        'code': 400,
        'message': {'unexpected': true},
        'details': [],
      }, 400),
    );
    expect(error.statusCode, 400);
    expect(error.code, isNull);
    expect(error.userMessage('Falha.'), contains('HTTP 400'));
  });
}

AuthViewModel _authViewModel(
  http.Client client, {
  SupabaseConfig config = _config,
}) {
  addTearDown(client.close);
  final repository = AuthRepository(
    AuthService(config: config, client: client),
  );
  final viewModel = AuthViewModel(repository);
  addTearDown(repository.dispose);
  addTearDown(viewModel.dispose);
  return viewModel;
}

http.Response _response(Object body, int status) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);
