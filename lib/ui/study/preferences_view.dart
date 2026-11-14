import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/study_layout.dart';
import '../subjects/subjects_view.dart';
import '../subjects/subjects_view_model.dart';
import 'preferences_view_model.dart';
import 'study_view_model.dart';

const _goals = [
  'Universidade',
  'Residência Médica',
  'Concursos Públicos',
  'ENEM / Vestibulares',
  'OAB & Jurídico',
];
const _days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

class PreferencesView extends StatelessWidget {
  const PreferencesView({super.key, this.onboarding = false});
  final bool onboarding;
  @override
  Widget build(BuildContext context) {
    final source = context.watch<StudyViewModel>();
    if (!source.loaded) {
      return StudyLayout(
        title: onboarding ? 'Configurar estudos' : 'Editar perfil',
        children: [
          if (source.busy) const LinearProgressIndicator(),
          Text(source.error ?? 'Carregando suas preferências…'),
          if (!source.busy)
            TextButton(
              onPressed: source.load,
              child: const Text('Tentar novamente'),
            ),
        ],
      );
    }
    return ChangeNotifierProvider(
      create: (context) => PreferencesViewModel(context.read<StudyViewModel>()),
      child: _PreferencesScreen(onboarding: onboarding),
    );
  }
}

class _PreferencesScreen extends StatefulWidget {
  const _PreferencesScreen({required this.onboarding});
  final bool onboarding;
  @override
  State<_PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<_PreferencesScreen> {
  final _form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PreferencesViewModel>();
    final subjects = context.watch<SubjectsViewModel>();
    final draft = vm.draft;
    final first = !widget.onboarding || vm.step == 0;
    final routine = !widget.onboarding || vm.step == 1;
    final summary = widget.onboarding && vm.step == 2;
    return PopScope(
      canPop: !vm.saving,
      child: StudyLayout(
        title: widget.onboarding
            ? [
                'Encontre seu ritmo',
                'Defina seus horários',
                'Tudo pronto para começar',
              ][vm.step]
            : 'Editar perfil',
        children: [
          if (widget.onboarding) ...[
            LinearProgressIndicator(value: (vm.step + 1) / 3),
            const SizedBox(height: 18),
            Text(
              'Passo ${vm.step + 1} de 3',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
          ],
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (first) ...[
                  StudyPanel(
                    dark: true,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFA4D0FE),
                          child: Icon(Icons.person_outline),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.onboarding
                                ? 'Seu plano começa com você'
                                : 'Seu perfil de estudos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StudyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          initialValue: draft.name,
                          enabled: !vm.saving,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Como você quer ser chamado(a)?',
                          ),
                          onChanged: (value) =>
                              vm.change(vm.draft.copyWith(name: value)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Foco principal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final goal in _goals)
                              ChoiceChip(
                                label: Text(goal),
                                selected: draft.goal == goal,
                                onSelected: vm.saving
                                    ? null
                                    : (_) =>
                                          vm.change(draft.copyWith(goal: goal)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _number(
                          'Meta diária de estudo (horas)',
                          draft.dailyHours,
                          1,
                          12,
                          vm.saving,
                          (n) => vm.change(draft.copyWith(dailyHours: n)),
                        ),
                        _number(
                          'Bloco de foco (minutos)',
                          draft.focusMinutes,
                          1,
                          120,
                          vm.saving,
                          (n) => vm.change(draft.copyWith(focusMinutes: n)),
                        ),
                        _number(
                          'Pausa curta (minutos)',
                          draft.shortBreak,
                          1,
                          60,
                          vm.saving,
                          (n) => vm.change(draft.copyWith(shortBreak: n)),
                        ),
                        _number(
                          'Pausa longa (minutos)',
                          draft.longBreak,
                          1,
                          60,
                          vm.saving,
                          (n) => vm.change(draft.copyWith(longBreak: n)),
                        ),
                      ],
                    ),
                  ),
                  StudyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Matérias do ciclo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          subjects.subjects.isEmpty
                              ? 'Adicione suas primeiras disciplinas.'
                              : subjects.subjects
                                    .map((s) => s.name)
                                    .join(' · '),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: vm.saving
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SubjectsView(),
                                  ),
                                ),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Gerenciar disciplinas'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (routine)
                  StudyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Dias de estudo ativo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          children: [
                            for (var index = 0; index < 7; index++)
                              FilterChip(
                                label: Text(_days[index]),
                                selected: draft.days.contains(index + 1),
                                onSelected: vm.saving
                                    ? null
                                    : (selected) {
                                        final days = [...draft.days];
                                        selected
                                            ? days.add(index + 1)
                                            : days.remove(index + 1);
                                        days.sort();
                                        vm.change(draft.copyWith(days: days));
                                      },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: draft.shift,
                          decoration: const InputDecoration(
                            labelText: 'Melhor turno para estudar',
                          ),
                          items: [
                            for (final shift in ['Manhã', 'Tarde', 'Noite'])
                              DropdownMenuItem(
                                value: shift,
                                child: Text(shift),
                              ),
                          ],
                          onChanged: vm.saving
                              ? null
                              : (v) => vm.change(draft.copyWith(shift: v)),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Estes horários organizam sua rotina de estudo. Alertas do sistema ainda não estão disponíveis.',
                        ),
                      ],
                    ),
                  ),
                if (summary)
                  StudyPanel(
                    dark: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFFA4D0FE),
                          size: 54,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          draft.name.trim().isEmpty
                              ? 'Vamos entrar no ritmo!'
                              : '${draft.name.trim()}, vamos entrar no ritmo!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${draft.goal}\n${draft.dailyHours}h de estudo por dia · ${draft.shift}\n${draft.days.map((d) => _days[d - 1]).join(' · ')}\nFoco de ${draft.focusMinutes} min\n${subjects.subjects.length} disciplina(s) no ciclo',
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton.icon(
            onPressed: vm.saving
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    if (routine && draft.days.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Escolha pelo menos um dia de estudo.'),
                        ),
                      );
                      return;
                    }
                    if (widget.onboarding && vm.step < 2) {
                      vm.go(vm.step + 1);
                      return;
                    }
                    final saved = await vm.save(complete: widget.onboarding);
                    if (saved && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferências salvas.')),
                      );
                    }
                  },
            icon: Icon(
              summary ? Icons.check_rounded : Icons.arrow_forward_rounded,
            ),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                vm.saving
                    ? 'Salvando…'
                    : widget.onboarding && !summary
                    ? 'Continuar'
                    : 'Salvar e continuar',
              ),
            ),
          ),
          if (widget.onboarding && vm.step > 0)
            TextButton(
              onPressed: vm.saving ? null : () => vm.go(vm.step - 1),
              child: const Text('Voltar'),
            ),
        ],
      ),
    );
  }

  Widget _number(
    String label,
    int value,
    int min,
    int max,
    bool busy,
    ValueChanged<int> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var n = min; n <= max; n++)
          DropdownMenuItem(value: n, child: Text('$n')),
      ],
      onChanged: busy
          ? null
          : (n) {
              if (n != null) onChanged(n);
            },
    ),
  );
}
