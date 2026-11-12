import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_view_model.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<AuthViewModel>();
    final success = _isRegistering
        ? await viewModel.signUp(
            _emailController.text,
            _passwordController.text,
          )
        : await viewModel.signIn(
            _emailController.text,
            _passwordController.text,
          );
    if (success && mounted) {
      _passwordController.clear();
      setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ritmo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegistering
                            ? 'Crie sua conta para organizar os estudos.'
                            : 'Entre para acessar suas disciplinas.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        enabled: !viewModel.isBusy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(email)) {
                            return 'Informe um e-mail válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !viewModel.isBusy,
                        obscureText: !_showPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: [
                          _isRegistering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Ocultar senha'
                                : 'Mostrar senha',
                            onPressed: viewModel.isBusy
                                ? null
                                : () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe sua senha.';
                          }
                          if (_isRegistering && value.length < 6) {
                            return 'Use uma senha com pelo menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      if (viewModel.error != null ||
                          viewModel.message != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            viewModel.error ?? viewModel.message!,
                            style: TextStyle(
                              color: viewModel.error != null
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: viewModel.isBusy ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            viewModel.isBusy
                                ? 'Aguarde…'
                                : _isRegistering
                                ? 'Criar conta'
                                : 'Entrar',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: viewModel.isBusy
                            ? null
                            : () {
                                viewModel.clearFeedback();
                                _formKey.currentState!.reset();
                                _passwordController.clear();
                                setState(
                                  () => _isRegistering = !_isRegistering,
                                );
                              },
                        child: Text(
                          _isRegistering ? 'Já tenho conta' : 'Criar uma conta',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
