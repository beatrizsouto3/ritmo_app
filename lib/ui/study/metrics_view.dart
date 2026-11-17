import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/question_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../../data/repositories/subject_repository.dart';
import '../common/study_layout.dart';
import '../common/main_navigation_bar.dart';
import 'metrics_view_model.dart';

class MetricsView extends StatelessWidget {
  const MetricsView({super.key, this.showNavigation = false});

  final bool showNavigation;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => MetricsViewModel(
      context.read<StudyRepository>(),
      context.read<SubjectRepository>(),
      context.read<QuestionRepository>(),
    )..load(),
    child: _MetricsScreen(showNavigation: showNavigation),
  );
}

class _MetricsScreen extends StatelessWidget {
  const _MetricsScreen({required this.showNavigation});
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MetricsViewModel>();
    final dailyAccuracy = vm.dailyAccuracy(DateTime.now());
    return StudyLayout(
      title: 'Métricas de estudo',
      bottomNavigationBar: showNavigation
          ? MainNavigationBar(
              selectedIndex: 4,
              onSelected: (index) {
                if (index != 4) openMainDestination(context, index);
              },
            )
          : null,
      children: [
        if (vm.busy) const LinearProgressIndicator(),
        if (vm.error != null) ...[
          Text(vm.error!),
          TextButton(onPressed: vm.load, child: const Text('Tentar novamente')),
        ],
        StudyPanel(
          dark: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HORAS LÍQUIDAS',
                style: TextStyle(
                  color: Color(0xFFA4D0FE),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                vm.totalDurationLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${vm.sessionCount} ciclo(s) de foco concluído(s)',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        StudyPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tempo por disciplina',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (vm.subjectDurations.isEmpty)
                const Text(
                  'Conclua seu primeiro foco para acompanhar o progresso.',
                ),
              for (final subject in vm.subjectDurations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(subject.label),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: subject.progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        StudyPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desempenho em questões',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(vm.questionSummary),
              const SizedBox(height: 16),
              Text(
                'Evolução nos últimos 30 dias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (vm.loaded && dailyAccuracy.isEmpty)
                const Text('Nenhuma questão registrada nesse período.'),
              for (final day in dailyAccuracy)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(day.label),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: day.accuracy,
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Últimos lançamentos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final record in vm.recentQuestions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(record.title),
                  subtitle: Text(record.subtitle),
                ),
            ],
          ),
        ),
        Text(
          'Sessões concluídas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final session in vm.recentSessions)
          StudyPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: Text(session.title),
              subtitle: Text(session.subtitle),
              trailing: Text(session.trailing!),
            ),
          ),
      ],
    );
  }
}
