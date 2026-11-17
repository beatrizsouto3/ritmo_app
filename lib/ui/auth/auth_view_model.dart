import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository) {
    _repository.addListener(_onSessionChanged);
  }

  final AuthRepository _repository;
  bool _isBusy = false;
  bool _isGooglePending = false;
  bool _isDisposed = false;
  String? _error;
  String? _message;

  String? get userId => _repository.userId;
  bool get isAuthenticated => userId != null;
  bool get isRestoring => _repository.isRestoring;
  bool get isBusy => _isBusy;
  bool get isGooglePending => _isGooglePending;
  String? get error => _error ?? _repository.restoreError;
  String? get message => _message;

  Future<bool> signIn(String email, String password) {
    return _run(() => _repository.signIn(email.trim(), password));
  }

  Future<bool> signUp(
    String email,
    String password, {
    String? fullName,
    String? goal,
  }) {
    return _run(() async {
      final authenticated = await _repository.signUp(
        email.trim(),
        password,
        fullName: fullName?.trim(),
        goal: goal,
      );
      if (!authenticated) {
        _message = 'Confira seu e-mail para confirmar o cadastro. Depois, entre na sua conta.';
      }
    });
  }

  Future<bool> signInWithGoogle() {
    return _run(() async {
      _isGooglePending = true;
      try {
        await _repository.signInWithGoogle();
      } on OAuthCanceledException {
        _message = 'Login com Google cancelado.';
      } finally {
        _isGooglePending = false;
      }
    });
  }

  Future<void> cancelGoogleSignIn() async {
    if (!_isGooglePending) return;
    try {
      await _repository.cancelGoogleSignIn();
    } catch (error, stackTrace) {
      _error = requestErrorMessage(error, stackTrace: stackTrace);
      notifyListeners();
    }
  }

  Future<bool> signOut() {
    return _run(() async {
      try {
        await _repository.signOut();
      } catch (error, stackTrace) {
        throw AuthException(
          'Você saiu deste aparelho. Não foi possível encerrar a sessão no servidor. '
          '${requestErrorMessage(error, stackTrace: stackTrace)}',
        );
      }
    });
  }

  void clearFeedback() {
    _error = null;
    _message = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_isBusy) return false;
    _isBusy = true;
    _error = null;
    _message = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      _error = requestErrorMessage(error, stackTrace: stackTrace);
      return false;
    } finally {
      _isBusy = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _onSessionChanged() => notifyListeners();

  @override
  void dispose() {
    _isDisposed = true;
    _repository.removeListener(_onSessionChanged);
    super.dispose();
  }
}
