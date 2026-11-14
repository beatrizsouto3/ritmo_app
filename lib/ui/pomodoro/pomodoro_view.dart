import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/study_repository.dart';
import '../common/study_layout.dart';
import '../study/study_view_model.dart';
import '../subjects/subjects_view_model.dart';
import 'pomodoro_view_model.dart';

class PomodoroView extends StatelessWidget {
  const PomodoroView({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => PomodoroViewModel(
      context.read<StudyRepository>(),
      context.read<StudyViewModel>().preferences,
    ),
    child: const _TimerScreen(),
  );
}

class _TimerScreen extends StatelessWidget {
  const _TimerScreen();
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
          const SizedBox(height: 16),
          StudyPanel(
            child: DropdownButtonFormField<int>(
              initialValue: vm.subjectId,
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
          StudyPanel(
            child: Column(
              children: [
                const SizedBox(height: 16),
                SizedBox.square(
                  dimension: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 228,
                        child: CircularProgressIndicator(
                          value: 1 - vm.progress,
                          strokeWidth: 10,
                          backgroundColor: const Color(0xFFE6EEFF),
                          color: const Color(0xFF0A4174),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vm.label.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            vm.clock,
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF002B52),
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
                                  vm.subjectId == null)
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
                const SizedBox(height: 16),
                const Text(
                  'O timer continua ao bloquear a tela. Ao fechar o aplicativo, o ciclo incompleto é descartado.',
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
            child: Text(
              'Foco: ${vm.preferences.focusMinutes} min · pausa curta: ${vm.preferences.shortBreak} min · pausa longa: ${vm.preferences.longBreak} min.\nA pausa longa é oferecida a cada 4 ciclos. Configure as durações no perfil.',
            ),
          ),
        ],
      ),
    );
  }
}
