import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/topic_repository.dart';
import '../../domain/models/study_topic.dart';
import 'topics_view_model.dart';

class TopicsView extends StatelessWidget {
  const TopicsView({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  final int subjectId;
  final String subjectName;

  Future<void> _openTopicForm(
    BuildContext context,
    TopicsViewModel viewModel, {
    StudyTopic? topic,
  }) async {
    viewModel.clearSaveError();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _TopicForm(topic: topic),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TopicsViewModel viewModel,
    StudyTopic topic,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tópico?'),
        content: Text('“${topic.name}” será removido da disciplina.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final deleted = await viewModel.deleteTopic(topic.id);
      if (!deleted && context.mounted) _showError(context, viewModel.saveError);
    }
  }

  void _showError(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Não foi possível concluir a ação.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          TopicsViewModel(context.read<TopicRepository>(), subjectId)
            ..loadTopics(),
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<TopicsViewModel>();
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FF),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF8F9FF),
              title: Text(subjectName),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: viewModel.isLoading || viewModel.loadError != null
                  ? null
                  : () => _openTopicForm(context, viewModel),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar tópico'),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: _ProgressCard(viewModel: viewModel),
                    ),
                    Expanded(child: _content(context, viewModel)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, TopicsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Carregando tópicos'),
      );
    }
    if (viewModel.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 12),
              Text(viewModel.loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: viewModel.loadTopics,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (viewModel.topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.checklist_rounded,
                size: 52,
                color: Color(0xFF33628A),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum tópico cadastrado',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Adicione assuntos e acompanhe teoria, resumo e exercícios.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: viewModel.topics.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final topic = viewModel.topics[index];
        return _TopicCard(
          topic: topic,
          isSaving: viewModel.isSaving,
          onChanged: (updated) async {
            final saved = await viewModel.updateTopic(updated);
            if (!saved && context.mounted) {
              _showError(context, viewModel.saveError);
            }
          },
          onEdit: () => _openTopicForm(context, viewModel, topic: topic),
          onDelete: () => _confirmDelete(context, viewModel, topic),
          onReview: () async {
            final saved = await viewModel.markReviewed(topic.id);
            if (!saved && context.mounted) {
              _showError(context, viewModel.saveError);
            }
          },
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.viewModel});

  final TopicsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final count = viewModel.topics.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002B52), Color(0xFF0A4174)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROGRESSO DOS TÓPICOS',
                style: TextStyle(
                  color: Color(0xFFA4D0FE),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${(viewModel.progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: viewModel.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: const Color(0xFFA4D0FE),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$count tópico(s) · ${viewModel.completedCount} concluído(s)',
            style: const TextStyle(color: Color(0xFFD3E3FF)),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.isSaving,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onReview,
  });

  final StudyTopic topic;
  final bool isSaving;
  final ValueChanged<StudyTopic> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              title: Text(
                topic.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${topic.completedSteps}/3 etapas concluídas'),
              trailing: PopupMenuButton<String>(
                enabled: !isSaving,
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar nome')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ),
            _TopicCheck(
              label: 'Teoria lida',
              value: topic.theoryRead,
              enabled: !isSaving,
              onChanged: (value) =>
                  onChanged(topic.copyWith(theoryRead: value)),
            ),
            _TopicCheck(
              label: 'Resumo feito',
              value: topic.summaryMade,
              enabled: !isSaving,
              onChanged: (value) =>
                  onChanged(topic.copyWith(summaryMade: value)),
            ),
            _TopicCheck(
              label: 'Exercícios resolvidos',
              value: topic.exercisesSolved,
              enabled: !isSaving,
              onChanged: (value) =>
                  onChanged(topic.copyWith(exercisesSolved: value)),
            ),
            ListTile(
              title: Text(
                topic.lastReviewedAt == null
                    ? 'Ainda não revisado'
                    : 'Última revisão: ${MaterialLocalizations.of(context).formatMediumDate(topic.lastReviewedAt!.toLocal())}',
              ),
              trailing: TextButton(
                onPressed: isSaving ? null : onReview,
                child: const Text('Marcar revisão'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCheck extends StatelessWidget {
  const _TopicCheck({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: enabled ? (checked) => onChanged(checked ?? false) : null,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _TopicForm extends StatefulWidget {
  const _TopicForm({this.topic});

  final StudyTopic? topic;

  @override
  State<_TopicForm> createState() => _TopicFormState();
}

class _TopicFormState extends State<_TopicForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.topic?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<TopicsViewModel>();
    final saved = widget.topic == null
        ? await viewModel.createTopic(_controller.text)
        : await viewModel.updateTopic(
            widget.topic!.copyWith(name: _controller.text.trim()),
          );
    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TopicsViewModel>();
    return PopScope(
      canPop: !viewModel.isSaving,
      child: AlertDialog(
        title: Text(widget.topic == null ? 'Novo tópico' : 'Editar tópico'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                enabled: !viewModel.isSaving,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nome do tópico',
                  hintText: 'Ex.: Introdução ao tema',
                  border: OutlineInputBorder(),
                ),
                validator: StudyTopic.validateName,
                onFieldSubmitted: (_) => _save(),
              ),
              if (viewModel.saveError != null) ...[
                const SizedBox(height: 8),
                Text(
                  viewModel.saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: viewModel.isSaving
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: viewModel.isSaving ? null : _save,
            child: Text(viewModel.isSaving ? 'Salvando…' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}
