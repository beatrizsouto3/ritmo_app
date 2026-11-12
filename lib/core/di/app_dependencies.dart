import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../data/repositories/subject_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/flashcard_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/flashcard_service.dart';
import '../../data/services/subject_service.dart';
import '../../ui/subjects/subjects_view_model.dart';
import '../../ui/auth/auth_view_model.dart';
import '../../ui/flashcards/flashcards_view_model.dart';
import '../config/supabase_config.dart';

class AppDependencies extends StatelessWidget {
  const AppDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: const SupabaseConfig.fromEnvironment()),
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, client) => client.close(),
        ),
        Provider(
          create: (context) =>
              AuthService(config: context.read(), client: context.read()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthRepository(context.read()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(context.read()),
        ),
      ],
      child: child,
    );
  }
}

class AuthenticatedDependencies extends StatelessWidget {
  const AuthenticatedDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(
          create: (context) => SubjectService(
            config: context.read(),
            client: context.read(),
            accessToken: context.read<AuthRepository>().getAccessToken,
          ),
        ),
        Provider(create: (context) => SubjectRepository(context.read())),
        ChangeNotifierProvider(
          create: (context) =>
              SubjectsViewModel(context.read())..loadSubjects(),
        ),
        Provider(
          create: (context) => FlashcardService(
            config: context.read(),
            client: context.read(),
            accessToken: context.read<AuthRepository>().getAccessToken,
          ),
        ),
        Provider(create: (context) => FlashcardRepository(context.read())),
        ChangeNotifierProvider(
          create: (context) => FlashcardsViewModel(context.read())..loadDecks(),
        ),
      ],
      child: child,
    );
  }
}
