import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:ritmo_app/core/config/supabase_config.dart';
import 'package:ritmo_app/core/config/ritmo_theme.dart';
import 'package:ritmo_app/data/services/study_service.dart';
import 'package:ritmo_app/data/services/subject_service.dart';
import 'package:ritmo_app/data/repositories/study_repository.dart';
import 'package:ritmo_app/data/repositories/subject_repository.dart';
import 'package:ritmo_app/ui/study/study_view_model.dart';
import 'package:ritmo_app/ui/study/preferences_view.dart';
import 'package:ritmo_app/ui/pomodoro/pomodoro_view.dart';
import 'package:ritmo_app/ui/subjects/subjects_view_model.dart';

void main() {
  const config = SupabaseConfig(
    url: 'https://test.supabase.co',
    publishableKey: 'public-test',
  );
  testWidgets(
    'small screen onboarding traverses all steps and saves actual choices',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          saved = jsonDecode(request.body) as Map<String, dynamic>;
        }
        return http.Response('[]', 200);
      });
      addTearDown(client.close);
      final repo = StudyRepository(
        StudyService(
          config: config,
          client: client,
          accessToken: () async => 'token',
          userId: () => 'user',
        ),
      );
      final study = StudyViewModel(repo);
      final subjects = SubjectsViewModel(
        SubjectRepository(SubjectService(config: config, client: client)),
      );
      addTearDown(study.dispose);
      addTearDown(subjects.dispose);
      await study.load();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: repo),
            ChangeNotifierProvider.value(value: study),
            ChangeNotifierProvider.value(value: subjects),
          ],
          child: MaterialApp(
            theme: buildRitmoTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PreferencesView(onboarding: true),
                    ),
                  ),
                  child: const Text('Configurar'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Configurar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Bia');
      final next = find.widgetWithText(FilledButton, 'Continuar');
      await tester.scrollUntilVisible(
        next,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('Defina seus horários'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Sáb'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.textContaining('Bia, vamos entrar no ritmo'), findsOneWidget);
      await tester.ensureVisible(find.text('Salvar e continuar'));
      await tester.tap(find.text('Salvar e continuar'));
      await tester.pumpAndSettle();
      expect(saved?['nome'], 'Bia');
      expect(saved?['configurado'], isTrue);
      expect(saved?['dias'], contains(6));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timer fits a narrow screen without bypassing subject selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = MockClient((_) async => http.Response('[]', 200));
      addTearDown(client.close);
      final repo = StudyRepository(
        StudyService(
          config: config,
          client: client,
          accessToken: () async => 'token',
          userId: () => 'user',
        ),
      );
      final study = StudyViewModel(repo);
      final subjects = SubjectsViewModel(
        SubjectRepository(SubjectService(config: config, client: client)),
      );
      addTearDown(study.dispose);
      addTearDown(subjects.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: repo),
            ChangeNotifierProvider.value(value: study),
            ChangeNotifierProvider.value(value: subjects),
          ],
          child: MaterialApp(
            theme: buildRitmoTheme(),
            home: const PomodoroView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Iniciar / retomar'),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('planned subject is selected when Pomodoro opens', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/disciplinas')) {
        return http.Response('[{"id":3,"nome":"Matemática"}]', 200);
      }
      return http.Response('[]', 200);
    });
    addTearDown(client.close);
    final repo = StudyRepository(
      StudyService(
        config: config,
        client: client,
        accessToken: () async => 'token',
        userId: () => 'user',
      ),
    );
    final study = StudyViewModel(repo);
    final subjects = SubjectsViewModel(
      SubjectRepository(SubjectService(config: config, client: client)),
    );
    addTearDown(study.dispose);
    addTearDown(subjects.dispose);
    await subjects.loadSubjects();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: study),
          ChangeNotifierProvider.value(value: subjects),
        ],
        child: MaterialApp(
          theme: buildRitmoTheme(),
          home: const PomodoroView(initialSubjectId: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Matemática'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Iniciar / retomar'),
    );
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
