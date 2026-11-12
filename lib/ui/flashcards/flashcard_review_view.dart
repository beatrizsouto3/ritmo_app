import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/flashcard.dart';
import '../../domain/models/flashcard_rating.dart';
import 'flashcard_ui_helpers.dart';
import 'flashcards_view_model.dart';

class FlashcardReviewView extends StatelessWidget {
  const FlashcardReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FlashcardsViewModel>();
    final card = viewModel.activeReviewCard;
    return PopScope(
      canPop: !viewModel.isSaving,
      child: Scaffold(
        backgroundColor: flashcardCanvas,
        appBar: AppBar(
          title: const Text('Revisão'),
          backgroundColor: flashcardCanvas,
          foregroundColor: flashcardNavy,
        ),
        body: card == null
            ? FlashcardEmptyState(
                icon: Icons.celebration_outlined,
                title: 'Revisão concluída!',
                message:
                    '${viewModel.reviewCompleted} cartão(ões) revisado(s). Volte mais tarde para continuar.',
                action: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar ao baralho'),
                ),
              )
            : _ReviewCard(viewModel: viewModel, card: card),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.viewModel, required this.card});

  final FlashcardsViewModel viewModel;
  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    final completed = viewModel.reviewCompleted;
    final total = viewModel.reviewTotal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : completed / total,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                    color: flashcardPrimary,
                    backgroundColor: flashcardTint,
                  ),
                ),
                const SizedBox(width: 12),
                Text('$completed/$total'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: flashcardOutline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.isAnswerVisible ? 'RESPOSTA' : 'PERGUNTA',
                          style: const TextStyle(
                            color: flashcardSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          viewModel.isAnswerVisible ? card.back : card.front,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: flashcardNavy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (card.imageUrl != null) ...[
                          const SizedBox(height: 20),
                          FlashcardImagePreview(imageUrl: card.imageUrl),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            FlashcardErrorMessage(viewModel.errorMessage),
            if (!viewModel.isAnswerVisible)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: viewModel.revealAnswer,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Revelar resposta'),
                ),
              )
            else ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Como foi sua lembrança?',
                  style: TextStyle(
                    color: flashcardNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final rating in const [
                    FlashcardRating.hard,
                    FlashcardRating.good,
                    FlashcardRating.easy,
                  ]) ...[
                    Expanded(
                      child: _RatingButton(
                        rating: rating,
                        intervalLabel: viewModel.reviewIntervalLabel(rating),
                        enabled: !viewModel.isSaving,
                        onPressed: () => viewModel.rateCurrentCard(rating),
                      ),
                    ),
                    if (rating != FlashcardRating.easy)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.rating,
    required this.intervalLabel,
    required this.enabled,
    required this.onPressed,
  });

  final FlashcardRating rating;
  final String intervalLabel;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        foregroundColor: flashcardPrimary,
        side: const BorderSide(color: flashcardOutline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rating.label, textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(intervalLabel, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
