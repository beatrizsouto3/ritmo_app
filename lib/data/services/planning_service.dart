import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/errors/request_error.dart';

class PlanningService {
  const PlanningService({
    required this.config,
    required this.client,
    required this.accessToken,
  });

  final SupabaseConfig config;
  final http.Client client;
  final Future<String> Function() accessToken;

  Future<List<Map<String, dynamic>>> request(
    String method,
    String table, {
    Map<String, String> query = const {},
    Map<String, Object?>? body,
  }) async {
    final headers = {
      'apikey': config.publishableKey,
      'Authorization': 'Bearer ${await accessToken()}',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
    final uri = config.tableUri(table, query);
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await client.send(request).timeout(const Duration(seconds: 15)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = SupabaseError.fromResponse(response);
      throw SupabaseRequestException(
        error.userMessage('Não foi possível acessar os registros de estudo.'),
        statusCode: response.statusCode,
        responseError: error,
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException('Resposta inválida ao consultar registros.');
    }
    return decoded.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }
}
