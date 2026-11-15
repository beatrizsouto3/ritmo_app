import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/models/auth_session.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository(this._service, {SessionStore? sessionStore})
    : _store = sessionStore;

  final AuthService _service;
  final SessionStore? _store;
  AuthSession? _session;
  Future<String>? _refreshing;
  Future<void> _storageQueue = Future.value();
  bool _isDisposed = false;
  bool isRestoring = false;
  String? restoreError;
  int _revision = 0;

  String? get userId => _session?.userId;

  Future<void> restoreSession() async {
    if (_store == null || isRestoring || _isDisposed) return;
    isRestoring = true;
    restoreError = null;
    notifyListeners();
    try {
      final saved = await _store.read();
      if (saved == null || _isDisposed) return;
      try {
        final data = Map<String, Object?>.from(jsonDecode(saved) as Map);
        _setSession(AuthSession.fromStoredJson(data));
      } on FormatException {
        await _persist(null);
        return;
      } on TypeError {
        await _persist(null);
        return;
      }
      try {
        await getAccessToken();
      } on AuthException {
        if (_session == null) return;
      }
    } catch (_) {
      restoreError =
          'Não foi possível recuperar a sessão salva neste aparelho.';
    } finally {
      isRestoring = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    final revision = _revision;
    await _activate(await _service.signIn(email, password), revision);
  }

  Future<bool> signUp(String email, String password) async {
    final revision = _revision;
    final session = await _service.signUp(email, password);
    if (session != null) await _activate(session, revision);
    return session != null;
  }

  Future<void> signOut() async {
    final session = _session;
    _revision++;
    restoreError = null;
    _setSession(null);
    await _persist(null);
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
      await _persist(session);
      if (_isDisposed || !identical(_session, previous)) {
        throw const AuthException('A sessão foi alterada. Entre novamente.');
      }
      _setSession(session);
      return session.accessToken;
    } on AuthException catch (error) {
      if (identical(_session, previous) &&
          [400, 401, 403].contains(error.statusCode)) {
        _setSession(null);
        await _persist(null);
      }
      rethrow;
    }
  }

  Future<void> _activate(AuthSession session, int revision) async {
    if (_isDisposed || revision != _revision) {
      throw const AuthException('A sessão foi alterada. Entre novamente.');
    }
    await _persist(session);
    if (_isDisposed || revision != _revision) {
      await _persist(null);
      throw const AuthException('A sessão foi alterada. Entre novamente.');
    }
    restoreError = null;
    _setSession(session);
  }

  Future<void> _persist(AuthSession? session) async {
    final store = _store;
    if (store == null) return;
    _storageQueue = _storageQueue
        .catchError((Object _) {})
        .then(
          (_) => session == null
              ? store.clear()
              : store.write(jsonEncode(session.toStoredJson())),
        );
    await _storageQueue;
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
