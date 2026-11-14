import '../../domain/models/study_preferences.dart';
import '../services/study_service.dart';

class StudyRepository {
  StudyRepository(this._service);
  final StudyService _service;
  Future<StudyPreferences> loadPreferences() async {
    final rows = await _service.preferences();
    return rows.isEmpty
        ? const StudyPreferences()
        : StudyPreferences.fromJson(rows.single);
  }

  Future<void> savePreferences(StudyPreferences value) {
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
    return _service.savePreferences(value.toJson());
  }

  Future<List<FocusSession>> loadSessions() async =>
      (await _service.sessions()).map(FocusSession.fromJson).toList();
  Future<void> saveSession(FocusSession value) =>
      _service.saveSession(value.toJson());
}
