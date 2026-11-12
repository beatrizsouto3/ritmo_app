import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/app.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/auth_repository.dart';
import 'package:ritmo_app/data/services/auth_service.dart';
import 'package:ritmo_app/ui/auth/auth_view.dart';
import 'package:ritmo_app/ui/auth/auth_view_model.dart';
import 'package:ritmo_app/ui/subjects/subjects_view.dart';

const _config = SupabaseConfig(
  url: 'https://ritmo-test.supabase.co',
  publishableKey: 'public-test-key',
);

void main() {
  test('password login uses the auth endpoint and parses a session', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'password');
      expect(request.headers['apikey'], 'public-test-key');
      expect(jsonDecode(request.body), {
        'email': 'davi@example.com',
        'password': 'test-password',
      });
      return _response(_session());
    });
    addTearDown(client.close);
    final session = await AuthService(
      config: _config,
      client: client,
    ).signIn('davi@example.com', 'test-password');
    expect(session.userId, 'user-a');
    expect(session.accessToken, 'access-a');
    expect(session.expiresAt.isAfter(DateTime.now()), isTrue);
  });

  test(
    'signup with email confirmation never creates a local session',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/auth/v1/signup');
        return _response({'id': 'new-user', 'email': 'davi@example.com'});
      });
      addTearDown(client.close);
      final repository = AuthRepository(
        AuthService(config: _config, client: client),
      );
      final viewModel = AuthViewModel(repository);
      addTearDown(repository.dispose);
      addTearDown(viewModel.dispose);
      expect(
        await viewModel.signUp('davi@example.com', 'test-password'),
        isTrue,
      );
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.message, contains('confirmar o cadastro'));
      expect(repository.userId, isNull);
    },
  );

  test('unconfirmed email produces a useful message without exposing response data', () async {
    final client = MockClient(
      (_) async => _response({
        'error_code': 'email_not_confirmed',
        'msg': 'Internal server information',
      }, status: 400),
    );
    addTearDown(client.close);
    final repository = AuthRepository(
      AuthService(config: _config, client: client),
    );
    final viewModel = AuthViewModel(repository);
    addTearDown(repository.dispose);
    addTearDown(viewModel.dispose);
    expect(
      await viewModel.signIn('davi@example.com', 'test-password'),
      isFalse,
    );
    expect(viewModel.error, 'Confirme seu e-mail antes de entrar.');
    expect(viewModel.isBusy, isFalse);
    expect(viewModel.isAuthenticated, isFalse);
  });

  test(
    'concurrent token requests share one refresh and use the new token',
    () async {
      var refreshCalls = 0;
      final refresh = Completer<http.Response>();
      final client = MockClient((request) async {
        if (request.url.queryParameters['grant_type'] == 'password') {
          return _response(_session(expiresIn: -60));
        }
        refreshCalls++;
        expect(jsonDecode(request.body), {'refresh_token': 'refresh-a'});
        return refresh.future;
      });
      addTearDown(client.close);
      final repository = AuthRepository(
        AuthService(config: _config, client: client),
      );
      addTearDown(repository.dispose);
      await repository.signIn('davi@example.com', 'test-password');
      final first = repository.getAccessToken();
      final second = repository.getAccessToken();
      await Future<void>.delayed(Duration.zero);
      expect(refreshCalls, 1);
      refresh.complete(_response(_session(token: 'renewed-token')));
      expect(await first, 'renewed-token');
      expect(await second, 'renewed-token');
      expect(await repository.getAccessToken(), 'renewed-token');
      expect(refreshCalls, 1);
    },
  );

  test('revoked refresh token clears the session', () async {
    final client = MockClient((request) async {
      if (request.url.queryParameters['grant_type'] == 'password') {
        return _response(_session(expiresIn: -60));
      }
      return _response({'error_code': 'refresh_token_not_found'}, status: 400);
    });
    addTearDown(client.close);
    final repository = AuthRepository(
      AuthService(config: _config, client: client),
    );
    addTearDown(repository.dispose);
    await repository.signIn('davi@example.com', 'test-password');
    await expectLater(
      repository.getAccessToken(),
      throwsA(isA<AuthException>()),
    );
    expect(repository.userId, isNull);
  });

  test('late refresh never restores a session after logout', () async {
    final refresh = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/logout')) return http.Response('', 204);
      if (request.url.queryParameters['grant_type'] == 'password') {
        return _response(_session(expiresIn: -60));
      }
      return refresh.future;
    });
    addTearDown(client.close);
    final repository = AuthRepository(
      AuthService(config: _config, client: client),
    );
    addTearDown(repository.dispose);
    await repository.signIn('davi@example.com', 'test-password');
    final pending = repository.getAccessToken();
    final expectation = expectLater(pending, throwsA(isA<AuthException>()));
    await repository.signOut();
    refresh.complete(_response(_session(token: 'late-token')));
    await expectation;
    expect(repository.userId, isNull);
  });

  test('logout clears the local session even when the network fails', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/logout')) {
        expect(request.url.queryParameters['scope'], 'local');
        expect(request.headers['authorization'], 'Bearer access-a');
        throw http.ClientException('Falha de conexão simulada.');
      }
      return _response(_session());
    });
    addTearDown(client.close);
    final repository = AuthRepository(
      AuthService(config: _config, client: client),
    );
    final viewModel = AuthViewModel(repository);
    addTearDown(repository.dispose);
    addTearDown(viewModel.dispose);
    await viewModel.signIn('davi@example.com', 'test-password');
    expect(await viewModel.signOut(), isFalse);
    expect(viewModel.isAuthenticated, isFalse);
    expect(viewModel.error, contains('Você saiu deste aparelho'));
    await expectLater(
      repository.getAccessToken(),
      throwsA(isA<AuthException>()),
    );
  });

  testWidgets(
    'registration validates fields and explains email confirmation on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return _response({'id': 'new-user'});
      });
      addTearDown(client.close);
      final repository = AuthRepository(
        AuthService(config: _config, client: client),
      );
      final viewModel = AuthViewModel(repository);
      addTearDown(repository.dispose);
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const MaterialApp(home: AuthView()),
        ),
      );
      await tester.tap(find.text('Criar uma conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();
      expect(find.text('Informe um e-mail válido.'), findsOneWidget);
      expect(calls, 0);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'davi@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Confira seu e-mail'), findsOneWidget);
      expect(viewModel.isAuthenticated, isFalse);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'logout from a nested route removes old subjects before another user logs in',
    (tester) async {
      var loginCount = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/logout')) return http.Response('', 204);
        if (request.url.path.endsWith('/token')) {
          loginCount++;
          return _response(
            _session(
              userId: loginCount == 1 ? 'user-a' : 'user-b',
              token: loginCount == 1 ? 'access-a' : 'access-b',
            ),
          );
        }
        final token = request.headers['authorization'];
        expect(token, anyOf('Bearer access-a', 'Bearer access-b'));
        return _response([
          {
            'id': 1,
            'nome': token == 'Bearer access-a'
                ? 'Disciplina A'
                : 'Disciplina B',
          },
        ]);
      });
      addTearDown(client.close);
      final repository = AuthRepository(
        AuthService(config: _config, client: client),
      );
      final viewModel = AuthViewModel(repository);
      addTearDown(repository.dispose);
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: _config),
            Provider<http.Client>.value(value: client),
            ChangeNotifierProvider.value(value: repository),
            ChangeNotifierProvider.value(value: viewModel),
          ],
          child: const RitmoApp(),
        ),
      );
      expect(find.byType(AuthView), findsOneWidget);
      await viewModel.signIn('a@example.com', 'test-password');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disciplinas'));
      await tester.pumpAndSettle();
      expect(find.text('Disciplina A'), findsOneWidget);
      await viewModel.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(AuthView), findsOneWidget);
      expect(find.byType(SubjectsView), findsNothing);
      expect(find.text('Disciplina A'), findsNothing);
      await viewModel.signIn('b@example.com', 'test-password');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disciplinas'));
      await tester.pumpAndSettle();
      expect(find.text('Disciplina B'), findsOneWidget);
      expect(find.text('Disciplina A'), findsNothing);
    },
  );
}

Map<String, Object?> _session({
  String userId = 'user-a',
  String token = 'access-a',
  int expiresIn = 3600,
}) => {
  'access_token': token,
  'refresh_token': 'refresh-a',
  'expires_in': expiresIn,
  'user': {'id': userId},
};

http.Response _response(Object data, {int status = 200}) {
  return http.Response.bytes(utf8.encode(jsonEncode(data)), status);
}
