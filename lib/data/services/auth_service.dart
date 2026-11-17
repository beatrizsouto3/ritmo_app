import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/errors/request_error.dart';
import '../../domain/models/auth_session.dart';
import '../mappers/auth_session_codec.dart';
import 'oauth_browser_service.dart';

class AuthService {
  AuthService({
    required this.config,
    required this.client,
    this.browser = const PlatformOAuthBrowserService(),
  });

  static final oauthRedirectUri = Uri.parse('br.ufrn.ritmo://login-callback');

  final SupabaseConfig config;
  final http.Client client;
  final OAuthBrowserService browser;

  Future<AuthSession> signIn(String email, String password) async {
    final data = await _post(
      'token',
      {'email': email, 'password': password},
      queryParameters: {'grant_type': 'password'},
    );
    return AuthSessionCodec.fromResponse(data);
  }

  Future<AuthSession?> signUp(
    String email,
    String password, {
    String? fullName,
    String? goal,
  }) async {
    final data = await _post('signup', {
      'email': email,
      'password': password,
      if (fullName != null && goal != null)
        'data': {'full_name': fullName, 'study_goal': goal},
    });
    if (data['access_token'] == null) {
      if (data['id'] is! String && data['user'] is! Map) {
        throw const FormatException('Resposta de cadastro inválida.');
      }
      return null;
    }
    return AuthSessionCodec.fromResponse(data);
  }

  Future<AuthSession> signInWithGoogle() async {
    final verifier = _createCodeVerifier();
    final authorizeUri = config.authUri('authorize', {
      'provider': 'google',
      'redirect_to': oauthRedirectUri.toString(),
      'code_challenge': _codeChallenge(verifier),
      'code_challenge_method': 's256',
    });
    final Uri callback;
    try {
      callback = await browser.authenticate(authorizeUri);
    } on PlatformException catch (error) {
      throw switch (error.code) {
        'OAUTH_CANCELED' => const OAuthCanceledException(),
        'OAUTH_IN_PROGRESS' => const AuthException(
          'Já existe um login com Google em andamento.',
        ),
        'BROWSER_NOT_FOUND' => const AuthException(
          'Nenhum navegador disponível para entrar com Google.',
        ),
        _ => const AuthException('Não foi possível abrir o login com Google.'),
      };
    } on MissingPluginException {
      throw const AuthException(
        'O login com Google está disponível somente no Android.',
      );
    } on TimeoutException {
      throw const AuthException(
        'O tempo para concluir o login com Google esgotou. Tente novamente.',
      );
    }
    final data = await _post(
      'token',
      {'auth_code': _readAuthCode(callback), 'code_verifier': verifier},
      queryParameters: {'grant_type': 'pkce'},
    );
    return AuthSessionCodec.fromResponse(data);
  }

  Future<void> cancelGoogleSignIn() => browser.cancel();

  Future<AuthSession> refreshSession(String refreshToken) async {
    final data = await _post(
      'token',
      {'refresh_token': refreshToken},
      queryParameters: {'grant_type': 'refresh_token'},
    );
    return AuthSessionCodec.fromResponse(data);
  }

  Future<void> signOut(String accessToken) async {
    await _post(
      'logout',
      const {},
      queryParameters: {'scope': 'local'},
      accessToken: accessToken,
    );
  }

  String _readAuthCode(Uri callback) {
    if (callback.scheme != oauthRedirectUri.scheme ||
        callback.host != oauthRedirectUri.host) {
      throw const FormatException('Retorno do login com Google inválido.');
    }
    // Erros podem vir na query ou no fragmento, conforme a etapa que falhou.
    final params = {
      ...Uri.splitQueryString(callback.fragment),
      ...callback.queryParameters,
    };
    final error = params['error'];
    if (error != null) {
      throw AuthException(
        error == 'access_denied'
            ? 'O acesso com Google foi recusado.'
            : 'Não foi possível entrar com Google. Tente novamente.',
      );
    }
    final code = params['code'];
    if (code == null || code.isEmpty) {
      throw const FormatException('Retorno do login com Google sem código.');
    }
    return code;
  }

  // Segredo PKCE: só o app que iniciou o login consegue trocar o código.
  String _createCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _codeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<Map<String, Object?>> _post(
    String action,
    Map<String, Object?> body, {
    Map<String, String> queryParameters = const {},
    String? accessToken,
  }) async {
    final response = await client
        .post(
          config.authUri(action, queryParameters),
          headers: {
            'apikey': config.publishableKey,
            'Content-Type': 'application/json',
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final responseError = SupabaseError.fromResponse(response);
      final message = switch (responseError.code) {
        'invalid_credentials' => 'E-mail ou senha incorretos.',
        'email_not_confirmed' => 'Confirme seu e-mail antes de entrar.',
        'email_address_invalid' => 'Informe um e-mail válido.',
        'email_address_not_authorized' => 'O envio de confirmação para este e-mail ainda não está habilitado. Entre em contato com a equipe do aplicativo.',
        'user_already_exists' || 'email_exists' =>
          'Não foi possível cadastrar este e-mail. Tente entrar na sua conta.',
        'weak_password' => 'Use uma senha mais forte.',
        'over_email_send_rate_limit' || 'over_request_rate_limit' =>
          'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
        'signup_disabled' => 'O cadastro de contas está indisponível.',
        'email_provider_disabled' =>
          'O login por e-mail está desabilitado no Supabase.',
        'flow_state_not_found' || 'flow_state_expired' =>
          'A tentativa de login expirou. Tente novamente.',
        'bad_code_verifier' =>
          'Não foi possível validar o login. Tente novamente.',
        'provider_disabled' =>
          'O login com Google está desabilitado no Supabase.',
        'request_timeout' => 'O Supabase excedeu o tempo para processar a solicitação. Tente novamente.',
        'unexpected_failure' => 'O Supabase encontrou uma falha interna. Verifique os logs de autenticação no painel.',
        _ => responseError.userMessage(
          'Não foi possível concluir a autenticação.',
        ),
      };
      throw AuthException(
        message,
        statusCode: response.statusCode,
        responseError: responseError,
      );
    }
    if (response.bodyBytes.isEmpty) return {};
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Resposta de autenticação inválida.');
    }
    return data;
  }
}

class AuthException extends SupabaseRequestException {
  const AuthException(super.message, {super.statusCode, super.responseError});
}

class OAuthCanceledException implements Exception {
  const OAuthCanceledException();
}
