import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../../data/repositories/subject_repository.dart';
import '../../domain/models/daily_question_accuracy.dart';
import '../../domain/models/question_record.dart';
import '../../domain/models/study_preferences.dart';
import '../../domain/models/subject.dart';

class SubjectDuration {
  const SubjectDuration(this.label, this.progress);
  final String label;
  final double progress;
}

class MetricEntry {
  const MetricEntry(this.title, this.subtitle, {this.trailing});
  final String title;
  final String subtitle;
  final String? trailing;
}

class DailyAccuracyEntry {
  const DailyAccuracyEntry(this.label, this.accuracy);
  final String label;
  final double accuracy;
}

class MetricsViewModel extends ChangeNotifier {
  MetricsViewModel(this._study, this._subjects, this._questions) {
    _study.addListener(_onStudyChanged);
    _subjects.addListener(_onSubjectsChanged);
    _questions.addListener(_onQuestionsChanged);
  }

  final StudyRepository _study;
  final SubjectRepository _subjects;
  final QuestionRepository _questions;
  List<Subject> _subjectList = [];
  List<FocusSession> _sessions = [];
  List<QuestionRecord> _records = [];
  bool busy = false;
  bool loaded = false;
  bool _disposed = false;
  String? error;

  String get totalDurationLabel {
    final seconds = _sessions.fold<int>(0, (sum, item) => sum + item.seconds);
    return '${seconds ~/ 3600}h ${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}min';
  }

  int get sessionCount => _sessions.length;

  List<SubjectDuration> get subjectDurations {
    final totals = <int, int>{};
    for (final session in _sessions) {
      totals.update(
        session.subjectId,
        (value) => value + session.seconds,
        ifAbsent: () => session.seconds,
      );
    }
    final maximum = totals.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    return List.unmodifiable([
      for (final subject in _subjectList)
        if (totals.containsKey(subject.id))
          SubjectDuration(
            '${subject.name} · ${(totals[subject.id]! / 60).round()} min',
            totals[subject.id]! / maximum,
          ),
    ]);
  }

  String get questionSummary {
    final total = _records.fold<int>(0, (sum, item) => sum + item.total);
    if (total == 0) return 'Ainda não há questões registradas.';
    final correct = _records.fold<int>(0, (sum, item) => sum + item.correct);
    return '${(correct / total * 100).round()}% de acerto em $total questões.';
  }

  List<DailyAccuracyEntry> dailyAccuracy(DateTime now) => List.unmodifiable(
    calculateDailyQuestionAccuracy(_records, now).map(
      (day) => DailyAccuracyEntry(
        '${_date(day.day)} · ${day.correct}/${day.total} acertos · ${(day.accuracy * 100).round()}%',
        day.accuracy,
      ),
    ),
  );

  List<MetricEntry> get recentQuestions => List.unmodifiable(
    _records
        .take(10)
        .map(
          (record) => MetricEntry(
            '${record.correct}/${record.total} acertos · ${(record.accuracy * 100).round()}%',
            _dateTime(record.recordedAt),
          ),
        ),
  );

  List<MetricEntry> get recentSessions => List.unmodifiable(
    _sessions
        .take(20)
        .map(
          (session) => MetricEntry(
            _subjectList
                    .where((subject) => subject.id == session.subjectId)
                    .map((subject) => subject.name)
                    .firstOrNull ??
                'Disciplina',
            _dateTime(session.completedAt),
            trailing: '${session.seconds ~/ 60} min',
          ),
        ),
  );

  Future<void> load() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _study.loadSessions(),
        _subjects.getSubjects(),
        _questions.getRecords(),
      ]);
      if (_disposed) return;
      _sessions = results[0] as List<FocusSession>;
      _subjectList = results[1] as List<Subject>;
      _records = results[2] as List<QuestionRecord>;
      loaded = true;
    } catch (exception, stackTrace) {
      error = requestErrorMessage(exception, stackTrace: stackTrace);
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _onStudyChanged() {
    if (_disposed) return;
    _sessions = _study.currentSessions;
    notifyListeners();
  }

  void _onQuestionsChanged() {
    if (_disposed) return;
    _records = _questions.currentRecords;
    notifyListeners();
  }

  void _onSubjectsChanged() {
    if (_disposed) return;
    _subjectList = _subjects.currentSubjects;
    notifyListeners();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

  String _dateTime(DateTime value) =>
      value.toLocal().toString().substring(0, 16);

  @override
  void dispose() {
    _disposed = true;
    _study.removeListener(_onStudyChanged);
    _subjects.removeListener(_onSubjectsChanged);
    _questions.removeListener(_onQuestionsChanged);
    super.dispose();
  }
}
