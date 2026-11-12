import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/app_dependencies.dart';
import 'ui/auth/auth_view.dart';
import 'ui/auth/auth_view_model.dart';
import 'ui/dashboard/dashboard_view.dart';

class RitmoApp extends StatelessWidget {
  const RitmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final app = MaterialApp(
      key: ValueKey(auth.userId),
      title: 'Ritmo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A4174),
          primary: const Color(0xFF0A4174),
          surface: const Color(0xFFF8F9FF),
          onSurface: const Color(0xFF001C38),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      ),
      home: auth.isAuthenticated ? const DashboardView() : const AuthView(),
    );
    if (!auth.isAuthenticated) return app;
    return AuthenticatedDependencies(key: ValueKey(auth.userId), child: app);
  }
}
