import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/question_record.dart';
import '../common/study_layout.dart';
import 'question_records_view_model.dart';

class QuestionRecordsView extends StatefulWidget {
  const QuestionRecordsView({super.key});

  @override
  State<QuestionRecordsView> createState() => _QuestionRecordsViewState();
}

class _QuestionRecordsViewState extends State<QuestionRecordsView> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _correctController = TextEditingController();
  final _incorrectController = TextEditingController();
  int? _subjectId;
  int? _topicId;
  DateTime _recordedAt = DateTime.now();
  QuestionRecord? _editingRecord;

  @override
  void dispose() {
    _totalController.dispose();
    _correctController.dispose();
    _incorrectController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (date != null && mounted) setState(() => _recordedAt = date);
  }

  Future<void> _save(QuestionRecordsViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    final total = int.parse(_totalController.text.trim());
    final correct = int.parse(_correctController.text.trim());
    final incorrect = int.parse(_incorrectController.text.trim());
    final saved = _editingRecord == null
        ? await viewModel.createRecord(
            subjectId: _subjectId!,
            topicId: _topicId,
            total: total,
            correct: correct,
            incorrect: incorrect,
            recordedAt: _recordedAt,
          )
        : await viewModel.updateRecord(
            QuestionRecord(
              id: _editingRecord!.id,
              subjectId: _subjectId!,
              topicId: _topicId,
              total: total,
              correct: correct,
              incorrect: incorrect,
              recordedAt: _recordedAt,
            ),
          );
    if (!mounted || !saved) return;
    final wasEditing = _editingRecord != null;
    _resetForm();
    await viewModel.loadTopics(null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasEditing ? 'Registro atualizado.' : 'Registro salvo.'),
      ),
    );
  }

  void _resetForm() {
    _totalController.clear();
    _correctController.clear();
    _incorrectController.clear();
    setState(() {
      _subjectId = null;
      _topicId = null;
      _recordedAt = DateTime.now();
      _editingRecord = null;
    });
  }

  Future<void> _editRecord(
    QuestionRecordsViewModel viewModel,
    QuestionRecord record,
  ) async {
    viewModel.clearSaveError();
    _totalController.text = record.total.toString();
    _correctController.text = record.correct.toString();
    _incorrectController.text = record.incorrect.toString();
    setState(() {
      _editingRecord = record;
      _subjectId = record.subjectId;
      _topicId = record.topicId;
      _recordedAt = record.recordedAt.toLocal();
    });
    await viewModel.loadTopics(record.subjectId);
    if (mounted && _formKey.currentContext != null) {
      await Scrollable.ensureVisible(
        _formKey.currentContext!,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  Future<void> _deleteRecord(
    QuestionRecordsViewModel viewModel,
    QuestionRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text(
          'O registro de questões será removido do histórico e das métricas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await viewModel.deleteRecord(record.id);
    if (!mounted) return;
    if (deleted && _editingRecord?.id == record.id) {
      _resetForm();
      await viewModel.loadTopics(null);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Registro excluído.'
              : viewModel.saveError ?? 'Não foi possível excluir o registro.',
        ),
      ),
    );
  }

  Future<void> _chooseFilterPeriod(QuestionRecordsViewModel viewModel) async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year, today.month, today.day),
      initialDateRange:
          viewModel.filterStart != null && viewModel.filterEnd != null
          ? DateTimeRange(
              start: viewModel.filterStart!,
              end: viewModel.filterEnd!,
            )
          : null,
    );
    if (range != null) {
      viewModel.setDateFilter(range.start, range.end);
    }
  }

  String? _validateCount(String? value, {required bool allowZero}) {
    final count = int.tryParse(value?.trim() ?? '');
    if (count == null) return 'Informe um número inteiro.';
    if (allowZero ? count < 0 : count < 1) {
      return allowZero
          ? 'Use zero ou um número maior.'
          : 'Informe um número maior que zero.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<QuestionRecordsViewModel>();
    if (viewModel.isLoading && viewModel.subjects.isEmpty) {
      return const StudyLayout(
        title: 'Questões e simulados',
        children: [Center(child: CircularProgressIndicator())],
      );
    }
    if (viewModel.loadError != null && viewModel.subjects.isEmpty) {
      return StudyLayout(
        title: 'Questões e simulados',
        children: [
          StudyPanel(
            child: Column(
              children: [
                Text(viewModel.loadError!, textAlign: TextAlign.center),
                TextButton(
                  onPressed: viewModel.load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return StudyLayout(
      title: 'Questões e simulados',
      children: [
        if (viewModel.loadError != null)
          StudyPanel(
            child: Column(
              children: [
                Text(viewModel.loadError!, textAlign: TextAlign.center),
                TextButton(
                  onPressed: viewModel.load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        StudyPanel(
          dark: true,
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined, color: Color(0xFFA4D0FE)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APROVEITAMENTO GERAL',
                      style: TextStyle(
                        color: Color(0xFFA4D0FE),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      viewModel.totalQuestions == 0
                          ? 'Sem questões registradas'
                          : '${(viewModel.accuracy * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${viewModel.correctAnswers} acerto(s) em '
                      '${viewModel.totalQuestions} questão(ões)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          _editingRecord == null ? 'Novo registro' : 'Editar registro',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        StudyPanel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey('subject-${_editingRecord?.id}-$_subjectId'),
                  initialValue: _subjectId,
                  isExpanded: true,
                  hint: const Text('Selecione uma disciplina'),
                  decoration: const InputDecoration(
                    labelText: 'Disciplina',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final subject in viewModel.subjects)
                      DropdownMenuItem<int>(
                        value: subject.id,
                        child: Text(subject.name),
                      ),
                  ],
                  validator: (value) =>
                      value == null ? 'Selecione uma disciplina.' : null,
                  onChanged: viewModel.isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _subjectId = value;
                            _topicId = null;
                          });
                          viewModel.loadTopics(value);
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    'topic-$_subjectId-$_topicId-${viewModel.isLoadingTopics}',
                  ),
                  initialValue:
                      viewModel.topics.any((topic) => topic.id == _topicId)
                      ? _topicId
                      : null,
                  isExpanded: true,
                  hint: const Text('Sem tópico específico'),
                  decoration: const InputDecoration(
                    labelText: 'Tópico (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final topic in viewModel.topics)
                      DropdownMenuItem<int>(
                        value: topic.id,
                        child: Text(topic.name),
                      ),
                  ],
                  onChanged:
                      viewModel.isSaving ||
                          _subjectId == null ||
                          viewModel.isLoadingTopics
                      ? null
                      : (value) => setState(() => _topicId = value),
                ),
                if (viewModel.isLoadingTopics)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (viewModel.topicError != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(viewModel.topicError!),
                  ),
                  TextButton.icon(
                    onPressed: () => viewModel.loadTopics(_subjectId),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar carregar tópicos'),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totalController,
                  enabled: !viewModel.isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total de questões',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateCount(value, allowZero: false),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _correctController,
                        enabled: !viewModel.isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Acertos',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _validateCount(value, allowZero: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _incorrectController,
                        enabled: !viewModel.isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Erros',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _validateCount(value, allowZero: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: viewModel.isSaving ? null : _chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Data: ${_formatDate(_recordedAt)}'),
                ),
                if (viewModel.saveError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    viewModel.saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      viewModel.isSaving ||
                          viewModel.isLoadingTopics ||
                          (_topicId != null &&
                              !viewModel.topics.any(
                                (topic) => topic.id == _topicId,
                              )) ||
                          viewModel.subjects.isEmpty
                      ? null
                      : () => _save(viewModel),
                  icon: viewModel.isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    viewModel.isSaving
                        ? 'Salvando…'
                        : _editingRecord == null
                        ? 'Salvar registro'
                        : 'Salvar alterações',
                  ),
                ),
                if (_editingRecord != null)
                  TextButton(
                    onPressed: viewModel.isSaving
                        ? null
                        : () {
                            viewModel.clearSaveError();
                            _resetForm();
                            viewModel.loadTopics(null);
                          },
                    child: const Text('Cancelar edição'),
                  ),
                if (viewModel.subjects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Cadastre uma disciplina antes de registrar questões.',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          'Histórico',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        StudyPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtrar histórico',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('filter-${viewModel.filterSubjectId}'),
                initialValue: viewModel.filterSubjectId ?? 0,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Disciplina',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Todas as disciplinas'),
                  ),
                  for (final subject in viewModel.subjects)
                    DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.name),
                    ),
                ],
                onChanged: (value) =>
                    viewModel.setSubjectFilter(value == 0 ? null : value),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _chooseFilterPeriod(viewModel),
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  viewModel.filterStart == null
                      ? 'Todas as datas'
                      : '${_formatDate(viewModel.filterStart!)} a '
                            '${_formatDate(viewModel.filterEnd!)}',
                ),
              ),
              if (viewModel.filterSubjectId != null ||
                  viewModel.filterStart != null)
                TextButton(
                  onPressed: viewModel.clearFilters,
                  child: const Text('Limpar filtros'),
                ),
            ],
          ),
        ),
        if (viewModel.records.isEmpty)
          const StudyPanel(
            child: Text(
              'Seus registros de questões aparecerão aqui depois que você '
              'salvar o primeiro.',
            ),
          )
        else if (viewModel.filteredRecords.isEmpty)
          const StudyPanel(
            child: Text('Nenhum registro encontrado neste filtro.'),
          )
        else
          for (final record in viewModel.filteredRecords)
            _QuestionRecordCard(
              record: record,
              viewModel: viewModel,
              onEdit: () => _editRecord(viewModel, record),
              onDelete: () => _deleteRecord(viewModel, record),
            ),
      ],
    );
  }
}

class _QuestionRecordCard extends StatelessWidget {
  const _QuestionRecordCard({
    required this.record,
    required this.viewModel,
    required this.onEdit,
    required this.onDelete,
  });

  final QuestionRecord record;
  final QuestionRecordsViewModel viewModel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final topicName = viewModel.topicName(record.subjectId, record.topicId);
    return StudyPanel(
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE6EEFF),
            foregroundColor: Color(0xFF0A4174),
            child: Icon(Icons.fact_check_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.subjectName(record.subjectId),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (topicName != null) Text(topicName),
                Text(
                  '${record.correct} acertos · ${record.incorrect} erros · '
                  '${_formatDate(record.recordedAt.toLocal())}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '${(record.accuracy * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A4174),
                ),
              ),
              PopupMenuButton<_RecordAction>(
                tooltip: 'Ações do registro',
                enabled: !viewModel.isSaving,
                onSelected: (action) {
                  if (action == _RecordAction.edit) onEdit();
                  if (action == _RecordAction.delete) onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _RecordAction.edit,
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: _RecordAction.delete,
                    child: Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RecordAction { edit, delete }

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
