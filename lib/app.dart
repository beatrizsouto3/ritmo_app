import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/app_dependencies.dart';
import 'core/config/ritmo_theme.dart';
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
      theme: buildRitmoTheme(),
      home: auth.isAuthenticated ? const DashboardView() : const AuthView(),
    );
    if (!auth.isAuthenticated) return app;
    return AuthenticatedDependencies(key: ValueKey(auth.userId), child: app);
  }
}
