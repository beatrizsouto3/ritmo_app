import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/data/repositories/subject_repository.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/services/subject_service.dart';
import 'package:ritmo_app/ui/subjects/subjects_view.dart';
import 'package:ritmo_app/ui/subjects/subjects_view_model.dart';

void main() {
  const config = SupabaseConfig(
    url: 'https://ritmo-test.supabase.co',
    publishableKey: 'public-test-key',
  );

  test('service loads subjects through the Supabase REST API', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/disciplinas');
      expect(request.url.queryParameters, {
        'select': 'id,nome',
        'order': 'id.asc',
      });
      expect(request.headers['apikey'], config.publishableKey);
      expect(request.headers.containsKey('authorization'), isFalse);
      return _jsonResponse([
        {'id': 7, 'nome': 'Matemática'},
        {'id': 12, 'nome': 'Português'},
      ]);
    });
    addTearDown(client.close);
    final repository = SubjectRepository(
      SubjectService(config: config, client: client),
    );
    final subjects = await repository.getSubjects();
    expect(subjects.map((subject) => subject.id), [7, 12]);
    expect(subjects.map((subject) => subject.name), [
      'Matemática',
      'Português',
    ]);
  });

  test('creation sends the normalized name and uses the server ID', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/disciplinas');
      expect(request.headers['prefer'], 'return=representation');
      expect(request.headers['authorization'], 'Bearer user-access-token');
      expect(jsonDecode(request.body), {'nome': 'Matemática'});
      return _jsonResponse([
        {'id': 42},
      ], status: 201);
    });
    addTearDown(client.close);
    final repository = SubjectRepository(
      SubjectService(
        config: config,
        client: client,
        accessToken: () async => 'user-access-token',
      ),
    );
    final subject = await repository.createSubject('  Matemática  ');
    expect(subject.id, 42);
    expect(subject.name, 'Matemática');
    expect(calls, 1);
  });

  test('blank names are rejected before any HTTP request', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return _jsonResponse([]);
    });
    addTearDown(client.close);
    final repository = SubjectRepository(
      SubjectService(config: config, client: client),
    );
    for (final name in ['', '   ', '\t\n']) {
      await expectLater(repository.createSubject(name), throwsArgumentError);
    }
    expect(calls, 0);
  });

  test(
    'HTTP errors are not interpreted as empty lists or successful saves',
    () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return _jsonResponse({'message': 'Acesso negado.'}, status: 403);
      });
      addTearDown(client.close);
      final service = SubjectService(config: config, client: client);
      final error = isA<SubjectRequestException>().having(
        (exception) => exception.statusCode,
        'statusCode',
        403,
      );
      await expectLater(service.getSubjects(), throwsA(error));
      await expectLater(service.createSubject('Matemática'), throwsA(error));
      expect(calls, 2);
    },
  );

  test('creation rejects a success response without a server ID', () async {
    for (final data in [
      [],
      [
        {'id': null},
      ],
      [
        {'id': '42'},
      ],
    ]) {
      final client = MockClient((_) async => _jsonResponse(data, status: 201));
      addTearDown(client.close);
      await expectLater(
        SubjectService(config: config, client: client).createSubject('Física'),
        throwsFormatException,
      );
    }
  });

  test('missing configuration fails before sending a request', () async {
    final client = MockClient((_) async {
      fail('Não deve enviar requisição sem configuração.');
    });
    addTearDown(client.close);
    final service = SubjectService(
      config: const SupabaseConfig(url: '', publishableKey: ''),
      client: client,
    );
    await expectLater(service.getSubjects(), throwsStateError);
  });

  test('view model recovers from load and save failures', () async {
    final service = _ControlledSubjectService();
    final viewModel = SubjectsViewModel(SubjectRepository(service));
    addTearDown(viewModel.dispose);
    service.failLoad = true;
    await viewModel.loadSubjects();
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.loadError, isNotNull);
    service.failLoad = false;
    await viewModel.loadSubjects();
    expect(viewModel.loadError, isNull);
    service.failSave = true;
    expect(await viewModel.createSubject('Matemática'), isFalse);
    expect(viewModel.isSaving, isFalse);
    expect(viewModel.saveError, isNotNull);
    expect(viewModel.subjects, isEmpty);
    service.failSave = false;
    expect(await viewModel.createSubject('Matemática'), isTrue);
    expect(viewModel.saveError, isNull);
    expect(viewModel.subjects.single.name, 'Matemática');
  });

  test('view model rejects blank names and concurrent saves', () async {
    final service = _ControlledSubjectService();
    final viewModel = SubjectsViewModel(SubjectRepository(service));
    addTearDown(viewModel.dispose);
    expect(await viewModel.createSubject('  '), isFalse);
    expect(service.saveCalls, 0);
    service.pendingSave = Completer<int>();
    final saving = viewModel.createSubject('Matemática');
    expect(viewModel.isSaving, isTrue);
    expect(await viewModel.createSubject('Matemática'), isFalse);
    expect(service.saveCalls, 1);
    service.pendingSave!.complete(1);
    expect(await saving, isTrue);
    expect(viewModel.subjects, hasLength(1));
  });

  testWidgets('empty state, validation, cancel and successful creation', (
    tester,
  ) async {
    final service = _ControlledSubjectService();
    final viewModel = SubjectsViewModel(SubjectRepository(service));
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: SubjectsView()),
      ),
    );
    expect(find.text('Sua lista começa aqui'), findsOneWidget);
    await tester.tap(find.text('Adicionar disciplina'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome da disciplina.'), findsOneWidget);
    expect(service.saveCalls, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Adicionar disciplina'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  Matemática  ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Matemática'), findsOneWidget);
    expect(find.text('Disciplina cadastrada.'), findsOneWidget);
    expect(find.text('Sua lista começa aqui'), findsNothing);
  });

  testWidgets('failed save keeps the name for retry on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _ControlledSubjectService()..failSave = true;
    final viewModel = SubjectsViewModel(SubjectRepository(service));
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: SubjectsView()),
      ),
    );
    await tester.tap(find.text('Adicionar disciplina'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Física');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível salvar a disciplina. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Física'), findsOneWidget);
    service.failSave = false;
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(viewModel.subjects.single.name, 'Física');
    expect(tester.takeException(), isNull);
  });
}

class _ControlledSubjectService extends SubjectService {
  _ControlledSubjectService()
    : super(
        config: const SupabaseConfig(
          url: 'https://ritmo-test.supabase.co',
          publishableKey: 'public-test-key',
        ),
        client: MockClient((_) async => _jsonResponse([])),
      );

  bool failLoad = false;
  bool failSave = false;
  int saveCalls = 0;
  Completer<int>? pendingSave;

  @override
  Future<List<Map<String, Object?>>> getSubjects() async {
    if (failLoad) throw StateError('Falha de leitura simulada.');
    return [];
  }

  @override
  Future<int> createSubject(String name) async {
    saveCalls++;
    if (failSave) throw StateError('Falha de gravação simulada.');
    return pendingSave?.future ?? Future.value(saveCalls);
  }
}

http.Response _jsonResponse(Object data, {int status = 200}) {
  return http.Response.bytes(utf8.encode(jsonEncode(data)), status);
}
