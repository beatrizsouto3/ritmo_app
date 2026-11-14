import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
import '../pomodoro/pomodoro_view.dart';
import '../study/preferences_view.dart';
import '../study/metrics_view.dart';
import '../study/study_view_model.dart';
import '../flashcards/flashcards_view.dart';
import '../questions/question_records_view.dart';
import '../subjects/subjects_view.dart';
import '../subjects/subjects_view_model.dart';
import 'dashboard_metrics_view_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (context.mounted) {
      await context.read<StudyViewModel>().load();
      if (context.mounted) {
        await context.read<DashboardMetricsViewModel>().load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectsViewModel>();
    final auth = context.watch<AuthViewModel>();
    final colors = Theme.of(context).colorScheme;
    final study = context.watch<StudyViewModel>();
    final metrics = context.watch<DashboardMetricsViewModel>();
    final urgent = metrics.urgentTopics(DateTime.now());
    final today = metrics.sessionsToday(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        title: const Text('Ritmo'),
        actions: [
          IconButton(
            tooltip: 'Editar perfil',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => _open(context, const PreferencesView()),
          ),
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: auth.isBusy ? null : auth.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Text(
                  study.preferences.name.trim().isEmpty
                      ? 'Seu espaço de estudos'
                      : 'Olá, ${study.preferences.name.trim()}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF002B52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Organize sua rotina e continue no seu ritmo.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: const Color(0xFF42474F)),
                ),
                const SizedBox(height: 22),
                if (study.busy) const LinearProgressIndicator(),
                if (study.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(study.error!),
                        TextButton(
                          onPressed: study.load,
                          child: const Text('Tentar carregar preferências'),
                        ),
                      ],
                    ),
                  ),
                if (metrics.busy) const LinearProgressIndicator(),
                if (metrics.error != null)
                  TextButton(
                    onPressed: metrics.load,
                    child: Text(
                      'Dados de questões/cronograma: ${metrics.error} · Tentar novamente',
                    ),
                  ),
                if (!study.preferences.configured)
                  _FeatureTile(
                    icon: Icons.tune_rounded,
                    title: 'Encontre seu ritmo',
                    subtitle: 'Configure sua meta, matérias e horários',
                    onTap: () =>
                        _open(context, const PreferencesView(onboarding: true)),
                  ),
                const SizedBox(height: 16),
                _WelcomeCard(
                  subjectCount: subjects.subjects.length,
                  isLoading: subjects.isLoading,
                  onOpenSubjects: () => _open(context, const SubjectsView()),
                ),
                const SizedBox(height: 20),
                Text(
                  'Continue por aqui',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Disciplinas',
                  subtitle: subjects.isLoading
                      ? 'Carregando suas disciplinas…'
                      : subjects.loadError != null
                      ? 'Não foi possível carregar agora'
                      : '${subjects.subjects.length} cadastrada(s)',
                  onTap: () => _open(context, const SubjectsView()),
                ),
                const SizedBox(height: 10),
                _FeatureTile(
                  icon: Icons.style_rounded,
                  title: 'Flashcards',
                  subtitle: 'Crie baralhos e revise seus cartões',
                  onTap: () => _open(context, const FlashcardsView()),
                ),
                const SizedBox(height: 10),
                _FeatureTile(
                  icon: Icons.timer_outlined,
                  title: 'Pomodoro',
                  subtitle: 'Foco, pausas e tempo líquido por disciplina',
                  onTap: () => _open(context, const PomodoroView()),
                ),
                const SizedBox(height: 10),
                _FeatureTile(
                  icon: Icons.quiz_outlined,
                  title: 'Questões e simulados',
                  subtitle: 'Registre acertos e acompanhe seu aproveitamento',
                  onTap: () => _open(context, const QuestionRecordsView()),
                ),
                const SizedBox(height: 10),
                _FeatureTile(
                  icon: Icons.insights_outlined,
                  title: 'Métricas',
                  subtitle: 'Acompanhe seus ciclos e horas de estudo',
                  onTap: () => _open(context, const MetricsView()),
                ),
                const SizedBox(height: 22),
                Text(
                  'Seu resumo',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.timer_outlined,
                        title: 'Tempo estudado',
                        value: study.loaded
                            ? '${(study.totalSeconds / 3600).toStringAsFixed(1)} h'
                            : 'Indisponível',
                        color: colors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.event_note_rounded,
                        title: 'Meta diária',
                        value: study.loaded
                            ? '${study.preferences.dailyHours} h · ${study.preferences.shift}'
                            : 'Indisponível',
                        color: colors.secondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  icon: Icons.fact_check_outlined,
                  title: 'Acerto em questões',
                  value: !metrics.loaded
                      ? 'Indisponível'
                      : metrics.accuracy == null
                      ? 'Sem questões registradas'
                      : '${(metrics.accuracy! * 100).round()}% · ${metrics.totalQuestions} questões',
                  color: colors.tertiaryContainer,
                ),
                const SizedBox(height: 20),
                Text(
                  'Cronograma de hoje',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (metrics.loaded && today.isEmpty)
                  const Text('Nenhuma sessão planejada para hoje.'),
                for (final session in today)
                  ListTile(
                    onTap: () => _open(
                      context,
                      PomodoroView(initialSubjectId: session.subjectId),
                    ),
                    title: Text(
                      subjects.subjects
                              .where(
                                (subject) => subject.id == session.subjectId,
                              )
                              .map((subject) => subject.name)
                              .firstOrNull ??
                          'Disciplina',
                    ),
                    subtitle: Text(
                      '${TimeOfDay.fromDateTime(session.startsAt.toLocal()).format(context)} – ${TimeOfDay.fromDateTime(session.endsAt.toLocal()).format(context)}',
                    ),
                    trailing: const Icon(Icons.play_arrow_rounded),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Tópicos para revisar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (metrics.loaded && urgent.isEmpty)
                  const Text('Nenhum tópico urgente com questões registradas.'),
                for (final item in urgent.take(5))
                  ListTile(
                    title: Text(item.topic.name),
                    subtitle: Text(item.reason),
                  ),
                if (subjects.loadError != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: subjects.loadSubjects,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar carregar disciplinas novamente'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            label: 'Foco',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: 'Flashcards',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Disciplinas',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Métricas',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == 1) _open(context, const PomodoroView());
          if (index == 2) _open(context, const FlashcardsView());
          if (index == 3) _open(context, const SubjectsView());
          if (index == 4) _open(context, const MetricsView());
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.subjectCount,
    required this.isLoading,
    required this.onOpenSubjects,
  });

  final int subjectCount;
  final bool isLoading;
  final VoidCallback onOpenSubjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002B52), Color(0xFF0A4174)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 14),
          Text(
            isLoading
                ? 'Preparando seu espaço…'
                : subjectCount == 0
                ? 'Vamos começar?'
                : 'Você está construindo constância.',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            isLoading
                ? 'Carregando seus dados.'
                : subjectCount == 0
                ? 'Cadastre uma disciplina para organizar seus estudos.'
                : 'Suas disciplinas já estão prontas para o próximo estudo.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.86)),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: onOpenSubjects,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              subjectCount == 0 ? 'Adicionar disciplina' : 'Ver disciplinas',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6EEFF),
          foregroundColor: const Color(0xFF0A4174),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0A4174)),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
