import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/flashcard_deck.dart';
import '../common/main_navigation_bar.dart';
import 'flashcard_deck_form.dart';
import 'flashcard_deck_view.dart';
import 'flashcard_ui_helpers.dart';
import 'flashcards_view_model.dart';

class FlashcardsView extends StatelessWidget {
  const FlashcardsView({super.key, this.showNavigation = false});

  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FlashcardsViewModel>();
    return Scaffold(
      backgroundColor: flashcardCanvas,
      appBar: AppBar(title: const Text('Flashcards')),
      bottomNavigationBar: showNavigation
          ? MainNavigationBar(
              selectedIndex: 2,
              onSelected: (index) {
                if (index != 2) openMainDestination(context, index);
              },
            )
          : null,
      body: Column(
        children: [
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  FlashcardErrorMessage(viewModel.errorMessage),
                  TextButton(
                    onPressed: viewModel.isBusy ? null : viewModel.loadDecks,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: viewModel.isLoading && viewModel.decks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : viewModel.decks.isEmpty
                ? FlashcardEmptyState(
                    icon: Icons.style_outlined,
                    title: 'Seus estudos começam por um baralho',
                    message: 'Crie um baralho e adicione cartões para começar a revisar.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: viewModel.decks.length,
                    itemBuilder: (context, index) {
                      final deck = viewModel.decks[index];
                      return _DeckTile(
                        deck: deck,
                        statistics: viewModel.statisticsForDeck(deck.id),
                        onTap: () => _openDeck(context, deck),
                        onEdit: () => _showDeckForm(context, deck: deck),
                        onDelete: () => _confirmDelete(context, deck),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isBusy ? null : () => _showDeckForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo baralho'),
      ),
    );
  }

  Future<void> _openDeck(BuildContext context, FlashcardDeck deck) async {
    final viewModel = context.read<FlashcardsViewModel>();
    if (viewModel.isBusy) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => FlashcardDeckView(deckId: deck.id)),
    );
    if (context.mounted) await viewModel.loadDecks();
  }

  Future<void> _showDeckForm(
    BuildContext context, {
    FlashcardDeck? deck,
  }) async {
    final viewModel = context.read<FlashcardsViewModel>();
    if (viewModel.isBusy) return;
    viewModel.clearMessages();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: FlashcardDeckForm(deck: deck),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.notice ?? 'Baralho salvo.')),
      );
      viewModel.clearMessages();
    }
  }

  Future<void> _confirmDelete(BuildContext context, FlashcardDeck deck) async {
    final viewModel = context.read<FlashcardsViewModel>();
    if (viewModel.isBusy) return;
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
