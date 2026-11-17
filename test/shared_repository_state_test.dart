import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/planned_session_repository.dart';
import 'package:ritmo_app/data/repositories/question_repository.dart';
import 'package:ritmo_app/data/repositories/topic_repository.dart';
import 'package:ritmo_app/data/services/planning_service.dart';
import 'package:ritmo_app/data/services/topic_service.dart';
import 'package:ritmo_app/domain/models/planned_session.dart';
import 'package:ritmo_app/domain/models/question_record.dart';
import 'package:ritmo_app/ui/dashboard/dashboard_metrics_view_model.dart';

void main() {
  test('dashboard follows repository changes without a second load', () async {
    const config = SupabaseConfig(
      url: 'https://example.supabase.co',
      publishableKey: 'public-key',
    );
    final now = DateTime.now();
    final client = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'GET') {
        if (path.endsWith('/topicos')) {
          return _rows([_topic(null)]);
        }
        return _rows([]);
      }
      if (request.method == 'PATCH' && path.endsWith('/topicos')) {
        return _rows([_topic(now.toUtc().toIso8601String())]);
      }
      if (request.method == 'POST' &&
          (path.endsWith('/registros_questoes') ||
              path.endsWith('/sessoes_planejadas'))) {
        final row = jsonDecode(request.body) as Map<String, dynamic>;
        return _rows([
          {'id': 1, ...row},
        ]);
      }
      fail('Unexpected request: ${request.method} $path');
    });
    addTearDown(client.close);
    final planning = PlanningService(
      config: config,
      client: client,
      accessToken: () async => 'token',
    );
    final questions = QuestionRepository(planning);
    final planned = PlannedSessionRepository(planning);
    final topics = TopicRepository(
      TopicService(
        config: config,
        client: client,
        accessToken: () async => 'token',
      ),
    );
    final dashboard = DashboardMetricsViewModel(questions, topics, planned);
    addTearDown(dashboard.dispose);
    addTearDown(questions.dispose);
    addTearDown(planned.dispose);
    addTearDown(topics.dispose);

    await dashboard.load();
    expect(dashboard.error, isNull);
    expect(dashboard.totalQuestions, 0);
    expect(dashboard.week, isEmpty);
    expect(dashboard.urgentTopics(now), hasLength(1));

    await questions.create(
      QuestionRecord(
        id: 0,
        subjectId: 2,
        topicId: 1,
        total: 10,
        correct: 9,
        incorrect: 1,
        recordedAt: now,
      ),
    );
    expect(dashboard.totalQuestions, 10);
    expect(dashboard.accuracy, 0.9);

    await topics.markReviewed(1);
    expect(dashboard.urgentTopics(now), isEmpty);

    await planned.create(
      PlannedSession(
        id: 0,
        subjectId: 2,
        topicId: 1,
        startsAt: DateTime(now.year, now.month, now.day, 12),
        endsAt: DateTime(now.year, now.month, now.day, 13),
        status: PlannedSessionStatus.planned,
        notes: null,
      ),
    );
    expect(dashboard.week, hasLength(1));
  });
}

http.Response _rows(List<Map<String, Object?>> rows) => http.Response(
  jsonEncode(rows),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> _topic(String? lastReviewedAt) => {
  'id': 1,
  'disciplina_id': 2,
  'nome': 'Funções',
  'ordem': 0,
  'teoria_lida': false,
  'resumo_feito': false,
  'exercicios_resolvidos': false,
  'ultima_revisao_em': lastReviewedAt,
};
