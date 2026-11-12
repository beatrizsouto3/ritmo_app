import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'subject_form.dart';
import 'subjects_view_model.dart';

class SubjectsView extends StatelessWidget {
  const SubjectsView({super.key});

  Future<void> _openForm(BuildContext context) async {
    final viewModel = context.read<SubjectsViewModel>();
    viewModel.clearSaveError();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const SubjectForm(),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Disciplina cadastrada.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Disciplinas')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Organize o que você vai estudar.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Expanded(child: _buildContent(context, viewModel)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton.icon(
                    onPressed:
                        viewModel.isLoading || viewModel.loadError != null
                        ? null
                        : () => _openForm(context),
                    icon: const Icon(Icons.add),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Adicionar disciplina'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SubjectsViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Carregando disciplinas',
        ),
      );
    }
    if (viewModel.loadError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 16),
              Text(viewModel.loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: viewModel.loadSubjects,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (viewModel.subjects.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Nenhuma disciplina cadastrada',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Adicione sua primeira disciplina para começar.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: viewModel.subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final subject = viewModel.subjects[index];
        return Card(
          key: ValueKey(subject.id),
          color: Colors.white,
          elevation: 1,
          shadowColor: const Color(0x18001D39),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
