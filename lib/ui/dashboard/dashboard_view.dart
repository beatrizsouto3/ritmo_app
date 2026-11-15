import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/planned_session.dart';
import '../../domain/models/subject.dart';
import '../auth/auth_view_model.dart';
import '../common/ritmo_logo.dart';
import '../common/main_navigation_bar.dart';
import '../flashcards/flashcards_view.dart';
import '../pomodoro/pomodoro_view.dart';
import '../questions/question_records_view.dart';
import '../study/metrics_view.dart';
import '../study/planned_sessions_view.dart';
import '../study/preferences_view.dart';
import '../study/study_view_model.dart';
import '../subjects/subjects_view.dart';
import '../subjects/subjects_view_model.dart';
import 'dashboard_metrics_view_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  Future<void> _open(BuildContext context, Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (!context.mounted) return;
    await context.read<StudyViewModel>().load();
    if (context.mounted) await context.read<DashboardMetricsViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectsViewModel>();
    final auth = context.watch<AuthViewModel>();
    final study = context.watch<StudyViewModel>();
    final metrics = context.watch<DashboardMetricsViewModel>();
    final now = DateTime.now();
    final urgent = metrics.urgentTopics(now);
    final today = metrics.sessionsToday(now)
      ..sort((first, second) => first.startsAt.compareTo(second.startsAt));
    final nextSession = today
        .where((session) => session.endsAt.isAfter(now))
        .firstOrNull;
    final todaySeconds = study.sessions
        .where((session) {
          final day = session.completedAt.toLocal();
          return day.year == now.year &&
              day.month == now.month &&
              day.day == now.day;
        })
        .fold<int>(0, (total, session) => total + session.seconds);
    final goalSeconds = study.preferences.dailyHours * 3600;
    final progress = goalSeconds == 0
        ? 0.0
        : (todaySeconds / goalSeconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            RitmoLogo(size: 38),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ritmo',
                  style: TextStyle(fontWeight: FontWeight.w700, height: 1.1),
                ),
                Text(
                  'Início',
                  style: TextStyle(fontSize: 12, color: Color(0xFF33628A)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Editar perfil',
            icon: const Icon(Icons.account_circle_rounded, size: 32),
            onPressed: () => _open(context, const PreferencesView()),
          ),
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (value) {
              if (value == 'logout' && !auth.isBusy) auth.signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Sair da conta')),
            ],
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Text(
                  study.preferences.name.trim().isEmpty
                      ? 'Seu espaço de estudos 🎯'
                      : 'Olá, ${study.preferences.name.trim()}! 🎯',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF002B52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A consistência diária constrói grandes resultados.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF42474F)),
                ),
                const SizedBox(height: 24),
                if (study.busy || metrics.busy) const LinearProgressIndicator(),
                if (study.error != null)
                  _ErrorPanel(message: study.error!, onRetry: study.load),
                if (metrics.error != null)
                  _ErrorPanel(message: metrics.error!, onRetry: metrics.load),
                _FocusCard(
                  studiedSeconds: todaySeconds,
                  goalSeconds: goalSeconds,
                  progress: progress,
                  questions: metrics.loaded ? '${metrics.totalQuestions}' : '—',
                  accuracy: metrics.accuracy == null
                      ? '—'
                      : '${(metrics.accuracy! * 100).round()}%',
                  cycles:
                      '${study.sessions.where((session) {
                        final day = session.completedAt.toLocal();
                        return day.year == now.year && day.month == now.month && day.day == now.day;
                      }).length}',
                ),
                const SizedBox(height: 26),
                _SectionHeading(
                  title: 'PRÓXIMO BLOCO DE IMERSÃO',
                  trailing: TextButton(
                    onPressed: () =>
                        _open(context, const PlannedSessionsView()),
                    child: const Text('Ver agenda'),
                  ),
                ),
                const SizedBox(height: 8),
                _NextSessionCard(
                  session: nextSession,
                  subject: nextSession == null
                      ? null
                      : subjects.subjects
                            .where((item) => item.id == nextSession.subjectId)
                            .firstOrNull,
                  focusMinutes: study.preferences.focusMinutes,
                  onStart: () => _open(
                    context,
                    PomodoroView(
                      initialSubjectId: nextSession?.subjectId,
                      showNavigation: true,
                    ),
                  ),
                  onPlan: () => _open(context, const PlannedSessionsView()),
                ),
                const SizedBox(height: 26),
                _SectionHeading(
                  title: 'Revisão crítica & SRS',
                  icon: Icons.notifications_active_outlined,
                  count: metrics.loaded ? '${urgent.length} pendente(s)' : null,
                ),
                const SizedBox(height: 10),
                if (metrics.loaded && urgent.isEmpty)
                  const _EmptyPanel(
                    message: 'Nenhum tópico urgente no momento.',
                  ),
                for (final item in urgent.take(3))
                  _ReviewCard(
                    subject:
                        subjects.subjects
                            .where(
                              (subject) => subject.id == item.topic.subjectId,
                            )
                            .map((subject) => subject.name)
                            .firstOrNull ??
                        'Disciplina',
                    topic: item.topic.name,
                    reason: item.reason,
                    onOpen: () => _open(
                      context,
                      const SubjectsView(showNavigation: true),
                    ),
                  ),
                if (urgent.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _open(
                        context,
                        const SubjectsView(showNavigation: true),
                      ),
                      child: const Text('Ver disciplinas'),
                    ),
                  ),
                const SizedBox(height: 20),
                _SectionHeading(
                  title: 'Cronograma de hoje',
                  icon: Icons.calendar_today_outlined,
                  trailing: TextButton(
                    onPressed: () =>
                        _open(context, const PlannedSessionsView()),
                    child: const Text('Planejar'),
                  ),
                ),
                const SizedBox(height: 8),
                if (metrics.loaded && today.isEmpty)
                  const _EmptyPanel(
                    message: 'Nenhuma sessão planejada para hoje.',
                  ),
                if (today.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: _panelDecoration(),
                    child: Column(
                      children: [
                        for (final session in today)
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFDCE9FF),
                              child: Icon(
                                Icons.schedule_rounded,
                                color: Color(0xFF0A4174),
                              ),
                            ),
                            title: Text(
                              subjects.subjects
                                      .where(
                                        (item) => item.id == session.subjectId,
                                      )
                                      .map((item) => item.name)
                                      .firstOrNull ??
                                  'Disciplina',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${TimeOfDay.fromDateTime(session.startsAt.toLocal()).format(context)} – ${TimeOfDay.fromDateTime(session.endsAt.toLocal()).format(context)}',
                            ),
                            trailing: const Icon(Icons.play_arrow_rounded),
                            onTap: () => _open(
                              context,
                              PomodoroView(
                                initialSubjectId: session.subjectId,
                                showNavigation: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 26),
                Text(
                  'Continue por aqui',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                _FeatureTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Disciplinas',
                  subtitle: subjects.isLoading
                      ? 'Carregando disciplinas…'
                      : '${subjects.subjects.length} cadastrada(s)',
                  onTap: () =>
                      _open(context, const SubjectsView(showNavigation: true)),
                ),
                _FeatureTile(
                  icon: Icons.style_rounded,
                  title: 'Flashcards',
                  subtitle: 'Crie baralhos e revise seus cartões',
                  onTap: () => _open(
                    context,
                    const FlashcardsView(showNavigation: true),
                  ),
                ),
                _FeatureTile(
                  icon: Icons.quiz_outlined,
                  title: 'Questões e simulados',
                  subtitle: 'Registre acertos e acompanhe seu aproveitamento',
                  onTap: () => _open(context, const QuestionRecordsView()),
                ),
                _FeatureTile(
                  icon: Icons.insights_outlined,
                  title: 'Métricas',
                  subtitle: 'Acompanhe seus ciclos e horas de estudo',
                  onTap: () =>
                      _open(context, const MetricsView(showNavigation: true)),
                ),
                if (subjects.loadError != null)
                  TextButton.icon(
                    onPressed: subjects.loadSubjects,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar carregar disciplinas novamente'),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MainNavigationBar(
        selectedIndex: 0,
        onSelected: (index) {
          if (index == 1) {
            _open(context, const PomodoroView(showNavigation: true));
          }
          if (index == 2) {
            _open(context, const FlashcardsView(showNavigation: true));
          }
          if (index == 3) {
            _open(context, const SubjectsView(showNavigation: true));
          }
          if (index == 4) {
            _open(context, const MetricsView(showNavigation: true));
          }
        },
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

BoxDecoration _panelDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  boxShadow: const [
    BoxShadow(color: Color(0x12001D39), blurRadius: 18, offset: Offset(0, 5)),
  ],
);

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.studiedSeconds,
    required this.goalSeconds,
    required this.progress,
    required this.questions,
    required this.accuracy,
    required this.cycles,
  });

  final int studiedSeconds;
  final int goalSeconds;
  final double progress;
  final String questions;
  final String accuracy;
  final String cycles;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF002B52), Color(0xFF0A4174), Color(0xFF001C38)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x38002B52),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'META DE FOCO DIÁRIO',
          style: TextStyle(
            color: Color(0xFFCEE5FF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 5,
          children: [
            Text(
              _formatDuration(studiedSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '/ ${_formatDuration(goalSeconds)}',
                style: const TextStyle(color: Color(0xFFCEE5FF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0x44FFFFFF),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFA4D0FE)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).round()}% concluído hoje',
              style: const TextStyle(color: Color(0xFFCEE5FF), fontSize: 11),
            ),
            Text(
              progress >= 1
                  ? 'Meta concluída'
                  : 'Resta ${_formatDuration((goalSeconds - studiedSeconds).clamp(0, goalSeconds))}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _FocusStat(label: 'Questões', value: questions),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FocusStat(label: 'Precisão', value: accuracy),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _FocusStat(label: 'Ciclos hoje', value: cycles),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FocusStat extends StatelessWidget {
  const _FocusStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0x22FFFFFF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFCEE5FF), fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.icon,
    this.count,
    this.trailing,
  });
  final String title;
  final IconData? icon;
  final String? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, color: const Color(0xFF0A4174), size: 20),
        const SizedBox(width: 7),
      ],
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            color: icon == null
                ? const Color(0xFF33628A)
                : const Color(0xFF001C38),
            fontSize: icon == null ? 12 : 18,
            fontWeight: FontWeight.w700,
            letterSpacing: icon == null ? 0.5 : 0,
          ),
        ),
      ),
      if (count != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count!,
            style: const TextStyle(
              color: Color(0xFF93000A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ?trailing,
    ],
  );
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.session,
    required this.subject,
    required this.focusMinutes,
    required this.onStart,
    required this.onPlan,
  });
  final PlannedSession? session;
  final Subject? subject;
  final int focusMinutes;
  final VoidCallback onStart;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _panelDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFE6EEFF),
              child: Icon(Icons.menu_book_rounded, color: Color(0xFF0A4174)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject?.name ??
                        (session == null ? 'Foco livre' : 'Disciplina'),
                    style: const TextStyle(
                      color: Color(0xFF0A4174),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    session?.notes?.trim().isNotEmpty == true
                        ? session!.notes!.trim()
                        : 'Pronto para seu próximo ciclo?',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (session != null)
                    Text(
                      TimeOfDay.fromDateTime(session!.startsAt.toLocal())
                          .format(context),
                      style: const TextStyle(
                        color: Color(0xFF42474F),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Iniciar ciclo ($focusMinutes min)'),
        ),
        if (session == null)
          TextButton(
            onPressed: onPlan,
            child: const Text('Planejar uma sessão'),
          ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.subject,
    required this.topic,
    required this.reason,
    required this.onOpen,
  });
  final String subject;
  final String topic;
  final String reason;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: _panelDecoration(),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: const TextStyle(
              color: Color(0xFF33628A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            topic,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Text(reason, style: const TextStyle(color: Color(0xFF42474F))),
      ),
      trailing: const Icon(
        Icons.arrow_forward_rounded,
        color: Color(0xFF0A4174),
      ),
      onTap: onOpen,
    ),
  );
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: _panelDecoration(),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE6EEFF),
        child: Icon(icon, color: const Color(0xFF0A4174)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _panelDecoration(),
    child: Text(message, style: const TextStyle(color: Color(0xFF42474F))),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: const Color(0xFFFFDAD6),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        title: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      ),
    ),
  );
}
