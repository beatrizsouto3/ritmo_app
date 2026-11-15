import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/models/study_preferences.dart';

class StudyViewModel extends ChangeNotifier {
  StudyViewModel(this._repository);
  final StudyRepository _repository;
  StudyPreferences _preferences = const StudyPreferences();
  List<FocusSession> _sessions = [];
  final Map<String, FocusSession> _recentSessions = {};
  bool busy = false, loaded = false, _disposed = false;
  String? error;
  StudyPreferences get preferences => _preferences;
  List<FocusSession> get sessions => List.unmodifiable(_sessions);
  int get totalSeconds =>
      _sessions.fold(0, (sum, session) => sum + session.seconds);

  void recordCompletedSession(FocusSession session) {
    if (_disposed || _sessions.any((saved) => saved.id == session.id)) return;
    _recentSessions[session.id] = session;
    _sessions = [session, ..._sessions];
    _notify();
  }

  Map<int, int> get secondsBySubject {
    final result = <int, int>{};
    for (final session in _sessions) {
      result.update(
        session.subjectId,
        (n) => n + session.seconds,
        ifAbsent: () => session.seconds,
      );
    }
    return result;
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      final preferences = await _repository.loadPreferences();
      final sessions = await _repository.loadSessions();
      if (_disposed) return;
      _preferences = preferences;
      _sessions = _mergeSessions(sessions);
      loaded = true;
    } catch (e, st) {
      error = requestErrorMessage(e, stackTrace: st);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> savePreferences(StudyPreferences value) async {
    if (busy) return false;
    busy = true;
    error = null;
    _notify();
    try {
      await _repository.savePreferences(value);
      if (_disposed) return false;
      _preferences = value;
      loaded = true;
      return true;
    } catch (e, st) {
      error = requestErrorMessage(e, stackTrace: st);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> refreshSessions() async {
    final sessions = await _repository.loadSessions();
    if (_disposed) return;
    _sessions = _mergeSessions(sessions);
    _notify();
  }

  List<FocusSession> _mergeSessions(List<FocusSession> remote) {
    for (final session in remote) {
      _recentSessions.remove(session.id);
    }
    return [..._recentSessions.values, ...remote];
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
