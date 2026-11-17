import 'package:flutter/foundation.dart';

import '../../domain/models/study_preferences.dart';
import '../services/study_service.dart';

class StudyRepository extends ChangeNotifier {
  StudyRepository(this._service, {StudyPreferences? initialPreferences})
    : _initialPreferences = initialPreferences ?? const StudyPreferences();
  final StudyService _service;
  final StudyPreferences _initialPreferences;
  StudyPreferences? _preferences;
  List<FocusSession>? _sessions;
  final Map<String, FocusSession> _recentSessions = {};
  bool _disposed = false;

  StudyPreferences get currentPreferences =>
      _preferences ?? _initialPreferences;
  List<FocusSession> get currentSessions =>
      List.unmodifiable(_sessions ?? const []);

  Future<StudyPreferences> loadPreferences() async {
    final rows = await _service.preferences();
    _preferences = rows.isEmpty
        ? _initialPreferences
        : _preferencesFromRow(rows.single);
    _notify();
    return _preferences!;
  }

  Future<void> savePreferences(StudyPreferences value) async {
    if (value.name.trim().length > 100 ||
        value.goal.trim().isEmpty ||
        value.goal.length > 100 ||
        value.dailyHours < 1 ||
        value.dailyHours > 12 ||
        value.focusMinutes < 1 ||
        value.focusMinutes > 120 ||
        value.shortBreak < 1 ||
        value.shortBreak > 60 ||
        value.longBreak < 1 ||
        value.longBreak > 60 ||
        value.days.isEmpty ||
        value.days.any((day) => day < 1 || day > 7) ||
        !['Manhã', 'Tarde', 'Noite'].contains(value.shift)) {
      throw ArgumentError('Confira o nome, as durações e os dias de estudo.');
    }
    await _service.savePreferences(_preferencesToRow(value));
    _preferences = value;
    _notify();
  }

  Future<List<FocusSession>> loadSessions() async {
    final remote = (await _service.sessions()).map(_sessionFromRow).toList();
    for (final session in remote) {
      _recentSessions.remove(session.id);
    }
    _sessions = [..._recentSessions.values, ...remote];
    _notify();
    return currentSessions;
  }

  Future<void> saveSession(FocusSession value) async {
    await _service.saveSession(_sessionToRow(value));
    if (!(_sessions ?? const <FocusSession>[]).any(
      (session) => session.id == value.id,
    )) {
      _recentSessions[value.id] = value;
      _sessions = [value, ...?_sessions];
      _notify();
    }
  }

  StudyPreferences _preferencesFromRow(Map<String, dynamic> row) =>
      StudyPreferences(
        name: row['nome'] as String,
        goal: row['objetivo'] as String,
        dailyHours: row['horas_diarias'] as int,
        focusMinutes: row['foco_minutos'] as int,
        shortBreak: row['pausa_curta'] as int,
        longBreak: row['pausa_longa'] as int,
        days: List<int>.unmodifiable((row['dias'] as List).cast<int>()),
        shift: row['turno'] as String,
        configured: row['configurado'] as bool,
      );

  Map<String, Object> _preferencesToRow(StudyPreferences value) => {
    'nome': value.name.trim(),
    'objetivo': value.goal,
    'horas_diarias': value.dailyHours,
    'foco_minutos': value.focusMinutes,
    'pausa_curta': value.shortBreak,
    'pausa_longa': value.longBreak,
    'dias': value.days,
    'turno': value.shift,
    'configurado': value.configured,
  };

  FocusSession _sessionFromRow(Map<String, dynamic> row) => FocusSession(
    id: row['id'] as String,
    subjectId: row['disciplina_id'] as int,
    seconds: row['segundos'] as int,
    completedAt: DateTime.parse(row['concluido_em'] as String),
  );

  Map<String, Object> _sessionToRow(FocusSession value) => {
    'id': value.id,
    'disciplina_id': value.subjectId,
    'segundos': value.seconds,
    'concluido_em': value.completedAt.toUtc().toIso8601String(),
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
