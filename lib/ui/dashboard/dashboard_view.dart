import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
import '../flashcards/flashcards_view.dart';
import '../subjects/subjects_view.dart';
import '../subjects/subjects_view_model.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectsViewModel>();
    final auth = context.watch<AuthViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        title: const Text('Ritmo'),
        actions: [
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: auth.isBusy ? null : auth.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Text(
                  'Seu espaço de estudos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF002B52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Organize sua rotina e continue no seu ritmo.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF42474F),
                  ),
                ),
                const SizedBox(height: 22),
                _WelcomeCard(
                  subjectCount: subjects.subjects.length,
                  isLoading: subjects.isLoading,
                  onOpenSubjects: () => _open(context, const SubjectsView()),
                ),
                const SizedBox(height: 20),
                Text(
                  'Continue por aqui',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Disciplinas',
                  subtitle: subjects.isLoading
                      ? 'Carregando suas disciplinas…'
                      : subjects.loadError != null
                      ? 'Não foi possível carregar agora'
                      : '${subjects.subjects.length} cadastrada(s)',
                  onTap: () => _open(context, const SubjectsView()),
                ),
                const SizedBox(height: 10),
                _FeatureTile(
                  icon: Icons.style_rounded,
                  title: 'Flashcards',
                  subtitle: 'Crie baralhos e revise seus cartões',
                  onTap: () => _open(context, const FlashcardsView()),
                ),
                const SizedBox(height: 22),
                Text(
                  'Seu resumo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.timer_outlined,
                        title: 'Tempo estudado',
                        value: 'Sem registros',
                        color: colors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.event_note_rounded,
                        title: 'Próxima sessão',
                        value: 'Cronograma em breve',
                        color: colors.secondaryContainer,
                      ),
                    ),
                  ],
                ),
                if (subjects.loadError != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: subjects.loadSubjects,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar carregar disciplinas novamente'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: 'Flashcards',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Disciplinas',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == 1) _open(context, const FlashcardsView());
          if (index == 2) _open(context, const SubjectsView());
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.subjectCount,
    required this.isLoading,
    required this.onOpenSubjects,
  });

  final int subjectCount;
  final bool isLoading;
  final VoidCallback onOpenSubjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002B52), Color(0xFF0A4174)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 14),
          Text(
            isLoading
                ? 'Preparando seu espaço…'
                : subjectCount == 0
                ? 'Vamos começar?'
                : 'Você está construindo constância.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLoading
                ? 'Carregando seus dados.'
                : subjectCount == 0
                ? 'Cadastre uma disciplina para organizar seus estudos.'
                : 'Suas disciplinas já estão prontas para o próximo estudo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: onOpenSubjects,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(subjectCount == 0 ? 'Adicionar disciplina' : 'Ver disciplinas'),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6EEFF),
          foregroundColor: const Color(0xFF0A4174),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0A4174)),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
