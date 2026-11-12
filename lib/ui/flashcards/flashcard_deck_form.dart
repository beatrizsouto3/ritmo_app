import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/flashcard_deck.dart';
import 'flashcards_view_model.dart';

class FlashcardDeckForm extends StatefulWidget {
  const FlashcardDeckForm({super.key, this.deck});

  final FlashcardDeck? deck;

  @override
  State<FlashcardDeckForm> createState() => _FlashcardDeckFormState();
}

class _FlashcardDeckFormState extends State<FlashcardDeckForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.deck?.name);
  late final _descriptionController = TextEditingController(
    text: widget.deck?.description,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<FlashcardsViewModel>();
    final deck = widget.deck;
    final saved = deck == null
        ? await viewModel.createDeck(
            name: _nameController.text,
            description: _descriptionController.text,
          )
        : await viewModel.updateDeck(
            deck.copyWith(
              name: _nameController.text,
              description: _descriptionController.text,
              clearDescription: _descriptionController.text.trim().isEmpty,
            ),
          );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FlashcardsViewModel>();
    return PopScope(
      canPop: !viewModel.isSaving,
      child: AlertDialog(
        scrollable: true,
        title: Text(widget.deck == null ? 'Novo baralho' : 'Editar baralho'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !viewModel.isSaving,
                autofocus: true,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome do baralho.'
                    : null,
              ),
              TextFormField(
                controller: _descriptionController,
                enabled: !viewModel.isSaving,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
              ),
              if (viewModel.errorMessage != null)
                Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
