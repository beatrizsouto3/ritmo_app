import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/planned_session.dart';
import '../common/study_layout.dart';
import 'planned_sessions_view_model.dart';

class PlannedSessionsView extends StatelessWidget {
  const PlannedSessionsView({super.key});

  Future<void> _openForm(
    BuildContext context, [
    PlannedSession? session,
  ]) async {
    final vm = context.read<PlannedSessionsViewModel>();
    vm.actionError = null;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _SessionForm(session: session),
      ),
    );
  }

  Future<void> _delete(BuildContext context, PlannedSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir sessão?'),
        content: const Text('A sessão planejada será removida do cronograma.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final vm = context.read<PlannedSessionsViewModel>();
    final done = await vm.delete(session.id);
    if (context.mounted && !done) _showError(context, vm.actionError);
  }

  Future<void> _setStatus(
    BuildContext context,
    PlannedSession session,
    PlannedSessionStatus status,
  ) async {
    final vm = context.read<PlannedSessionsViewModel>();
    final done = await vm.setStatus(session, status);
    if (context.mounted && !done) _showError(context, vm.actionError);
  }

  void _showError(BuildContext context, String? error) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Não foi possível concluir a ação.')),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannedSessionsViewModel>();
    return StudyLayout(
      title: 'Cronograma semanal',
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Semana anterior',
              onPressed: vm.loading ? null : () => vm.changeWeek(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${_date(vm.weekStart)} a ${_date(vm.weekStart.add(const Duration(days: 6)))}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Próxima semana',
              onPressed: vm.loading ? null : () => vm.changeWeek(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (vm.loading) const LinearProgressIndicator(),
        if (vm.error != null)
          StudyPanel(
            child: Column(
              children: [
                Text(vm.error!),
                TextButton(
                  onPressed: vm.load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        FilledButton.icon(
          onPressed:
              vm.loading || vm.saving || vm.error != null || vm.subjects.isEmpty
              ? null
              : () => _openForm(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Planejar sessão'),
        ),
        if (!vm.loading && vm.subjects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Cadastre uma disciplina antes de planejar sessões.'),
          ),
        const SizedBox(height: 12),
        for (var day = 0; day < 7; day++) ...[
          Text(
            '${_weekday(day)} · ${_date(vm.weekStart.add(Duration(days: day)))}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (vm.sessions
              .where(
                (s) => _sameDay(
                  s.startsAt.toLocal(),
                  vm.weekStart.add(Duration(days: day)),
                ),
              )
              .isEmpty)
            const StudyPanel(child: Text('Nenhuma sessão planejada.')),
          for (final session in vm.sessions.where(
            (s) => _sameDay(
              s.startsAt.toLocal(),
              vm.weekStart.add(Duration(days: day)),
            ),
          ))
            StudyPanel(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(vm.subjectName(session.subjectId)),
                subtitle: Text(
                  '${_time(session.startsAt.toLocal())}–${_time(session.endsAt.toLocal())} · ${_status(session.status)}${session.notes == null || session.notes!.isEmpty ? '' : '\n${session.notes}'}',
                ),
                isThreeLine: session.notes != null && session.notes!.isNotEmpty,
                trailing: PopupMenuButton<String>(
                  tooltip: 'Ações da sessão',
                  enabled: !vm.saving,
                  onSelected: (action) {
                    if (action == 'edit') _openForm(context, session);
                    if (action == 'complete') {
                      _setStatus(
                        context,
                        session,
                        PlannedSessionStatus.completed,
                      );
                    }
                    if (action == 'cancel') {
                      _setStatus(
                        context,
                        session,
                        PlannedSessionStatus.cancelled,
                      );
                    }
                    if (action == 'delete') _delete(context, session);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (session.status != PlannedSessionStatus.completed)
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text('Marcar como realizada'),
                      ),
                    if (session.status != PlannedSessionStatus.cancelled)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancelar sessão'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SessionForm extends StatefulWidget {
  const _SessionForm({this.session});
  final PlannedSession? session;
  @override
  State<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<_SessionForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _notes;
  int? _subjectId;
  int? _topicId;
  late int _day;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    final vm = context.read<PlannedSessionsViewModel>();
    _subjectId = session?.subjectId;
    _topicId = session?.topicId;
    _day = (session == null ? DateTime.now() : session.startsAt.toLocal())
        .difference(vm.weekStart)
        .inDays
        .clamp(0, 6)
        .toInt();
    _start = session == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(session.startsAt.toLocal());
    _end = session == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : TimeOfDay.fromDateTime(session.endsAt.toLocal());
    _notes = TextEditingController(text: session?.notes ?? '');
    if (_subjectId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => vm.loadTopics(_subjectId),
      );
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked != null && mounted) {
      setState(() {
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final vm = context.read<PlannedSessionsViewModel>();
    final day = vm.weekStart.add(Duration(days: _day));
    final starts = DateTime(
      day.year,
      day.month,
      day.day,
      _start.hour,
      _start.minute,
    );
    final ends = DateTime(day.year, day.month, day.day, _end.hour, _end.minute);
    final saved = await vm.save(
      PlannedSession(
        id: widget.session?.id ?? 0,
        subjectId: _subjectId!,
        topicId: _topicId,
        startsAt: starts,
        endsAt: ends,
        status: widget.session?.status ?? PlannedSessionStatus.planned,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannedSessionsViewModel>();
    return PopScope(
      canPop: !vm.saving,
      child: AlertDialog(
        scrollable: true,
        title: Text(
          widget.session == null ? 'Planejar sessão' : 'Editar sessão',
        ),
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _subjectId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Disciplina'),
                items: [
                  for (final subject in vm.subjects)
                    DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.name),
                    ),
                ],
                validator: (value) =>
                    value == null ? 'Selecione uma disciplina.' : null,
                onChanged: vm.saving
                    ? null
                    : (value) {
                        setState(() {
                          _subjectId = value;
                          _topicId = null;
                        });
                        vm.loadTopics(value);
                      },
              ),
              DropdownButtonFormField<int>(
                key: ValueKey('$_subjectId-${vm.topics.length}-$_topicId'),
                initialValue: vm.topics.any((topic) => topic.id == _topicId)
                    ? _topicId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tópico (opcional)',
                ),
                items: [
                  for (final topic in vm.topics)
                    DropdownMenuItem(value: topic.id, child: Text(topic.name)),
                ],
                onChanged: vm.saving || vm.loadingTopics || _subjectId == null
                    ? null
                    : (value) => setState(() => _topicId = value),
              ),
              if (_topicId != null)
                TextButton(
                  onPressed: vm.saving
                      ? null
                      : () => setState(() => _topicId = null),
                  child: const Text('Remover tópico'),
                ),
              if (vm.loadingTopics) const LinearProgressIndicator(),
              if (vm.topicError != null)
                TextButton(
                  onPressed: () => vm.loadTopics(_subjectId),
                  child: const Text('Tentar carregar tópicos'),
                ),
              DropdownButtonFormField<int>(
                initialValue: _day,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Dia da semana'),
                items: [
                  for (var i = 0; i < 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        '${_weekday(i)} · ${_date(vm.weekStart.add(Duration(days: i)))}',
                      ),
                    ),
                ],
                onChanged: vm.saving
                    ? null
                    : (value) => setState(() => _day = value!),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: vm.saving ? null : () => _pickTime(true),
                      child: Text('Início ${_start.format(context)}'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: vm.saving ? null : () => _pickTime(false),
                      child: Text('Fim ${_end.format(context)}'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _notes,
                enabled: !vm.saving,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
              ),
              if (vm.actionError != null)
                Text(
                  vm.actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: vm.saving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: vm.saving ? null : _save,
            child: Text(vm.saving ? 'Salvando…' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String _weekday(int day) =>
    const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][day];
String _status(PlannedSessionStatus status) => switch (status) {
  PlannedSessionStatus.planned => 'Planejada',
  PlannedSessionStatus.completed => 'Realizada',
  PlannedSessionStatus.cancelled => 'Cancelada',
};
