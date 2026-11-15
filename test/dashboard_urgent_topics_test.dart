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
import 'package:ritmo_app/ui/dashboard/dashboard_metrics_view_model.dart';

void main() {
  const config = SupabaseConfig(
    url: 'https://example.supabase.co',
    publishableKey: 'public-key',
  );
  final now = DateTime.utc(2026, 11, 15, 12);

  test('urgent topics use actual review dates and include topics without questions', () async {
    final client = MockClient((request) async {
      switch (request.url.path) {
        case '/rest/v1/topicos':
          return _rows([
            _topic(1, null),
            _topic(2, null),
            _topic(3, now.subtract(const Duration(days: 2))),
            _topic(4, now.subtract(const Duration(days: 8))),
            _topic(5, now.subtract(const Duration(days: 2))),
          ]);
        case '/rest/v1/registros_questoes':
          return _rows([
            _record(2, 10, 9, now.subtract(const Duration(days: 1))),
            _record(3, 10, 9, now.subtract(const Duration(days: 20))),
            _record(4, 10, 9, now.subtract(const Duration(days: 1))),
            _record(5, 10, 6, now.subtract(const Duration(days: 1))),
          ]);
        case '/rest/v1/sessoes_planejadas':
          return _rows([]);
        default:
          fail('Unexpected request: ${request.url.path}');
      }
    });
    addTearDown(client.close);
    final planning = PlanningService(
      config: config,
      client: client,
      accessToken: () async => 'access-token',
    );
    final viewModel = DashboardMetricsViewModel(
      QuestionRepository(planning),
      TopicRepository(
        TopicService(
          config: config,
          client: client,
          accessToken: () async => 'access-token',
        ),
      ),
      PlannedSessionRepository(planning),
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();
    expect(viewModel.error, isNull);
    final urgent = {
      for (final item in viewModel.urgentTopics(now))
        item.topic.id: item.reason,
    };
    expect(urgent.keys, containsAll([1, 2, 4, 5]));
    expect(urgent.keys, isNot(contains(3)));
    expect(urgent[1], 'Sem questões registradas');
    expect(urgent[2], 'Ainda não revisado');
    expect(urgent[4], 'Última revisão há mais de 7 dias');
    expect(urgent[5], contains('60% de acerto'));
  });

  test(
    'marking a review writes and reads the dedicated review timestamp',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/rest/v1/topicos');
        expect(request.url.queryParameters['id'], 'eq.3');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.keys, ['ultima_revisao_em']);
        final reviewedAt = DateTime.parse(body['ultima_revisao_em'] as String);
        return _rows([_topic(3, reviewedAt)]);
      });
      addTearDown(client.close);
      final repository = TopicRepository(
        TopicService(
          config: config,
          client: client,
          accessToken: () async => 'access-token',
        ),
      );

      final topic = await repository.markReviewed(3);
      expect(topic.lastReviewedAt, isNotNull);
    },
  );
}

http.Response _rows(List<Map<String, Object?>> rows) => http.Response(
  jsonEncode(rows),
  200,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _topic(int id, DateTime? lastReviewedAt) => {
  'id': id,
  'disciplina_id': 1,
  'nome': 'Tópico $id',
  'ordem': id,
  'teoria_lida': false,
  'resumo_feito': false,
  'exercicios_resolvidos': false,
  'ultima_revisao_em': lastReviewedAt?.toIso8601String(),
};

Map<String, Object?> _record(
  int topicId,
  int total,
  int correct,
  DateTime recordedAt,
) => {
  'id': topicId,
  'disciplina_id': 1,
  'topico_id': topicId,
  'total': total,
  'acertos': correct,
  'erros': total - correct,
  'realizado_em': recordedAt.toIso8601String(),
};
