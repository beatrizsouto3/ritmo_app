import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/flashcard.dart';
import 'flashcard_ui_helpers.dart';
import 'flashcards_view_model.dart';

class FlashcardFormView extends StatefulWidget {
  const FlashcardFormView({required this.deckId, this.card, super.key});

  final int deckId;
  final Flashcard? card;

  @override
  State<FlashcardFormView> createState() => _FlashcardFormViewState();
}

class _FlashcardFormViewState extends State<FlashcardFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.front ?? '');
    _backController = TextEditingController(text: widget.card?.back ?? '');
    _imageController = TextEditingController(text: widget.card?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FlashcardsViewModel>();
    final isEditing = widget.card != null;
    return PopScope(
      canPop: !viewModel.isSaving,
      child: Scaffold(
        backgroundColor: flashcardCanvas,
        appBar: AppBar(
          title: Text(isEditing ? 'Editar cartão' : 'Novo cartão'),
          backgroundColor: flashcardCanvas,
          foregroundColor: flashcardNavy,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Frente',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: flashcardNavy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _frontController,
                enabled: !viewModel.isSaving,
                minLines: 3,
                maxLines: 6,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Digite a pergunta ou conceito...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _requiredText,
              ),
              const SizedBox(height: 14),
              const Text(
                'Verso',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: flashcardNavy,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _backController,
                enabled: !viewModel.isSaving,
                minLines: 3,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Digite a resposta ou explicação...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _requiredText,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _imageController,
                enabled: !viewModel.isSaving,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Imagem (opcional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: _validateImageUrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              FlashcardImagePreview(imageUrl: _imageController.text),
              FlashcardErrorMessage(viewModel.errorMessage),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: viewModel.isSaving ? null : _save,
                icon: viewModel.isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isEditing ? 'Salvar alterações' : 'Criar cartão'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  String? _validateImageUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      return 'Informe uma URL iniciada por http:// ou https://.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<FlashcardsViewModel>();
    final imageUrl = _imageController.text.trim();
    final card = widget.card;
    final saved = card == null
        ? await viewModel.createCard(
            deckId: widget.deckId,
            front: _frontController.text,
            back: _backController.text,
            imageUrl: imageUrl.isEmpty ? null : imageUrl,
          )
        : await viewModel.updateCard(
            card.copyWith(
              front: _frontController.text.trim(),
              back: _backController.text.trim(),
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
              clearImageUrl: imageUrl.isEmpty,
            ),
          );
    if (!mounted || !saved) return;
    Navigator.of(context).pop();
  }
}
