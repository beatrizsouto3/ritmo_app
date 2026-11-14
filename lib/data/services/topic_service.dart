import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import 'topic_contract.dart';

class TopicService {
  TopicService({required this.config, required this.client, this.accessToken});

  final SupabaseConfig config;
  final http.Client client;
  final Future<String> Function()? accessToken;

  Future<Map<String, String>> get _headers async {
    final token = await accessToken?.call();
    return {
      'apikey': config.publishableKey,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, Object?>>> fetchTopics(int subjectId) async {
    final response = await client
        .get(
          config.tableUri(TopicContract.table, {
            'select': '*',
            TopicContract.subjectIdColumn: 'eq.$subjectId',
            'order':
                '${TopicContract.orderColumn}.asc,${TopicContract.idColumn}.asc',
          }),
          headers: await _headers,
        )
        .timeout(const Duration(seconds: 15));
    return _decodeRows(response);
  }

  Future<Map<String, Object?>> createTopic({
    required int subjectId,
    required String name,
    required int order,
  }) async {
    final response = await client
        .post(
          config.tableUri(TopicContract.table, const {'select': '*'}),
          headers: {...await _headers, 'Prefer': 'return=representation'},
          body: jsonEncode({
            TopicContract.subjectIdColumn: subjectId,
            TopicContract.nameColumn: name,
            TopicContract.orderColumn: order,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeSingle(response, 'criar tópico');
  }

  Future<Map<String, Object?>> updateTopic({
    required int topicId,
    required String name,
    required int order,
    required bool theoryRead,
    required bool summaryMade,
    required bool exercisesSolved,
  }) async {
    final response = await client
        .patch(
          config.tableUri(TopicContract.table, {
            'select': '*',
            TopicContract.idColumn: 'eq.$topicId',
          }),
          headers: {...await _headers, 'Prefer': 'return=representation'},
          body: jsonEncode({
            TopicContract.nameColumn: name,
            TopicContract.orderColumn: order,
            TopicContract.theoryReadColumn: theoryRead,
            TopicContract.summaryMadeColumn: summaryMade,
            TopicContract.exercisesSolvedColumn: exercisesSolved,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeSingle(response, 'atualizar tópico');
  }

  Future<void> deleteTopic(int topicId) async {
    final response = await client
        .delete(
          config.tableUri(TopicContract.table, {
            TopicContract.idColumn: 'eq.$topicId',
          }),
          headers: await _headers,
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TopicRequestException(response.statusCode);
    }
  }

  Map<String, Object?> _decodeSingle(http.Response response, String action) {
    final rows = _decodeRows(response);
    if (rows.length != 1) {
      throw FormatException('Resposta inválida ao $action.');
    }
    return rows.single;
  }

  List<Map<String, Object?>> _decodeRows(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TopicRequestException(response.statusCode);
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) {
      throw const FormatException('Resposta inválida ao consultar tópicos.');
    }
    return data.map((row) => Map<String, Object?>.from(row as Map)).toList();
  }
}

class TopicRequestException implements Exception {
  const TopicRequestException(this.statusCode);

  final int statusCode;

  @override
  String toString() =>
      'Não foi possível acessar os tópicos (HTTP $statusCode).';
}
