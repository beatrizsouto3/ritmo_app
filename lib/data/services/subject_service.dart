import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/errors/request_error.dart';
import 'subject_contract.dart';

class SubjectService {
  SubjectService({
    required this.config,
    required this.client,
    this.accessToken,
  });

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

  Future<List<Map<String, Object?>>> getSubjects() async {
    final response = await client
        .get(
          config.tableUri(SubjectContract.table, {
            'select':
                '${SubjectContract.idColumn},${SubjectContract.nameColumn}',
            'order': '${SubjectContract.idColumn}.asc',
          }),
          headers: await _headers,
        )
        .timeout(const Duration(seconds: 15));
    return _decodeRows(response);
  }

  Future<int> createSubject(String name) async {
    final response = await client
        .post(
          config.tableUri(SubjectContract.table, {
            'select': SubjectContract.idColumn,
          }),
          headers: {...await _headers, 'Prefer': 'return=representation'},
          body: jsonEncode({SubjectContract.nameColumn: name}),
        )
        .timeout(const Duration(seconds: 15));
    final rows = _decodeRows(response);
    if (rows.length != 1 || rows.single[SubjectContract.idColumn] is! int) {
      throw const FormatException('Resposta inválida ao cadastrar disciplina.');
    }
    return rows.single[SubjectContract.idColumn] as int;
  }

  List<Map<String, Object?>> _decodeRows(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SubjectRequestException(
        response.statusCode,
        responseError: SupabaseError.fromResponse(response),
      );
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) {
      throw const FormatException(
        'Resposta inválida ao consultar disciplinas.',
      );
    }
    return data.map((row) => Map<String, Object?>.from(row as Map)).toList();
  }
}

class SubjectRequestException extends SupabaseRequestException {
  SubjectRequestException(int statusCode, {super.responseError})
    : super(
        responseError?.userMessage(
              'Não foi possível acessar as disciplinas.',
            ) ??
            'Não foi possível acessar as disciplinas (HTTP $statusCode).',
        statusCode: statusCode,
      );
}
