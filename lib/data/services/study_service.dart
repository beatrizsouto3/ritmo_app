import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/errors/request_error.dart';

class StudyService {
  StudyService({
    required this.config,
    required this.client,
    required this.accessToken,
    required this.userId,
  });
  final SupabaseConfig config;
  final http.Client client;
  final Future<String> Function() accessToken;
  final String Function() userId;

  Future<List<Map<String, dynamic>>> _request(
    String method,
    String table, {
    Map<String, String> query = const {},
    Map<String, Object>? body,
    bool upsert = false,
    bool ignoreDuplicate = false,
  }) async {
    final uri = config.tableUri(table, query);
    final headers = {
      'apikey': config.publishableKey,
      'Authorization': 'Bearer ${await accessToken()}',
      'Content-Type': 'application/json',
      'Prefer':
          'return=representation${upsert
              ? ',resolution=merge-duplicates'
              : ignoreDuplicate
              ? ',resolution=ignore-duplicates'
              : ''}',
    };
    final response =
        await (method == 'GET'
                ? client.get(uri, headers: headers)
                : client.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = SupabaseError.fromResponse(response);
      throw SupabaseRequestException(
        error.userMessage('Não foi possível acessar seus estudos.'),
        statusCode: response.statusCode,
        responseError: error,
      );
    }
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> preferences() =>
      _request('GET', 'preferencias_estudo');
  Future<void> savePreferences(Map<String, Object> values) => _request(
    'POST',
    'preferencias_estudo',
    query: const {'on_conflict': 'usuario_id'},
    body: {...values, 'usuario_id': userId()},
    upsert: true,
  );
  Future<List<Map<String, dynamic>>> sessions() => _request(
    'GET',
    'sessoes_foco',
    query: const {'order': 'concluido_em.desc'},
  );
  Future<void> saveSession(Map<String, Object> values) async {
    final saved = await _request(
      'POST',
      'sessoes_foco',
      query: const {'on_conflict': 'id'},
      body: values,
      ignoreDuplicate: true,
    );
    if (saved.any((row) => row['id'] == values['id'])) return;

    final existing = await _request(
      'GET',
      'sessoes_foco',
      query: {'id': 'eq.${values['id']}', 'select': 'id'},
    );
    if (existing.any((row) => row['id'] == values['id'])) return;
    throw const SupabaseRequestException(
      'Não foi possível confirmar o ciclo salvo. Tente salvar novamente.',
    );
  }
}
