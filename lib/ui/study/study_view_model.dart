import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/models/study_preferences.dart';

class StudyViewModel extends ChangeNotifier {
  StudyViewModel(this._repository) {
    _repository.addListener(_onRepositoryChanged);
  }
  final StudyRepository _repository;
  StudyPreferences _preferences = const StudyPreferences();
  List<FocusSession> _sessions = [];
  bool busy = false, loaded = false, _disposed = false;
  String? error;
  StudyPreferences get preferences => _preferences;
  List<FocusSession> get sessions => List.unmodifiable(_sessions);
  int get totalSeconds =>
      _sessions.fold(0, (sum, session) => sum + session.seconds);

  List<FocusSession> sessionsOn(DateTime date) => _sessions.where((session) {
    final day = session.completedAt.toLocal();
    return day.year == date.year &&
        day.month == date.month &&
        day.day == date.day;
  }).toList();

  int secondsOn(DateTime date) =>
      sessionsOn(date).fold(0, (total, session) => total + session.seconds);

  double dailyProgress(DateTime date) =>
      (secondsOn(date) / (_preferences.dailyHours * 3600)).clamp(0.0, 1.0);

  String get totalDurationLabel =>
      '${totalSeconds ~/ 3600}h ${((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0')}min';

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
      _sessions = sessions;
      loaded = true;
    } catch (e, st) {
      error = requestErrorMessage(e, stackTrace: st);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> refreshSessions() async {
    final sessions = await _repository.loadSessions();
    if (_disposed) return;
    _sessions = sessions;
    _notify();
  }

  void _onRepositoryChanged() {
    if (_disposed) return;
    _preferences = _repository.currentPreferences;
    _sessions = _repository.currentSessions;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
