import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/data/services/study_service.dart';
import 'package:ritmo_app/data/repositories/study_repository.dart';
import 'package:ritmo_app/domain/models/study_preferences.dart';
import 'package:ritmo_app/ui/pomodoro/pomodoro_view_model.dart';
import 'package:ritmo_app/ui/study/study_view_model.dart';

class ControlledStopwatch extends Fake implements Stopwatch {
  int micros = 0;
  bool active = false;
  @override
  int get elapsedMicroseconds => micros;
  @override
  bool get isRunning => active;
  @override
  void start() {
    active = true;
  }

  @override
  void stop() {
    active = false;
  }

  @override
  void reset() {
    micros = 0;
  }
}

void main() {
  const config = SupabaseConfig(
    url: 'https://test.supabase.co',
    publishableKey: 'public-test',
  );
  StudyRepository repository(http.Client client) => StudyRepository(
    StudyService(
      config: config,
      client: client,
      accessToken: () async => 'session-test',
      userId: () => 'user-test',
    ),
  );

  test('preferences upsert belongs to the authenticated user and rejects empty days', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('[]', 201);
    });
    addTearDown(client.close);
    final repo = repository(client);
    await repo.savePreferences(
      const StudyPreferences(name: 'Bia', configured: true),
    );
    final request = requests.single;
    expect(request.headers['authorization'], 'Bearer session-test');
    expect(request.headers['prefer'], contains('resolution=merge-duplicates'));
    expect(jsonDecode(request.body)['usuario_id'], 'user-test');
    expect(
      () => repo.savePreferences(const StudyPreferences(days: [])),
      throwsArgumentError,
    );
    expect(requests.length, 1);
  });

  testWidgets(
    'completed focus retries the same id after failure and starts a break',
    (tester) async {
      final requests = <http.Request>[];
      Map<String, dynamic>? savedSession;
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            request.url.path.endsWith('/sessoes_foco')
                ? jsonEncode([savedSession])
                : '[]',
            200,
          );
        }
        if (savedSession != null) {
          return http.Response(jsonEncode([savedSession]), 201);
        }
        if (requests.where((item) => item.method == 'POST').length == 1) {
          return http.Response('{"message":"unavailable"}', 503);
        }
        savedSession = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode([savedSession]), 201);
      });
      addTearDown(client.close);
      final clock = ControlledStopwatch();
      final study = StudyViewModel(repository(client));
      addTearDown(study.dispose);
      final vm = PomodoroViewModel(
        repository(client),
        const StudyPreferences(focusMinutes: 1),
        stopwatch: clock,
        onSessionSaved: study.recordCompletedSession,
      );
      addTearDown(vm.dispose);
      vm.selectSubject(12);
      vm.toggle();
      clock.micros = 60 * 1000000;
      await tester.pump(const Duration(seconds: 1));
      expect(vm.needsSave, isTrue);
      expect(vm.completedCycles, 0);
      await vm.retrySave();
      expect(requests.length, 2);
      expect(
        jsonDecode(requests[0].body)['id'],
        jsonDecode(requests[1].body)['id'],
      );
      expect(jsonDecode(requests[1].body)['segundos'], 60);
      expect(vm.mode, FocusMode.shortBreak);
      expect(vm.completedCycles, 1);
      expect(vm.sessionSaved, isTrue);
      expect(study.totalSeconds, 60);
      expect(study.secondsBySubject[12], 60);
      expect(vm.remaining, 300);

      final reloadedStudy = StudyViewModel(repository(client));
      addTearDown(reloadedStudy.dispose);
      await reloadedStudy.load();
      expect(reloadedStudy.totalSeconds, 60);
      expect(reloadedStudy.secondsBySubject[12], 60);
    },
  );

  testWidgets('empty save response keeps focus pending until it is confirmed', (
    tester,
  ) async {
    final client = MockClient((_) async => http.Response('[]', 200));
    addTearDown(client.close);
    final clock = ControlledStopwatch();
    final study = StudyViewModel(repository(client));
    addTearDown(study.dispose);
    final vm = PomodoroViewModel(
      repository(client),
      const StudyPreferences(focusMinutes: 1),
      stopwatch: clock,
      onSessionSaved: study.recordCompletedSession,
    );
    addTearDown(vm.dispose);
    vm.selectSubject(12);
    vm.toggle();
    clock.micros = 60 * 1000000;
    await tester.pump(const Duration(seconds: 1));

    expect(vm.needsSave, isTrue);
    expect(vm.sessionSaved, isFalse);
    expect(study.totalSeconds, 0);
    expect(vm.error, contains('confirmar o ciclo salvo'));
  });

  test(
    'a retry succeeds when the cycle already exists on the server',
    () async {
      final requests = <http.Request>[];
      final session = FocusSession(
        id: 'saved-cycle',
        subjectId: 12,
        seconds: 60,
        completedAt: DateTime(2026, 11, 17),
      );
      final client = MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') return http.Response('[]', 201);
        return http.Response(
          jsonEncode([
            {'id': session.id},
          ]),
          200,
        );
      });
      addTearDown(client.close);

      await repository(client).saveSession(session);

      expect(requests.map((request) => request.method), ['POST', 'GET']);
      expect(requests.last.url.queryParameters['id'], 'eq.${session.id}');
    },
  );

  testWidgets(
    'pausing and cancelling do not record focus; break never records study time',
    (tester) async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('[]', 201);
      });
      addTearDown(client.close);
      final clock = ControlledStopwatch();
      final vm = PomodoroViewModel(
        repository(client),
        const StudyPreferences(shortBreak: 1),
        stopwatch: clock,
      );
      addTearDown(vm.dispose);
      vm.selectSubject(1);
      vm.toggle();
      clock.micros = 10 * 1000000;
      vm.toggle();
      expect(vm.remaining, 1490);
      await tester.pump(const Duration(seconds: 20));
      expect(vm.remaining, 1490);
      vm.cancel();
      expect(vm.remaining, 1500);
      vm.selectMode(FocusMode.shortBreak);
      vm.toggle();
      clock.micros = 60 * 1000000;
      await tester.pump(const Duration(seconds: 1));
      expect(vm.mode, FocusMode.focus);
      expect(requests, isEmpty);
    },
  );
}
