import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/topic_repository.dart';
import 'package:ritmo_app/data/services/topic_service.dart';
import 'package:ritmo_app/ui/subjects/topics_view.dart';

void main() {
  testWidgets('topic steps update independently and progress survives reload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final row = <String, Object?>{
      'id': 8,
      'disciplina_id': 3,
      'nome': 'Álgebra',
      'ordem': 0,
      'teoria_lida': false,
      'resumo_feito': false,
      'exercicios_resolvidos': false,
      'ultima_revisao_em': null,
    };
    var deleted = false;
    var updates = 0;
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-token');
      if (request.method == 'GET') {
        return _jsonResponse(deleted ? [] : [row]);
      }
      if (request.method == 'PATCH') {
        updates++;
        row.addAll(jsonDecode(request.body) as Map<String, dynamic>);
        return _jsonResponse([row]);
      }
      if (request.method == 'DELETE') {
        deleted = true;
        return http.Response('', 204);
      }
      fail('Método inesperado: ${request.method}');
    });
    addTearDown(client.close);
    const config = SupabaseConfig(
      url: 'https://ritmo-test.supabase.co',
      publishableKey: 'public-test-key',
    );
    final repository = TopicRepository(
      TopicService(
        config: config,
        client: client,
        accessToken: () async => 'test-token',
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const TopicsView(subjectId: 3, subjectName: 'Matemática'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final (label, percent) in [
      ('Teoria lida', '33%'),
      ('Resumo feito', '67%'),
      ('Exercícios resolvidos', '100%'),
    ]) {
      final check = find.widgetWithText(CheckboxListTile, label);
      await tester.ensureVisible(check);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(check).value, isTrue);
      expect(find.text(percent, skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(updates, 3);
    expect(row['teoria_lida'], isTrue);
    expect(row['resumo_feito'], isTrue);
    expect(row['exercicios_resolvidos'], isTrue);

    final menu = find.byType(PopupMenuButton<String>);
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Excluir tópico?'), findsOneWidget);
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(find.text('Nenhum tópico cadastrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

http.Response _jsonResponse(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
