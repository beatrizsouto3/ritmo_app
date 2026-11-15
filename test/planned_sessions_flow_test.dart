import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/planned_session_repository.dart';
import 'package:ritmo_app/data/repositories/subject_repository.dart';
import 'package:ritmo_app/data/repositories/topic_repository.dart';
import 'package:ritmo_app/data/services/planning_service.dart';
import 'package:ritmo_app/data/services/subject_service.dart';
import 'package:ritmo_app/data/services/topic_service.dart';
import 'package:ritmo_app/domain/models/planned_session.dart';
import 'package:ritmo_app/ui/study/planned_sessions_view.dart';
import 'package:ritmo_app/ui/study/planned_sessions_view_model.dart';

void main() {
  testWidgets('weekly schedule creates, edits, changes status and deletes', (
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
    final rows = <Map<String, dynamic>>[];
    var conflict = false;
    var writes = 0;
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-token');
      switch (request.url.path) {
        case '/rest/v1/disciplinas':
          return _jsonResponse([
            {'id': 3, 'nome': 'Matemática'},
          ]);
        case '/rest/v1/topicos':
          return _jsonResponse([]);
        case '/rest/v1/sessoes_planejadas':
          if (request.method == 'GET') {
            if (request.url.queryParameters['select'] == 'id') {
              return _jsonResponse(
                conflict
                    ? [
                        {'id': 99},
                      ]
                    : [],
              );
            }
            return _jsonResponse(rows);
          }
          if (request.method == 'DELETE') {
            expect(request.url.queryParameters['id'], 'eq.11');
            rows.clear();
            writes++;
            return _jsonResponse([
              {'id': 11},
            ]);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['disciplina_id'], 3);
          expect(body.containsKey('usuario_id'), isFalse);
          final saved = {'id': 11, ...body};
          if (request.method == 'POST') {
            rows.add(saved);
          } else if (request.method == 'PATCH') {
            expect(request.url.queryParameters['id'], 'eq.11');
            rows[0] = saved;
          } else {
            fail('Método inesperado: ${request.method}');
          }
          writes++;
          return _jsonResponse([
            saved,
          ], status: request.method == 'POST' ? 201 : 200);
        default:
          fail('Caminho inesperado: ${request.url.path}');
      }
    });
    addTearDown(client.close);
    Future<String> accessToken() async => 'test-token';
    final viewModel = PlannedSessionsViewModel(
      PlannedSessionRepository(
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
        TopicService(config: config, client: client, accessToken: accessToken),
      ),
    );
    addTearDown(viewModel.dispose);
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
          home: const PlannedSessionsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma sessão planejada.', skipOffstage: false),
      findsWidgets,
    );
    await tester.tap(find.text('Planejar sessão'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matemática').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(viewModel.sessions.single.status, PlannedSessionStatus.planned);
    expect(writes, 1);

    Future<void> chooseAction(String label) async {
      final actions = find.byTooltip('Ações da sessão');
      await tester.scrollUntilVisible(
        actions,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await chooseAction('Editar');
    await tester.enterText(find.byType(TextFormField), 'Capítulo 1');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(viewModel.sessions.single.notes, 'Capítulo 1');
    expect(writes, 2);

    conflict = true;
    await chooseAction('Editar');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(viewModel.actionError, 'Já existe uma sessão nesse horário.');
    expect(writes, 2);
    await tester.tap(find.text('Cancelar').last);
    await tester.pumpAndSettle();
    conflict = false;

    await chooseAction('Marcar como realizada');
    expect(viewModel.sessions.single.status, PlannedSessionStatus.completed);
    await chooseAction('Cancelar sessão');
    expect(viewModel.sessions.single.status, PlannedSessionStatus.cancelled);
    await chooseAction('Excluir');
    expect(find.text('Excluir sessão?'), findsOneWidget);
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(viewModel.sessions, isEmpty);
    expect(writes, 5);

    final firstWeek = viewModel.weekStart;
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Próxima semana'));
    await tester.pumpAndSettle();
    expect(viewModel.weekStart, firstWeek.add(const Duration(days: 7)));
    expect(tester.takeException(), isNull);
  });
}

http.Response _jsonResponse(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
