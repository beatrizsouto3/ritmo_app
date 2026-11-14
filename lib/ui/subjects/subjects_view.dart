import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/subject.dart';
import 'subject_form.dart';
import 'topics_view.dart';
import 'subjects_view_model.dart';

class SubjectsView extends StatefulWidget {
  const SubjectsView({super.key});

  @override
  State<SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<SubjectsView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final subjects = viewModel.subjects
        .where((subject) => subject.name.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ritmo', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              'Disciplinas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProgressSummary(
                        count: viewModel.subjects.length,
                        isLoading: viewModel.isLoading,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Buscar disciplinas…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar busca',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: const Color(0xFFEFF4FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Suas disciplinas',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${viewModel.subjects.length}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: const Color(0xFF33628A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildContent(context, viewModel, subjects)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          viewModel.isLoading || viewModel.loadError != null
                          ? null
                          : () => _openForm(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Adicionar disciplina'),
                      ),
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

  Widget _buildContent(
    BuildContext context,
    SubjectsViewModel viewModel,
    List<Subject> subjects,
  ) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          semanticsLabel: 'Carregando disciplinas',
        ),
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
              const SizedBox(height: 16),
              Text(viewModel.loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: viewModel.loadSubjects,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (subjects.isEmpty) {
      final hasSearch = _query.isNotEmpty;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSearch ? Icons.search_off_rounded : Icons.menu_book_rounded,
                size: 48,
                color: const Color(0xFF33628A),
              ),
              const SizedBox(height: 16),
              Text(
                hasSearch ? 'Nenhum resultado' : 'Sua lista começa aqui',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                hasSearch
                    ? 'Tente buscar por outro nome.'
                    : 'Cadastre uma disciplina para organizar seus assuntos.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      itemCount: subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return Card(
          key: ValueKey(subject.id),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE6EEFF),
              foregroundColor: Color(0xFF0A4174),
              child: Icon(Icons.menu_book_rounded),
            ),
            title: Text(
              subject.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Tópicos e progresso de estudo'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TopicsView(
                  subjectId: subject.id,
                  subjectName: subject.name,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.count, required this.isLoading});

  final int count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(Icons.auto_stories_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLANO DE ESTUDOS',
                  style: TextStyle(
                    color: Color(0xFFA4D0FE),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading
                      ? 'Carregando…'
                      : count == 1
                      ? '1 disciplina cadastrada'
                      : '$count disciplinas cadastradas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Seu progresso será calculado com os tópicos.',
                  style: TextStyle(color: Color(0xFFD3E3FF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
