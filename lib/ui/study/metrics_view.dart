import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/study_layout.dart';
import '../subjects/subjects_view_model.dart';
import 'study_view_model.dart';
import '../dashboard/dashboard_metrics_view_model.dart';

class MetricsView extends StatelessWidget {
  const MetricsView({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudyViewModel>();
    final subjects = context.watch<SubjectsViewModel>().subjects;
    final totals = vm.secondsBySubject;
    final dashboard = context.watch<DashboardMetricsViewModel>();
    final dailyAccuracy = dashboard.dailyAccuracy(DateTime.now());
    final maximum = totals.values.fold<int>(1, (max, n) => n > max ? n : max);
    return StudyLayout(
      title: 'Métricas de estudo',
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
                '${(vm.totalSeconds / 3600).toStringAsFixed(1)} h',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${vm.sessions.length} ciclo(s) de foco concluído(s)',
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
              if (totals.isEmpty)
                const Text(
                  'Conclua seu primeiro foco para acompanhar o progresso.',
                ),
              for (final subject in subjects.where(
                (subject) => totals.containsKey(subject.id),
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${subject.name} · ${(totals[subject.id]! / 60).round()} min',
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: totals[subject.id]! / maximum,
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
              Text(
                dashboard.accuracy == null
                    ? 'Ainda não há questões registradas.'
                    : '${(dashboard.accuracy! * 100).round()}% de acerto em ${dashboard.totalQuestions} questões.',
              ),
              const SizedBox(height: 16),
              Text(
                'Evolução nos últimos 30 dias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (dashboard.busy) const LinearProgressIndicator(),
              if (dashboard.error != null)
                TextButton(
                  onPressed: dashboard.load,
                  child: const Text(
                    'Não foi possível carregar as questões. Tentar novamente',
                  ),
                ),
              if (dashboard.loaded && dailyAccuracy.isEmpty)
                const Text('Nenhuma questão registrada nesse período.'),
              for (final day in dailyAccuracy)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${day.day.day.toString().padLeft(2, '0')}/${day.day.month.toString().padLeft(2, '0')} · ${day.correct}/${day.total} acertos · ${(day.accuracy * 100).round()}%',
                      ),
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
              for (final record in dashboard.records.take(10))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${record.correct}/${record.total} acertos · ${(record.accuracy * 100).round()}%',
                  ),
                  subtitle: Text(
                    record.recordedAt.toLocal().toString().substring(0, 16),
                  ),
                ),
            ],
          ),
        ),
        Text(
          'Sessões concluídas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final session in vm.sessions.take(20))
          StudyPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: Text(
                subjects
                        .where((s) => s.id == session.subjectId)
                        .map((s) => s.name)
                        .firstOrNull ??
                    'Disciplina',
              ),
              subtitle: Text(
                session.completedAt.toLocal().toString().substring(0, 16),
              ),
              trailing: Text('${session.seconds ~/ 60} min'),
            ),
          ),
      ],
    );
  }
}
