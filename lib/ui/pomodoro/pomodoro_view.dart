import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/study_repository.dart';
import '../common/main_navigation_bar.dart';
import '../common/study_layout.dart';
import '../study/preferences_view.dart';
import '../subjects/subjects_view_model.dart';
import 'focus_progress_ring.dart';
import 'pomodoro_view_model.dart';

class PomodoroView extends StatelessWidget {
  const PomodoroView({
    super.key,
    this.initialSubjectId,
    this.showNavigation = false,
  });

  final int? initialSubjectId;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => PomodoroViewModel(
      context.read<StudyRepository>(),
      context.read<StudyRepository>().currentPreferences,
      initialSubjectId: initialSubjectId,
    ),
    child: _TimerScreen(showNavigation: showNavigation),
  );
}

class _TimerScreen extends StatelessWidget {
  const _TimerScreen({required this.showNavigation});

  final bool showNavigation;
  Future<void> _editPreferences(
    BuildContext context,
    PomodoroViewModel vm,
  ) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PreferencesView()));
    if (context.mounted) {
      vm.updatePreferences(context.read<StudyRepository>().currentPreferences);
    }
  }

  Future<bool> _confirm(BuildContext context, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Encerrar sessão?'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Encerrar'),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PomodoroViewModel>();
    final subjects = context.watch<SubjectsViewModel>();
    final selectedSubjectId =
        subjects.subjects.any((subject) => subject.id == vm.subjectId)
        ? vm.subjectId
        : null;
    return PopScope(
      canPop: !vm.hasStarted && !vm.saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || vm.saving) return;
        final close = await _confirm(
          context,
          vm.needsSave
              ? 'O ciclo concluído ainda não foi salvo. Sair descarta a tentativa pendente.'
              : 'Ao sair, o ciclo em andamento será descartado. Pausas e ciclos cancelados não contam como estudo.',
        );
        if (close && context.mounted) {
          vm.cancel();
          Navigator.of(context).pop();
        }
      },
      child: StudyLayout(
        title: 'Pomodoro · Foco',
        bottomNavigationBar: showNavigation
            ? MainNavigationBar(
                selectedIndex: 1,
                onSelected: (index) async {
                  if (index == 1 || vm.saving) return;
                  if (vm.hasStarted) {
                    final close = await _confirm(
                      context,
                      vm.needsSave
                          ? 'O ciclo concluído ainda não foi salvo. Sair descarta a tentativa pendente.'
                          : 'Ao sair, o ciclo em andamento será descartado. Pausas e ciclos cancelados não contam como estudo.',
                    );
                    if (!close || !context.mounted) return;
                    vm.cancel();
                    await WidgetsBinding.instance.endOfFrame;
                    if (!context.mounted) return;
                  }
                  openMainDestination(context, index);
                },
              )
            : null,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in FocusMode.values)
                ChoiceChip(
                  label: Text(switch (mode) {
                    FocusMode.focus => 'Foco',
                    FocusMode.shortBreak => 'Pausa curta',
                    FocusMode.longBreak => 'Pausa longa',
                  }),
                  selected: vm.mode == mode,
                  onSelected: vm.hasStarted || vm.saving
                      ? null
                      : (_) => vm.selectMode(mode),
                ),
            ],
          ),
          if (vm.mode != FocusMode.focus) ...[
            const SizedBox(height: 8),
            const Text(
              'Pausas não somam tempo de estudo. Selecione Foco para registrar o tempo ao concluir o ciclo.',
            ),
          ],
          const SizedBox(height: 16),
          StudyPanel(
            child: DropdownButtonFormField<int>(
              key: ValueKey(selectedSubjectId),
              initialValue: selectedSubjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Disciplina vinculada',
                border: InputBorder.none,
              ),
              items: [
                for (final subject in subjects.subjects)
                  DropdownMenuItem(
                    value: subject.id,
                    child: Text(subject.name),
                  ),
              ],
              onChanged: vm.hasStarted || vm.saving ? null : vm.selectSubject,
            ),
          ),
          if (subjects.loadError != null)
            TextButton(
              onPressed: subjects.loadSubjects,
              child: const Text('Tentar carregar disciplinas'),
            ),
          if (!subjects.isLoading && subjects.subjects.isEmpty)
            const Text('Cadastre uma disciplina para iniciar o foco.'),
          if (!subjects.isLoading &&
              vm.subjectId != null &&
              selectedSubjectId == null)
            const Text(
              'A disciplina planejada não está disponível. Escolha outra para iniciar.',
            ),
          StudyPanel(
            child: Column(
              children: [
                const SizedBox(height: 16),
                SizedBox.square(
                  dimension: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FocusProgressRing(remainingFraction: 1 - vm.progress),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6EEFF),
                              borderRadius: BorderRadius.all(
                                Radius.circular(99),
                              ),
                            ),
                            child: Text(
                              vm.label.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF0A4174),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Text(
                            vm.clock,
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF002B52),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text('${vm.completedCycles} ciclo(s) concluído(s)'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (vm.saving) const LinearProgressIndicator(),
                if (vm.sessionSaved)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Ciclo salvo! O tempo já entrou nas métricas da disciplina.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0A4174),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Cancelar ciclo',
                      icon: const Icon(Icons.replay_rounded),
                      onPressed: vm.saving || !vm.hasStarted
                          ? null
                          : () async {
                              if (await _confirm(
                                context,
                                'Descartar este ciclo? Apenas focos concluídos e salvos entram nas métricas.',
                              )) {
                                vm.cancel();
                              }
                            },
                    ),
                    FilledButton.icon(
                      onPressed:
                          vm.saving ||
                              vm.needsSave ||
                              (vm.mode == FocusMode.focus &&
                                  selectedSubjectId == null)
                          ? null
                          : vm.toggle,
                      icon: Icon(
                        vm.running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(vm.running ? 'Pausar' : 'Iniciar / retomar'),
                    ),
                  ],
                ),
                if (vm.mode != FocusMode.focus && !vm.needsSave)
                  TextButton(
                    onPressed: vm.saving ? null : vm.skipBreak,
                    child: const Text('Pular pausa'),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'O tempo entra nas métricas ao concluir e salvar o foco. Pausas não contam. O timer continua ao bloquear a tela.',
                  textAlign: TextAlign.center,
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (vm.needsSave)
                  TextButton(
                    onPressed: vm.saving ? null : vm.retrySave,
                    child: const Text('Tentar salvar o ciclo novamente'),
                  ),
              ],
            ),
          ),
          StudyPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Foco: ${vm.preferences.focusMinutes} min · pausa curta: ${vm.preferences.shortBreak} min · pausa longa: ${vm.preferences.longBreak} min.\nA pausa longa é oferecida a cada 4 ciclos.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: vm.hasStarted || vm.saving
                      ? null
                      : () => _editPreferences(context, vm),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Editar tempos do Pomodoro'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
