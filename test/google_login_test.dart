import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/auth_repository.dart';
import 'package:ritmo_app/data/services/auth_service.dart';
import 'package:ritmo_app/data/services/oauth_browser_service.dart';
import 'package:ritmo_app/ui/auth/auth_view.dart';
import 'package:ritmo_app/ui/auth/auth_view_model.dart';

const _config = SupabaseConfig(
  url: 'https://ritmo-test.supabase.co',
  publishableKey: 'public-test-key',
);

void main() {
  test('google login sends a PKCE challenge and exchanges the code', () async {
    final browser = _FakeBrowser()
      ..callback = Uri.parse('br.ufrn.ritmo://login-callback?code=auth-123');
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'pkce');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['auth_code'], 'auth-123');
      final challenge = base64UrlEncode(
        sha256.convert(utf8.encode(body['code_verifier'] as String)).bytes,
      ).replaceAll('=', '');
      expect(
        browser.authorizeUri!.queryParameters['code_challenge'],
        challenge,
      );
      return _response(_session());
    });
    addTearDown(client.close);

    final session = await AuthService(
      config: _config,
      client: client,
      browser: browser,
    ).signInWithGoogle();

    final params = browser.authorizeUri!.queryParameters;
    expect(browser.authorizeUri!.path, '/auth/v1/authorize');
    expect(params['provider'], 'google');
    expect(params['redirect_to'], 'br.ufrn.ritmo://login-callback');
    expect(params['code_challenge_method'], 's256');
    expect(session.userId, 'user-g');
    expect(session.fullName, 'Davi Google');
  });

  test('a refused authorization never requests a session', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return _response(_session());
    });
    addTearDown(client.close);
    final service = AuthService(
      config: _config,
      client: client,
      browser: _FakeBrowser()
        ..callback = Uri.parse(
          'br.ufrn.ritmo://login-callback?error=access_denied',
        ),
    );

    await expectLater(
      service.signInWithGoogle(),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'O acesso com Google foi recusado.',
        ),
      ),
    );
    expect(calls, 0);
  });

  test('a callback from another address is rejected', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return _response(_session());
    });
    addTearDown(client.close);
    final service = AuthService(
      config: _config,
      client: client,
      browser: _FakeBrowser()
        ..callback = Uri.parse('evil.app://login-callback?code=auth-123'),
    );

    await expectLater(service.signInWithGoogle(), throwsFormatException);
    expect(calls, 0);
  });

  test('canceling shows feedback and keeps the user signed out', () async {
    final browser = _FakeBrowser()..waitForCallback = true;
    final client = MockClient((_) async => _response(_session()));
    addTearDown(client.close);
    final repository = AuthRepository(
      AuthService(config: _config, client: client, browser: browser),
    );
    final viewModel = AuthViewModel(repository);
    addTearDown(repository.dispose);
    addTearDown(viewModel.dispose);

    final pending = viewModel.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.isGooglePending, isTrue);
    expect(await viewModel.signInWithGoogle(), isFalse);

    await viewModel.cancelGoogleSignIn();
    await pending;
    expect(viewModel.isGooglePending, isFalse);
    expect(viewModel.isBusy, isFalse);
    expect(viewModel.message, 'Login com Google cancelado.');
    expect(viewModel.isAuthenticated, isFalse);
  });

  test('a late callback after cancel does not create a session', () async {
    final browser = _FakeBrowser()
      ..waitForCallback = true
      ..ignoreCancel = true;
    final client = MockClient((_) async => _response(_session()));
    addTearDown(client.close);
    final repository = AuthRepository(
      AuthService(config: _config, client: client, browser: browser),
    );
    addTearDown(repository.dispose);

    final pending = repository.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    await repository.cancelGoogleSignIn();
    browser.complete(
      Uri.parse('br.ufrn.ritmo://login-callback?code=auth-late'),
    );

    await expectLater(pending, throwsA(isA<OAuthCanceledException>()));
    expect(repository.userId, isNull);
  });

  test('platform bridge passes the URL and parses the returned link', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('com.example.ritmo_app/oauth');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? openedUrl;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'authenticate');
      openedUrl = call.arguments as String;
      return 'br.ufrn.ritmo://login-callback?code=auth-123';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final callback = await const PlatformOAuthBrowserService().authenticate(
      Uri.parse('https://ritmo-test.supabase.co/auth/v1/authorize'),
    );
    expect(openedUrl, 'https://ritmo-test.supabase.co/auth/v1/authorize');
    expect(callback.queryParameters['code'], 'auth-123');
  });

  testWidgets('google button signs in without filling the form', (
    tester,
  ) async {
    final client = MockClient((_) async => _response(_session()));
    addTearDown(client.close);
    final repository = AuthRepository(
      AuthService(
        config: _config,
        client: client,
        browser: _FakeBrowser()
          ..callback = Uri.parse(
            'br.ufrn.ritmo://login-callback?code=auth-123',
          ),
      ),
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

    final button = find.text('Continuar com Google');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido.'), findsNothing);
    expect(viewModel.isAuthenticated, isTrue);
    expect(repository.userId, 'user-g');
  });
}

Map<String, Object?> _session() => {
  'access_token': 'access-g',
  'refresh_token': 'refresh-g',
  'expires_in': 3600,
  'user': {
    'id': 'user-g',
    'user_metadata': {'full_name': 'Davi Google'},
  },
};

http.Response _response(Object data, {int status = 200}) {
  return http.Response.bytes(utf8.encode(jsonEncode(data)), status);
}

class _FakeBrowser implements OAuthBrowserService {
  Uri? authorizeUri;
  Uri? callback;
  bool waitForCallback = false;
  bool ignoreCancel = false;
  Completer<Uri>? _pending;

  @override
  Future<Uri> authenticate(Uri authorizeUri) {
    this.authorizeUri = authorizeUri;
    if (!waitForCallback) return Future.value(callback);
    return (_pending = Completer<Uri>()).future;
  }

  @override
  Future<void> cancel() async {
    if (ignoreCancel) return;
    _pending?.completeError(PlatformException(code: 'OAUTH_CANCELED'));
    _pending = null;
  }

  void complete(Uri uri) => _pending?.complete(uri);
}
