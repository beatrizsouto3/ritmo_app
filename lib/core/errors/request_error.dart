import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'transport_error_message.dart'
    if (dart.library.io) 'transport_error_message_io.dart';

class SupabaseError {
  const SupabaseError({
    required this.statusCode,
    this.code,
    this.message,
    this.details,
    this.hint,
  });

  final int statusCode;
  final String? code;
  final String? message;
  final String? details;
  final String? hint;

  factory SupabaseError.fromResponse(http.Response response) {
    Map<String, dynamic> data = const {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } on FormatException {
      // Mantém o status HTTP quando o servidor não retorna JSON válido.
    }
    String? read(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    return SupabaseError(
      statusCode: response.statusCode,
      code: read('error_code') ?? read('code'),
      message:
          read('message') ??
          read('msg') ??
          read('error_description') ??
          read('error'),
      details: read('details'),
      hint: read('hint'),
    );
  }

  String userMessage(String fallback) {
    final description = switch (code) {
      '42501' => 'Sua conta não tem permissão para esta operação. Verifique as políticas de acesso (RLS) do Supabase.',
      '42P01' || 'PGRST205' => 'A tabela solicitada não está disponível no Supabase. Verifique o schema e as migrações.',
      '42703' || 'PGRST204' => 'Uma coluna esperada pelo aplicativo não está disponível no Supabase. Verifique as migrações.',
      '42883' || 'PGRST202' => 'A função solicitada não está disponível no Supabase. Verifique as migrações e os parâmetros.',
      '23505' => 'Já existe um registro com esses dados.',
      '23503' => 'A operação depende de um registro relacionado que não existe ou ainda está em uso.',
      '23502' => 'Um campo obrigatório não foi informado.',
      '23514' => 'Os dados não atendem às regras de validação do banco.',
      'PGRST301' ||
      'PGRST303' ||
      'bad_jwt' ||
      'session_expired' ||
      'session_not_found' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' =>
        'Sua sessão não é mais válida. Entre novamente.',
      'PGRST000' || 'PGRST001' || 'PGRST002' || 'PGRST003' => 'O serviço do Supabase não conseguiu acessar o banco de dados. Tente novamente mais tarde.',
      _ => switch (statusCode) {
        400 || 422 => 'O Supabase recusou os dados enviados. Verifique os campos e a configuração do aplicativo.',
        401 => 'A autenticação foi recusada. Entre novamente; se persistir, verifique a configuração do Supabase.',
        403 => 'Sua conta não tem permissão para esta operação.',
        404 => 'O recurso solicitado não foi encontrado no Supabase.',
        409 => 'A operação entrou em conflito com os dados existentes.',
        408 => 'O servidor excedeu o tempo para processar a solicitação. Tente novamente.',
        429 => 'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
        >= 500 => 'O Supabase retornou uma falha no servidor. Tente novamente mais tarde.',
        _ => fallback,
      },
    };
    final reference =
        code != null && RegExp(r'^[a-zA-Z0-9_]{1,80}$').hasMatch(code!)
        ? 'HTTP $statusCode; código $code'
        : 'HTTP $statusCode';
    return '$description ($reference)';
  }
}

class SupabaseRequestException implements Exception {
  const SupabaseRequestException(
    this.message, {
    this.statusCode,
    this.responseError,
  });

  final String message;
  final int? statusCode;
  final SupabaseError? responseError;

  @override
  String toString() => message;
}

class SupabaseConfigurationException extends StateError {
  SupabaseConfigurationException(super.message);
}

String requestErrorMessage(
  Object error, {
  StackTrace? stackTrace,
  String fallback =
      'Ocorreu um erro inesperado no aplicativo. Tente novamente.',
}) {
  if (kDebugMode) {
    final response = error is SupabaseRequestException
        ? error.responseError
        : null;
    developer.log(
      response == null
          ? 'Falha do tipo ${error.runtimeType}.'
          : 'HTTP ${response.statusCode}; código ${response.code}; '
                'mensagem: ${response.message}; detalhes: ${response.details}; dica: ${response.hint}',
      name: 'ritmo.requests',
      error: error,
      stackTrace: stackTrace,
    );
  }
  if (error is SupabaseRequestException) return error.message;
  if (error is TimeoutException) {
    return 'O tempo de espera pela resposta do servidor esgotou. Tente novamente.';
  }
  final transportMessage = transportErrorMessage(error);
  if (transportMessage != null) return transportMessage;
  if (error is http.ClientException) {
    return 'Não foi possível estabelecer a conexão com o servidor. Verifique sua conexão e a URL do Supabase.';
  }
  if (error is SupabaseConfigurationException) return error.message;
  if (error is FormatException || error is TypeError) {
    return 'A resposta do servidor não tem o formato esperado pelo aplicativo. Verifique a configuração e as versões do banco e do app.';
  }
  if (error is ArgumentError) return error.message.toString();
  return fallback;
}
