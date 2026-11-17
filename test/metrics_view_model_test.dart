import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/repositories/question_repository.dart';
import 'package:ritmo_app/data/repositories/study_repository.dart';
import 'package:ritmo_app/data/repositories/subject_repository.dart';
import 'package:ritmo_app/data/services/planning_service.dart';
import 'package:ritmo_app/data/services/study_service.dart';
import 'package:ritmo_app/data/services/subject_service.dart';
import 'package:ritmo_app/ui/study/metrics_view_model.dart';

void main() {
  test(
    'metrics view model prepares study and question data for the view',
    () async {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        publishableKey: 'public-key',
      );
      final now = DateTime.now();
      final client = MockClient((request) async {
        final rows = switch (request.url.path) {
          '/rest/v1/sessoes_foco' => [
            {
              'id': 'focus-1',
              'disciplina_id': 2,
              'segundos': 5400,
              'concluido_em': now.toUtc().toIso8601String(),
            },
          ],
          '/rest/v1/disciplinas' => [
            {'id': 2, 'nome': 'Matemática'},
          ],
          '/rest/v1/registros_questoes' => [
            {
              'id': 1,
              'disciplina_id': 2,
              'topico_id': null,
              'total': 10,
              'acertos': 8,
              'erros': 2,
              'realizado_em': now.toUtc().toIso8601String(),
            },
          ],
          _ => throw StateError('Unexpected request: ${request.url.path}'),
        };
        return http.Response(
          jsonEncode(rows),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final study = StudyRepository(
        StudyService(
          config: config,
          client: client,
          accessToken: () async => 'token',
          userId: () => 'user',
        ),
      );
      final subjects = SubjectRepository(
        SubjectService(
          config: config,
          client: client,
          accessToken: () async => 'token',
        ),
      );
      final questions = QuestionRepository(
        PlanningService(
          config: config,
          client: client,
          accessToken: () async => 'token',
        ),
      );
      final vm = MetricsViewModel(study, subjects, questions);
      addTearDown(vm.dispose);
      addTearDown(study.dispose);
      addTearDown(subjects.dispose);
      addTearDown(questions.dispose);

      await vm.load();
      expect(vm.error, isNull);
      expect(vm.totalDurationLabel, '1h 30min');
      expect(vm.sessionCount, 1);
      expect(vm.subjectDurations.single.label, 'Matemática · 90 min');
      expect(vm.subjectDurations.single.progress, 1);
      expect(vm.questionSummary, '80% de acerto em 10 questões.');
      expect(vm.dailyAccuracy(now).single.accuracy, 0.8);
      expect(vm.recentSessions.single.title, 'Matemática');
    },
  );
}
