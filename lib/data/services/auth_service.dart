import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../domain/models/auth_session.dart';

class AuthService {
  AuthService({required this.config, required this.client});

  final SupabaseConfig config;
  final http.Client client;

  Future<AuthSession> signIn(String email, String password) async {
    final data = await _post(
      'token',
      {'email': email, 'password': password},
      queryParameters: {'grant_type': 'password'},
    );
    return AuthSession.fromJson(data);
  }

  Future<AuthSession?> signUp(String email, String password) async {
    final data = await _post('signup', {'email': email, 'password': password});
    if (data['access_token'] == null) {
      if (data['id'] is! String && data['user'] is! Map) {
        throw const FormatException('Resposta de cadastro inválida.');
      }
      return null;
    }
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> refreshSession(String refreshToken) async {
    final data = await _post(
      'token',
      {'refresh_token': refreshToken},
      queryParameters: {'grant_type': 'refresh_token'},
    );
    return AuthSession.fromJson(data);
  }

  Future<void> signOut(String accessToken) async {
    await _post(
      'logout',
      const {},
      queryParameters: {'scope': 'local'},
      accessToken: accessToken,
    );
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
      String? code;
      try {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        if (error is Map) code = error['error_code'] as String?;
      } on FormatException {
        code = null;
      }
      final message = switch (code) {
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
        _ => 'Não foi possível concluir a autenticação. Tente novamente.',
      };
      throw AuthException(message, statusCode: response.statusCode);
    }
    if (response.bodyBytes.isEmpty) return {};
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Resposta de autenticação inválida.');
    }
    return data;
  }
}

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
