import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/app_dependencies.dart';
import 'core/config/ritmo_theme.dart';
import 'ui/auth/auth_view.dart';
import 'ui/auth/auth_view_model.dart';
import 'ui/dashboard/dashboard_view.dart';
import 'ui/study/preferences_view.dart';
import 'ui/study/study_view_model.dart';

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
      home: auth.isRestoring
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isAuthenticated
          ? const _AuthenticatedHome()
          : const AuthView(),
    );
    if (auth.isRestoring || !auth.isAuthenticated) return app;
    return AuthenticatedDependencies(key: ValueKey(auth.userId), child: app);
  }
}

class _AuthenticatedHome extends StatelessWidget {
  const _AuthenticatedHome();

  @override
  Widget build(BuildContext context) {
    final study = context.watch<StudyViewModel>();
    if (!study.loaded) {
      return Scaffold(
        body: Center(
          child: study.busy
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        study.error ?? 'Não foi possível carregar seu perfil.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: study.load,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    return study.preferences.configured
        ? const DashboardView()
        : const PreferencesView(onboarding: true);
  }
}
