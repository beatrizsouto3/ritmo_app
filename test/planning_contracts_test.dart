import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/planned_session_repository.dart';
import 'package:ritmo_app/data/repositories/question_repository.dart';
import 'package:ritmo_app/data/services/planning_service.dart';
import 'package:ritmo_app/domain/models/planned_session.dart';
import 'package:ritmo_app/domain/models/question_record.dart';

void main() {
  const config = SupabaseConfig(
    url: 'https://example.supabase.co',
    publishableKey: 'public-key',
  );

  test(
    'planned sessions use a bounded week and authenticated request',
    () async {
      late http.Request captured;
      final service = PlanningService(
        config: config,
        client: MockClient((request) async {
          captured = request;
          return http.Response('[]', 200);
        }),
        accessToken: () async => 'access-token',
      );
      final rows = await PlannedSessionRepository(service)
          .getWeek(DateTime(2026, 11, 18));
      expect(rows, isEmpty);
      expect(captured.url.path, '/rest/v1/sessoes_planejadas');
      expect(captured.headers['authorization'], 'Bearer access-token');
      expect(
        captured.url.queryParameters['and'],
        contains('inicio_em.gte.2026-11-16'),
      );
      expect(captured.url.queryParameters['and'], contains('2026-11-23'));
    },
  );

  test(
    'question counts are validated before sending and serialized for SQL',
    () async {
      var calls = 0;
      final service = PlanningService(
        config: config,
        client: MockClient((request) async {
          calls++;
          expect(request.url.path, '/rest/v1/registros_questoes');
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['disciplina_id'], 3);
          expect(body['topico_id'], isNull);
          expect(body['total'], 10);
          expect(body['acertos'], 7);
          expect(body['erros'], 3);
          expect(body.containsKey('usuario_id'), isFalse);
          return http.Response(
            jsonEncode([
              {'id': 9, ...body},
            ]),
            201,
          );
        }),
        accessToken: () async => 'access-token',
      );
      final repository = QuestionRepository(service);
      final now = DateTime.utc(2026, 11, 14);
      await expectLater(
        repository.create(
          QuestionRecord(
            id: 0,
            subjectId: 3,
            topicId: null,
            total: 10,
            correct: 8,
            incorrect: 3,
            recordedAt: now,
          ),
        ),
        throwsArgumentError,
      );
      expect(calls, 0);
      final saved = await repository.create(
        QuestionRecord(
          id: 0,
          subjectId: 3,
          topicId: null,
          total: 10,
          correct: 7,
          incorrect: 3,
          recordedAt: now,
        ),
      );
      expect(saved.accuracy, 0.7);
      expect(calls, 1);
    },
  );

  test('planned session rejects an interval ending before it starts', () async {
    final service = PlanningService(
      config: config,
      client: MockClient((_) async => throw StateError('unexpected request')),
      accessToken: () async => 'access-token',
    );
    final now = DateTime.utc(2026, 11, 14);
    await expectLater(
      PlannedSessionRepository(service).create(
        PlannedSession(
          id: 0,
          subjectId: 3,
          topicId: null,
          startsAt: now,
          endsAt: now,
          status: PlannedSessionStatus.planned,
          notes: null,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('planned session deletion accepts the returned id only', () async {
    final service = PlanningService(
      config: config,
      client: MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/rest/v1/sessoes_planejadas');
        expect(request.url.queryParameters['id'], 'eq.12');
        return http.Response('[{"id":12}]', 200);
      }),
      accessToken: () async => 'access-token',
    );
    await PlannedSessionRepository(service).delete(12);
  });

  test(
    'conflict lookup includes sessions crossing the week boundary',
    () async {
      var calls = 0;
      final service = PlanningService(
        config: config,
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'GET');
          expect(request.url.path, '/rest/v1/sessoes_planejadas');
          expect(request.url.queryParameters['select'], 'id');
          final filters = request.url.queryParameters['and']!;
          expect(filters, contains('estado.neq.cancelled'));
          expect(filters, contains('id.neq.12'));
          expect(filters, contains('inicio_em.lt.'));
          expect(filters, contains('fim_em.gt.'));
          return http.Response('[{"id":7}]', 200);
        }),
        accessToken: () async => 'access-token',
      );
      final session = PlannedSession(
        id: 12,
        subjectId: 3,
        topicId: null,
        startsAt: DateTime(2026, 11, 16, 0, 15),
        endsAt: DateTime(2026, 11, 16, 1),
        status: PlannedSessionStatus.planned,
        notes: null,
      );
      expect(
        await PlannedSessionRepository(service).hasConflict(session),
        isTrue,
      );
      expect(calls, 1);
      final cancelled = PlannedSession(
        id: session.id,
        subjectId: session.subjectId,
        topicId: session.topicId,
        startsAt: session.startsAt,
        endsAt: session.endsAt,
        status: PlannedSessionStatus.cancelled,
        notes: session.notes,
      );
      expect(
        await PlannedSessionRepository(service).hasConflict(cancelled),
        isFalse,
      );
      expect(calls, 1);
    },
  );
}
