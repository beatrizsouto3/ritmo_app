import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/ritmo_logo.dart';
import 'auth_view_model.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  static const _goals = [
    'Residência Médica',
    'Concursos Públicos',
    'ENEM / Vestibulares',
    'OAB & Jurídico',
  ];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegistering = false;
  bool _showPassword = false;
  bool _hasSubmitted = false;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordStrength);
  }

  void _refreshPasswordStrength() {
    if (mounted && _isRegistering) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _hasSubmitted = true);
    if (!_formKey.currentState!.validate() ||
        (_isRegistering && _selectedGoal == null)) {
      return;
    }
    final viewModel = context.read<AuthViewModel>();
    final success = _isRegistering
        ? await viewModel.signUp(
            _emailController.text,
            _passwordController.text,
            fullName: _nameController.text,
            goal: _selectedGoal,
          )
        : await viewModel.signIn(
            _emailController.text,
            _passwordController.text,
          );
    if (success && mounted) {
      _passwordController.clear();
      _confirmPasswordController.clear();
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
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isRegistering = registering;
      _hasSubmitted = false;
      _showPassword = false;
      _selectedGoal = null;
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
                          child: const Center(child: RitmoLogo(size: 58)),
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
                            if (_isRegistering) ...[
                              const _FieldLabel(
                                label: 'Qual é a sua meta principal?',
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final goal in _goals)
                                    ChoiceChip(
                                      label: Text(goal),
                                      selected: _selectedGoal == goal,
                                      onSelected: viewModel.isBusy
                                          ? null
                                          : (_) => setState(
                                              () => _selectedGoal = goal,
                                            ),
                                      showCheckmark: false,
                                      backgroundColor: const Color(0xFFE6EEFF),
                                      selectedColor: const Color(0xFFCEE5FF),
                                      side: BorderSide.none,
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF164A70),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              if (_hasSubmitted && _selectedGoal == null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Selecione sua meta principal.',
                                  style: TextStyle(
                                    color: colors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              const _FieldLabel(label: 'Nome completo'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                enabled: !viewModel.isBusy,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: _decoration(
                                  hint: 'Ex: Dra. Helena Silveira',
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (value) =>
                                    (value?.trim().isEmpty ?? true)
                                    ? 'Informe seu nome completo.'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                            const _FieldLabel(label: 'E-mail de estudos'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              enabled: !viewModel.isBusy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              decoration: _decoration(
                                hint: 'seu.nome@exemplo.com',
                                icon: Icons.alternate_email_rounded,
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
                            _FieldLabel(
                              label: _isRegistering ? 'Criar Senha' : 'Senha',
                            ),
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
                              textInputAction: _isRegistering
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted: _isRegistering
                                  ? null
                                  : (_) => _submit(),
                              decoration:
                                  _decoration(
                                    hint: _isRegistering
                                        ? 'Mínimo 8 caracteres'
                                        : 'Digite sua senha',
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
                                if (_isRegistering && value.length < 8) {
                                  return 'Use pelo menos 8 caracteres.';
                                }
                                return null;
                              },
                            ),
                            if (_isRegistering) ...[
                              const SizedBox(height: 8),
                              _PasswordStrength(
                                password: _passwordController.text,
                              ),
                              const SizedBox(height: 14),
                              const _FieldLabel(label: 'Confirmar Senha'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _confirmPasswordController,
                                enabled: !viewModel.isBusy,
                                obscureText: !_showPassword,
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: _decoration(
                                  hint: 'Repita a senha criada',
                                  icon: Icons.lock_clock_outlined,
                                ),
                                validator: (value) =>
                                    value != _passwordController.text
                                    ? 'As senhas não coincidem.'
                                    : null,
                              ),
                            ],
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
                                            ? 'Criar Conta & Calibrar Estudos'
                                            : 'Entrar',
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isRegistering
                            ? 'Próximo passo: definir grade de matérias e ritmo diário'
                            : 'Ao continuar, seus dados de estudo ficam associados à sua conta.',
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
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFF0A4174), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
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

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final score =
        (password.length >= 8 ? 1 : 0) +
        (RegExp(r'[A-Z]').hasMatch(password) &&
                RegExp(r'[a-z]').hasMatch(password)
            ? 1
            : 0) +
        (RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password) ? 1 : 0);
    final label = password.isEmpty
        ? 'Use 8 caracteres ou mais'
        : score == 3
        ? 'Senha forte'
        : score == 2
        ? 'Boa para segurança acadêmica'
        : 'Adicione letras, números e símbolos';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: index < score
                        ? const Color(0xFF0A4174)
                        : const Color(0xFFE6EEFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: const Color(0xFF33628A)),
        ),
      ],
    );
  }
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
