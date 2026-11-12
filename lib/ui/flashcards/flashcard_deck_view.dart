import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/flashcard.dart';
import '../../domain/models/flashcard_deck.dart';
import 'flashcard_form_view.dart';
import 'flashcard_review_view.dart';
import 'flashcard_ui_helpers.dart';
import 'flashcards_view_model.dart';

class FlashcardDeckView extends StatelessWidget {
  const FlashcardDeckView({required this.deckId, super.key});

  final int deckId;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FlashcardsViewModel>();
    final FlashcardDeck? deck = viewModel.deckById(deckId);
    if (deck == null) {
      return Scaffold(
        backgroundColor: flashcardCanvas,
        appBar: AppBar(title: const Text('Baralho')),
        body: const FlashcardEmptyState(
          icon: Icons.info_outline,
          title: 'Baralho não encontrado',
          message: 'Volte à lista e abra um baralho disponível.',
        ),
      );
    }

    final cards = viewModel.cardsForDeck(deckId);
    final stats = viewModel.statisticsForDeck(deckId);
    return Scaffold(
      backgroundColor: flashcardCanvas,
      appBar: AppBar(
        title: Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: flashcardCanvas,
        foregroundColor: flashcardNavy,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (deck.description != null) ...[
                  Text(deck.description!),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CountPill(label: '${stats.total} cartões'),
                    _CountPill(label: '${stats.due} a revisar'),
                    _CountPill(label: '${stats.retained} retidos'),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: stats.total == 0 ? 0 : stats.retained / stats.total,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                  color: flashcardPrimary,
                  backgroundColor: flashcardTint,
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  FlashcardErrorMessage(viewModel.errorMessage),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: stats.due == 0 || viewModel.isBusy
                        ? null
                        : () => _startReview(context),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      stats.due == 0
                          ? 'Sem cartões vencidos'
                          : 'Revisar ${stats.due} cartões',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: viewModel.isLoading && cards.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : cards.isEmpty
                ? FlashcardEmptyState(
                    icon: Icons.note_add_outlined,
                    title: 'Este baralho ainda está vazio',
                    message: 'Crie o primeiro cartão com uma pergunta e uma resposta.',
                    action: FilledButton.icon(
                      onPressed: viewModel.isBusy
                          ? null
                          : () => _createCard(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Criar cartão'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    itemCount: cards.length,
                    itemBuilder: (context, index) => _FlashcardTile(
                      card: cards[index],
                      onEdit: () => _editCard(context, cards[index]),
                      onDelete: () => _deleteCard(context, cards[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isBusy ? null : () => _createCard(context),
        backgroundColor: flashcardPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo cartão'),
      ),
    );
  }

  Future<void> _createCard(BuildContext context) async {
    if (context.read<FlashcardsViewModel>().isBusy) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardFormView(deckId: deckId),
      ),
    );
  }

  Future<void> _editCard(BuildContext context, Flashcard card) async {
    if (context.read<FlashcardsViewModel>().isBusy) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FlashcardFormView(deckId: deckId, card: card),
      ),
    );
  }

  Future<void> _startReview(BuildContext context) async {
    final viewModel = context.read<FlashcardsViewModel>();
    final started = await viewModel.startReview(deckId);
    if (!context.mounted) return;
    if (!started) {
      final notice = viewModel.notice;
      if (notice != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(notice)));
        viewModel.clearMessages();
      }
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const FlashcardReviewView()),
    );
    if (context.mounted) await viewModel.loadCardsForDeck(deckId);
  }

  Future<void> _deleteCard(BuildContext context, Flashcard card) async {
    final viewModel = context.read<FlashcardsViewModel>();
    if (viewModel.isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir cartão?'),
        content: const Text(
          'O cartão e o histórico de revisão serão removidos.',
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
    if (confirmed == true) await viewModel.deleteCard(card.id);
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: flashcardTint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: flashcardPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  const _FlashcardTile({
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  final Flashcard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDue = card.isDueAt(DateTime.now());
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDue ? Icons.schedule : Icons.check_circle_outline,
                        size: 16,
                        color: isDue ? flashcardSecondary : flashcardPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(isDue ? 'A revisar' : 'Agendado'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    card.front,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: flashcardNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (card.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.image_outlined, size: 16),
                        SizedBox(width: 5),
                        Text('Contém imagem'),
                      ],
                    ),
                  ],
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
      ),
    );
  }
}
