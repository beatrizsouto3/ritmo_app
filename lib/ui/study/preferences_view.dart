import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
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
        actions: widget.onboarding && !Navigator.of(context).canPop()
            ? [
                IconButton(
                  tooltip: 'Sair da conta',
                  onPressed: () => context.read<AuthViewModel>().signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ]
            : null,
        children: [
          if (widget.onboarding) ...[
            Row(
              children: [
                Text(
                  'PASSO ${vm.step + 1} DE 3',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF002B52),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      'Matérias & Metas',
                      'Rotina & Horários',
                      'Seu plano',
                    ][vm.step],
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: const Color(0xFF33628A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (vm.step + 1) / 3),
            const SizedBox(height: 22),
          ],
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (first) ...[
                  StudyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF002B52),
                          foregroundColor: Colors.white,
                          child: Icon(Icons.tune_rounded),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.onboarding
                              ? 'Monte seu Ritmo'
                              : 'Seu perfil de estudos',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.onboarding
                              ? 'Personalize sua meta, suas matérias e seus blocos de foco.'
                              : 'Ajuste suas metas e sua rotina de estudo.',
                        ),
                      ],
                    ),
                  ),
                  _sectionHeading(
                    context,
                    Icons.flag_outlined,
                    '1. Foco principal',
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
                      ],
                    ),
                  ),
                  StudyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeading(
                          context,
                          Icons.library_books_outlined,
                          '2. Matérias do ciclo',
                        ),
                        const SizedBox(height: 8),
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
                  _sectionHeading(
                    context,
                    Icons.timelapse_rounded,
                    '3. Carga e foco',
                  ),
                  StudyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Meta de estudo diário',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final hours in [2, 4, 6])
                              ChoiceChip(
                                label: Text('$hours h'),
                                selected: draft.dailyHours == hours,
                                onSelected: vm.saving
                                    ? null
                                    : (_) => vm.change(
                                        draft.copyWith(dailyHours: hours),
                                      ),
                              ),
                          ],
                        ),
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
                ],
                if (routine) ...[
                  Text(
                    'Defina seus horários',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Escolha os dias e o turno em que prefere estudar.',
                  ),
                  const SizedBox(height: 20),
                  StudyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeading(
                          context,
                          Icons.calendar_month_outlined,
                          '1. Dias de estudo ativo',
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
                        _sectionHeading(
                          context,
                          Icons.wb_sunny_outlined,
                          '2. Melhor turno para estudar',
                        ),
                        const SizedBox(height: 10),
                        for (final (shift, hours, icon) in [
                          ('Manhã', '06:00–12:00', Icons.wb_sunny_outlined),
                          ('Tarde', '12:00–18:00', Icons.wb_twilight_outlined),
                          ('Noite', '18:00–23:00', Icons.nights_stay_outlined),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: draft.shift == shift
                                  ? const Color(0xFF0A4174)
                                  : const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: vm.saving
                                    ? null
                                    : () => vm.change(
                                        draft.copyWith(shift: shift),
                                      ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        icon,
                                        color: draft.shift == shift
                                            ? Colors.white
                                            : const Color(0xFF002B52),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shift,
                                              style: TextStyle(
                                                color: draft.shift == shift
                                                    ? Colors.white
                                                    : const Color(0xFF001C38),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              hours,
                                              style: TextStyle(
                                                color: draft.shift == shift
                                                    ? Colors.white70
                                                    : const Color(0xFF33628A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (draft.shift == shift)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        const Text(
                          'Estes horários organizam sua rotina de estudo. Alertas do sistema ainda não estão disponíveis.',
                        ),
                      ],
                    ),
                  ),
                ],
                if (summary) ...[
                  Text(
                    draft.name.trim().isEmpty
                        ? 'Tudo pronto!'
                        : 'Tudo pronto, ${draft.name.trim()}!',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Seu espaço de estudos está configurado com as escolhas abaixo.',
                  ),
                  const SizedBox(height: 20),
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
                          '${draft.goal}\n${draft.dailyHours}h de estudo por dia · ${draft.days.length} dia(s) por semana\n${draft.shift} · ${draft.days.map((d) => _days[d - 1]).join(' · ')}\nFoco de ${draft.focusMinutes} min + pausa de ${draft.shortBreak} min\n${subjects.subjects.length} disciplina(s) no ciclo',
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
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

  Widget _sectionHeading(BuildContext context, IconData icon, String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF002B52), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF002B52),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
}
