import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/subject.dart';
import 'subjects_view_model.dart';

class SubjectForm extends StatefulWidget {
  const SubjectForm({super.key});

  @override
  State<SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await context.read<SubjectsViewModel>().createSubject(
      _nameController.text,
    );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectsViewModel>();
    return PopScope(
      canPop: !viewModel.isSaving,
      child: AlertDialog(
        scrollable: true,
        title: const Text('Adicionar disciplina'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                enabled: !viewModel.isSaving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nome da disciplina',
                  hintText: 'Ex.: Matemática',
                  border: OutlineInputBorder(),
                ),
                validator: Subject.validateName,
                onFieldSubmitted: (_) => _save(),
              ),
              if (viewModel.saveError != null) ...[
                const SizedBox(height: 16),
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
                : () => Navigator.of(context).pop(false),
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
