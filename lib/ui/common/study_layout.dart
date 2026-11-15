import 'package:flutter/material.dart';

class StudyLayout extends StatelessWidget {
  const StudyLayout({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: children,
          ),
        ),
      ),
    ),
  );
}

class StudyPanel extends StatelessWidget {
  const StudyPanel({super.key, required this.child, this.dark = false});
  final Widget child;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: dark ? null : Colors.white,
      gradient: dark
          ? const LinearGradient(colors: [Color(0xFF002B52), Color(0xFF0A4174)])
          : null,
      boxShadow: const [
        BoxShadow(
          color: Color(0x12001D39),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}
