import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/question_repository.dart';
import 'package:ritmo_app/data/repositories/planned_session_repository.dart';
import 'package:ritmo_app/data/repositories/subject_repository.dart';
import 'package:ritmo_app/data/repositories/topic_repository.dart';
import 'package:ritmo_app/data/services/planning_service.dart';
import 'package:ritmo_app/data/services/subject_service.dart';
import 'package:ritmo_app/data/services/topic_service.dart';
import 'package:ritmo_app/ui/questions/question_records_view.dart';
import 'package:ritmo_app/ui/questions/question_records_view_model.dart';
import 'package:ritmo_app/ui/dashboard/dashboard_metrics_view_model.dart';

void main() {
  testWidgets('question history creates, edits, filters and deletes a record', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const config = SupabaseConfig(
      url: 'https://ritmo-test.supabase.co',
      publishableKey: 'public-test-key',
    );
    final savedRows = <Map<String, dynamic>>[];
    var insertCalls = 0;
    var updateCalls = 0;
    var deleteCalls = 0;
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-user-token');
      switch (request.url.path) {
        case '/rest/v1/disciplinas':
          return _jsonResponse([
            {'id': 3, 'nome': 'Matemática'},
            {'id': 4, 'nome': 'Física'},
          ]);
        case '/rest/v1/topicos':
          return _jsonResponse(<Object>[]);
        case '/rest/v1/sessoes_planejadas':
          return _jsonResponse(<Object>[]);
        case '/rest/v1/registros_questoes':
          if (request.method == 'GET') return _jsonResponse(savedRows);
          if (request.method == 'DELETE') {
            expect(request.url.queryParameters['id'], 'eq.9');
            deleteCalls++;
            savedRows.clear();
            return _jsonResponse([
              {'id': 9},
            ]);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['disciplina_id'], 3);
          expect(body['total'], 10);
          expect(body.containsKey('usuario_id'), isFalse);
          if (request.method == 'POST') {
            expect(body['acertos'], 7);
            expect(body['erros'], 3);
            insertCalls++;
          } else if (request.method == 'PATCH') {
            expect(request.url.queryParameters['id'], 'eq.9');
            expect(body['acertos'], 8);
            expect(body['erros'], 2);
            updateCalls++;
            savedRows.clear();
          } else {
            fail('Método inesperado: ${request.method}');
          }
          final saved = {'id': 9, ...body};
          savedRows.add(saved);
          return _jsonResponse([
            saved,
          ], status: request.method == 'POST' ? 201 : 200);
        default:
          fail('Requisição inesperada: ${request.url.path}');
      }
    });
    addTearDown(client.close);
    Future<String> accessToken() async => 'test-user-token';
    final planningService = PlanningService(
      config: config,
      client: client,
      accessToken: accessToken,
    );
    final questionRepository = QuestionRepository(planningService);
    final topicRepository = TopicRepository(
      TopicService(config: config, client: client, accessToken: accessToken),
    );
    final viewModel = QuestionRecordsViewModel(
      questionRepository,
      SubjectRepository(
        SubjectService(
          config: config,
          client: client,
          accessToken: accessToken,
        ),
      ),
      topicRepository,
    );
    addTearDown(viewModel.dispose);
    final dashboard = DashboardMetricsViewModel(
      questionRepository,
      topicRepository,
      PlannedSessionRepository(planningService),
    );
    addTearDown(dashboard.dispose);
    await viewModel.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const QuestionRecordsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sem questões registradas'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
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
    await tester.scrollUntilVisible(
      find.byTooltip('Ações do registro'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('7 acertos · 3 erros · ${_today()}'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações do registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar registro', skipOffstage: false), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!
          .text,
      '10',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '8');
    tester.testTextInput.hide();
    final updateButton = find.widgetWithText(FilledButton, 'Salvar alterações');
    await tester.ensureVisible(updateButton);
    await tester.pumpAndSettle();
    await tester.tap(updateButton);
    await tester.pumpAndSettle();
    expect(updateCalls, 0);
    expect(
      find.text('O total deve ser igual à soma de acertos e erros.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).at(2), '2');
    tester.testTextInput.hide();
    await tester.ensureVisible(updateButton);
    await tester.pumpAndSettle();
    await tester.tap(updateButton);
    await tester.pumpAndSettle();
    expect(updateCalls, 1);
    expect(viewModel.accuracy, 0.8);
    await dashboard.load();
    expect(dashboard.accuracy, 0.8);
    expect(dashboard.totalQuestions, 10);
    expect(dashboard.dailyAccuracy(DateTime.now()).last.accuracy, 0.8);

    final subjectFilter = find.byType(DropdownButtonFormField<int>).last;
    await tester.ensureVisible(subjectFilter);
    await tester.pumpAndSettle();
    await tester.tap(subjectFilter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Física').last);
    await tester.pumpAndSettle();
    expect(viewModel.filteredRecords, isEmpty);
    expect(
      find.text('Nenhum registro encontrado neste filtro.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(viewModel.filteredRecords, hasLength(1));

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    viewModel.setDateFilter(yesterday, yesterday);
    await tester.pumpAndSettle();
    expect(viewModel.filteredRecords, isEmpty);
    viewModel.clearFilters();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Ações do registro'));
    await tester.tap(find.byTooltip('Ações do registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir registro?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(deleteCalls, 0);
    await tester.tap(find.byTooltip('Ações do registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(deleteCalls, 1);
    expect(viewModel.records, isEmpty);
    expect(viewModel.totalQuestions, 0);
    await dashboard.load();
    expect(dashboard.accuracy, isNull);
    expect(dashboard.records, isEmpty);
    expect(tester.takeException(), isNull);
  });
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
