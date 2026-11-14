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
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _hasSubmitted = true);
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
      setState(() {
        _isRegistering = false;
        _hasSubmitted = false;
      });
    }
  }

  void _setMode(bool registering, AuthViewModel viewModel) {
    if (_isRegistering == registering || viewModel.isBusy) return;
    viewModel.clearFeedback();
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _isRegistering = registering;
      _hasSubmitted = false;
      _showPassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _hasSubmitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14001D39),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 42,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Ritmo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF002B52),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'O ritmo ideal para a sua aprovação e alta performance cognitiva.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: const Color(0xFF33628A)),
                      ),
                      const SizedBox(height: 24),
                      _AuthModeSelector(
                        isRegistering: _isRegistering,
                        onSelected: (registering) =>
                            _setMode(registering, viewModel),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10001D39),
                              blurRadius: 22,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isRegistering
                                  ? 'Crie sua conta para começar'
                                  : 'Que bom ter você de volta',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            _FieldLabel(label: 'E-mail'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              enabled: !viewModel.isBusy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              decoration: _decoration(
                                hint: 'seuemail@exemplo.com',
                                icon: Icons.mail_outline_rounded,
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
                            const SizedBox(height: 14),
                            _FieldLabel(label: 'Senha'),
                            const SizedBox(height: 6),
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
                              decoration:
                                  _decoration(
                                    hint: 'Digite sua senha',
                                    icon: Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      tooltip: _showPassword
                                          ? 'Ocultar senha'
                                          : 'Mostrar senha',
                                      onPressed: viewModel.isBusy
                                          ? null
                                          : () => setState(
                                              () => _showPassword =
                                                  !_showPassword,
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
                                  return 'Use pelo menos 6 caracteres.';
                                }
                                return null;
                              },
                            ),
                            if (viewModel.error != null ||
                                viewModel.message != null) ...[
                              const SizedBox(height: 14),
                              _AuthFeedback(
                                text: viewModel.error ?? viewModel.message!,
                                isError: viewModel.error != null,
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: viewModel.isBusy ? null : _submit,
                                child: viewModel.isBusy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isRegistering
                                            ? 'Criar conta'
                                            : 'Entrar',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Ao continuar, seus dados de estudo ficam associados à sua conta.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFF737780)),
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

  InputDecoration _decoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFEFF4FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF0A4174), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _AuthModeSelector extends StatelessWidget {
  const _AuthModeSelector({
    required this.isRegistering,
    required this.onSelected,
  });

  final bool isRegistering;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EEFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _modeButton(
            context,
            label: 'Entrar',
            icon: Icons.login_rounded,
            selected: !isRegistering,
            onTap: () => onSelected(false),
          ),
          _modeButton(
            context,
            label: 'Criar conta',
            icon: Icons.person_add_alt_1_rounded,
            selected: isRegistering,
            onTap: () => onSelected(true),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF002B52) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x18001D39), blurRadius: 8)]
              : null,
        ),
        child: TextButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: selected ? Colors.white : const Color(0xFF42474F),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: const Color(0xFF42474F), fontWeight: FontWeight.w600),
  );
}

class _AuthFeedback extends StatelessWidget {
  const _AuthFeedback({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF0A4174);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
