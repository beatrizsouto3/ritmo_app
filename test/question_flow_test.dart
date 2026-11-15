import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/question_repository.dart';
import 'package:ritmo_app/data/repositories/subject_repository.dart';
import 'package:ritmo_app/data/repositories/topic_repository.dart';
import 'package:ritmo_app/data/services/planning_service.dart';
import 'package:ritmo_app/data/services/subject_service.dart';
import 'package:ritmo_app/data/services/topic_service.dart';
import 'package:ritmo_app/ui/questions/question_records_view.dart';
import 'package:ritmo_app/ui/questions/question_records_view_model.dart';

void main() {
  testWidgets(
    'question form persists a record and updates the visible history',
    (tester) async {
      const config = SupabaseConfig(
        url: 'https://ritmo-test.supabase.co',
        publishableKey: 'public-test-key',
      );
      final savedRows = <Map<String, dynamic>>[];
      var insertCalls = 0;
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-user-token');
        switch (request.url.path) {
          case '/rest/v1/disciplinas':
            return _jsonResponse([
              {'id': 3, 'nome': 'Matemática'},
            ]);
          case '/rest/v1/topicos':
            return _jsonResponse(<Object>[]);
          case '/rest/v1/registros_questoes':
            if (request.method == 'GET') return _jsonResponse(savedRows);
            expect(request.method, 'POST');
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['disciplina_id'], 3);
            expect(body['total'], 10);
            expect(body['acertos'], 7);
            expect(body['erros'], 3);
            expect(body.containsKey('usuario_id'), isFalse);
            insertCalls++;
            final saved = {'id': 9, ...body};
            savedRows.add(saved);
            return _jsonResponse([saved], status: 201);
          default:
            fail('Requisição inesperada: ${request.url.path}');
        }
      });
      addTearDown(client.close);
      Future<String> accessToken() async => 'test-user-token';
      final viewModel = QuestionRecordsViewModel(
        QuestionRepository(
          PlanningService(
            config: config,
            client: client,
            accessToken: accessToken,
          ),
        ),
        SubjectRepository(
          SubjectService(
            config: config,
            client: client,
            accessToken: accessToken,
          ),
        ),
        TopicRepository(
          TopicService(
            config: config,
            client: client,
            accessToken: accessToken,
          ),
        ),
      );
      addTearDown(viewModel.dispose);
      await viewModel.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const MaterialApp(home: QuestionRecordsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sem questões registradas'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matemática').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '10');
      await tester.enterText(find.byType(TextFormField).at(1), '7');
      await tester.enterText(find.byType(TextFormField).at(2), '3');
      tester.testTextInput.hide();
      final saveButton = find.widgetWithText(FilledButton, 'Salvar registro');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(insertCalls, 1);
      expect(viewModel.accuracy, 0.7);
      await tester.drag(find.byType(ListView), const Offset(0, 700));
      await tester.pumpAndSettle();
      expect(find.text('70.0%'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.text('7 acertos · 3 erros · ${_today()}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

http.Response _jsonResponse(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

String _today() {
  final date = DateTime.now();
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
