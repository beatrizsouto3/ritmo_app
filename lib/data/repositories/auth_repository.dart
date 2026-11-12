import 'package:flutter/foundation.dart';

import '../../domain/models/auth_session.dart';
import '../services/auth_service.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository(this._service);

  final AuthService _service;
  AuthSession? _session;
  Future<String>? _refreshing;
  bool _isDisposed = false;

  String? get userId => _session?.userId;

  Future<void> signIn(String email, String password) async {
    _setSession(await _service.signIn(email, password));
  }

  Future<bool> signUp(String email, String password) async {
    final session = await _service.signUp(email, password);
    if (session != null) _setSession(session);
    return session != null;
  }

  Future<void> signOut() async {
    final session = _session;
    _setSession(null);
    if (session != null) await _service.signOut(session.accessToken);
  }

  Future<String> getAccessToken() async {
    final session = _session;
    if (session == null) {
      throw const AuthException('Entre na sua conta para continuar.');
    }
    if (session.expiresAt.isAfter(
      DateTime.now().add(const Duration(seconds: 30)),
    )) {
      return session.accessToken;
    }
    final pending = _refreshing ??= _refresh(session);
    try {
      return await pending;
    } finally {
      if (identical(_refreshing, pending)) _refreshing = null;
    }
  }

  Future<String> _refresh(AuthSession previous) async {
    try {
      final session = await _service.refreshSession(previous.refreshToken);
      if (_isDisposed || !identical(_session, previous)) {
        throw const AuthException('A sessão foi alterada. Entre novamente.');
      }
      _setSession(session);
      return session.accessToken;
    } on AuthException catch (error) {
      if (identical(_session, previous) &&
          [400, 401, 403].contains(error.statusCode)) {
        _setSession(null);
      }
      rethrow;
    }
  }

  void _setSession(AuthSession? session) {
    if (_isDisposed) return;
    _session = session;
    _refreshing = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _session = null;
    super.dispose();
  }
}
