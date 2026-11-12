import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
import '../subjects/subjects_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ritmo'),
        actions: [
          TextButton.icon(
            onPressed: context.watch<AuthViewModel>().isBusy
                ? null
                : () => context.read<AuthViewModel>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Seu espaço de estudos.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SubjectsView()),
              ),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Disciplinas'),
            ),
          ],
        ),
      ),
    );
  }
}
