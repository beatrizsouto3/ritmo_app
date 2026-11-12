import 'package:flutter/material.dart';

import '../../data/models/flashcard_deck.dart';
import 'flashcard_deck_view.dart';
import 'flashcard_ui_helpers.dart';
import 'flashcards_view_model.dart';

class FlashcardsView extends StatefulWidget {
  const FlashcardsView({required this.viewModel, super.key});

  final FlashcardsViewModel viewModel;

  @override
  State<FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends State<FlashcardsView> {
  FlashcardsViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    viewModel.loadDecks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: flashcardCanvas,
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: flashcardCanvas,
        foregroundColor: flashcardNavy,
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading && viewModel.decks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: FlashcardErrorMessage(viewModel.errorMessage),
              ),
              Expanded(
                child: viewModel.decks.isEmpty
                    ? FlashcardEmptyState(
                        icon: Icons.style_outlined,
                        title: 'Seus estudos começam por um baralho',
                        message: 'Crie um baralho e adicione cartões para começar a revisar.',
                        action: FilledButton.icon(
                          onPressed: _showDeckForm,
                          icon: const Icon(Icons.add),
                          label: const Text('Criar baralho'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: viewModel.decks.length,
                        itemBuilder: (context, index) => _DeckTile(
                          deck: viewModel.decks[index],
                          statistics: viewModel.statisticsForDeck(
                            viewModel.decks[index].id,
                          ),
                          onTap: () => _openDeck(viewModel.decks[index]),
                          onEdit: () =>
                              _showDeckForm(deck: viewModel.decks[index]),
                          onDelete: () =>
                              _confirmDelete(viewModel.decks[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDeckForm,
        backgroundColor: flashcardPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo baralho'),
      ),
    );
  }

  Future<void> _openDeck(FlashcardDeck deck) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            FlashcardDeckView(deckId: deck.id, viewModel: viewModel),
      ),
    );
    if (mounted) await viewModel.loadDecks();
  }

  Future<void> _showDeckForm({FlashcardDeck? deck}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: deck?.name ?? '');
    final descriptionController = TextEditingController(
      text: deck?.description ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(deck == null ? 'Novo baralho' : 'Editar baralho'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome do baralho.'
                    : null,
              ),
              TextFormField(
                controller: descriptionController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = deck == null
                  ? await viewModel.createDeck(
                      name: nameController.text,
                      description: descriptionController.text,
                    )
                  : await viewModel.updateDeck(
                      deck.copyWith(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        clearDescription: descriptionController.text
                            .trim()
                            .isEmpty,
                      ),
                    );
              if (dialogContext.mounted) Navigator.pop(dialogContext, ok);
            },
            child: Text(deck == null ? 'Criar' : 'Salvar'),
          ),
        ],
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.notice ?? 'Baralho salvo.')),
      );
      viewModel.clearMessages();
    }
  }

  Future<void> _confirmDelete(FlashcardDeck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir baralho?'),
        content: Text(
          '“${deck.name}” e os cartões associados serão removidos.',
        ),
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
    if (confirmed == true) await viewModel.deleteDeck(deck.id);
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({
    required this.deck,
    required this.statistics,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FlashcardDeck deck;
  final DeckStatistics statistics;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = statistics.total == 0
        ? 0.0
        : statistics.retained / statistics.total;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: flashcardTint,
                    foregroundColor: flashcardPrimary,
                    child: Icon(Icons.style_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: flashcardNavy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (deck.description != null)
                          Text(
                            deck.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(label: '${statistics.total} cartões'),
                  _StatChip(label: '${statistics.newCards} novos'),
                  _StatChip(label: '${statistics.due} a revisar'),
                  _StatChip(label: '${statistics.retained} retidos'),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: flashcardTint,
                color: flashcardPrimary,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      statistics.total == 0
                          ? 'Adicione cartões para iniciar.'
                          : '${(progress * 100).round()}% fora da fila de revisão',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: flashcardSecondary),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: flashcardSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: flashcardPaleBlue,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: flashcardPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
