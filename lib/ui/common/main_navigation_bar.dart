import 'package:flutter/material.dart';

import '../flashcards/flashcards_view.dart';
import '../pomodoro/pomodoro_view.dart';
import '../study/metrics_view.dart';
import '../subjects/subjects_view.dart';

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_rounded),
        label: 'Início',
      ),
      NavigationDestination(
        icon: Icon(Icons.timer_outlined),
        label: 'Pomodoro',
      ),
      NavigationDestination(
        icon: Icon(Icons.style_outlined),
        label: 'Flashcards',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        label: 'Disciplinas',
      ),
      NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        label: 'Métricas',
      ),
    ],
    onDestinationSelected: onSelected,
  );
}

void openMainDestination(BuildContext context, int index) {
  final navigator = Navigator.of(context);
  if (index == 0) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }
  final page = switch (index) {
    1 => const PomodoroView(showNavigation: true),
    2 => const FlashcardsView(showNavigation: true),
    3 => const SubjectsView(showNavigation: true),
    4 => const MetricsView(showNavigation: true),
    _ => throw RangeError.range(index, 0, 4),
  };
  navigator.popUntil((route) => route.isFirst);
  navigator.push(MaterialPageRoute<void>(builder: (_) => page));
}
