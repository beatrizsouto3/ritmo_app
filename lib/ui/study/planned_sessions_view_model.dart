import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/planned_session_repository.dart';
import '../../data/repositories/subject_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../domain/models/planned_session.dart';
import '../../domain/models/study_topic.dart';
import '../../domain/models/subject.dart';

class PlannedSessionsViewModel extends ChangeNotifier {
  PlannedSessionsViewModel(
    this._repository,
    this._subjectsRepository,
    this._topicsRepository,
  ) : weekStart = _monday(DateTime.now()) {
    _repository.addListener(_onSessionsChanged);
    _subjectsRepository.addListener(_onSubjectsChanged);
  }

  final PlannedSessionRepository _repository;
  final SubjectRepository _subjectsRepository;
  final TopicRepository _topicsRepository;
  DateTime weekStart;
  List<PlannedSession> sessions = [];
  List<Subject> subjects = [];
  List<StudyTopic> topics = [];
  bool loading = false;
  bool saving = false;
  bool loadingTopics = false;
  String? error;
  String? actionError;
  String? topicError;
  bool _disposed = false;
  int _topicRequest = 0;

  static DateTime _monday(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day,
  ).subtract(Duration(days: day.weekday - 1));

  String subjectName(int id) =>
      subjects.where((s) => s.id == id).map((s) => s.name).firstOrNull ??
      'Disciplina';

  Future<void> load() async {
    if (loading || saving) return;
    loading = true;
    error = null;
    _notify();
    try {
      await Future.wait<Object>([
        _repository.getWeek(weekStart),
        _subjectsRepository.getSubjects(),
      ]);
      if (_disposed) return;
      sessions = _repository.currentWeek(weekStart);
      subjects = _subjectsRepository.currentSubjects;
    } catch (e, st) {
      error = requestErrorMessage(e, stackTrace: st);
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> changeWeek(int weeks) async {
    if (loading || saving) return;
    weekStart = weekStart.add(Duration(days: weeks * 7));
    await load();
  }

  Future<void> loadTopics(int? subjectId) async {
    final request = ++_topicRequest;
    topics = [];
    topicError = null;
    if (subjectId == null) {
      loadingTopics = false;
      _notify();
      return;
    }
    loadingTopics = true;
    _notify();
    try {
      final loaded = await _topicsRepository.getTopics(subjectId);
      if (_disposed || request != _topicRequest) return;
      topics = loaded;
    } catch (e, st) {
      if (_disposed || request != _topicRequest) return;
      topicError = requestErrorMessage(e, stackTrace: st);
    } finally {
      if (!_disposed && request == _topicRequest) {
        loadingTopics = false;
        _notify();
      }
    }
  }

  Future<bool> save(PlannedSession value) async {
    if (saving || loading) return false;
    actionError = null;
    if (value.subjectId <= 0 || !value.endsAt.isAfter(value.startsAt)) {
      actionError = 'Confira a disciplina e o horário da sessão.';
    } else if (value.status != PlannedSessionStatus.cancelled &&
        sessions.any(
          (other) =>
              other.id != value.id &&
              other.status != PlannedSessionStatus.cancelled &&
              value.startsAt.isBefore(other.endsAt) &&
              value.endsAt.isAfter(other.startsAt),
        )) {
      actionError = 'Já existe uma sessão nesse horário.';
    }
    if (actionError != null) {
      _notify();
      return false;
    }
    saving = true;
    _notify();
    try {
      if (await _repository.hasConflict(value)) {
        actionError = 'Já existe uma sessão nesse horário.';
        return false;
      }
      value.id == 0
          ? await _repository.create(value)
          : await _repository.update(value);
      if (_disposed) return false;
      sessions = _repository.currentWeek(weekStart);
      return true;
    } catch (e, st) {
      actionError = requestErrorMessage(e, stackTrace: st);
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<bool> setStatus(PlannedSession value, PlannedSessionStatus status) =>
      save(
        PlannedSession(
          id: value.id,
          subjectId: value.subjectId,
          topicId: value.topicId,
          startsAt: value.startsAt,
          endsAt: value.endsAt,
          status: status,
          notes: value.notes,
        ),
      );

  Future<bool> delete(int id) async {
    if (saving || loading) return false;
    saving = true;
    actionError = null;
    _notify();
    try {
      await _repository.delete(id);
      if (_disposed) return false;
      sessions = _repository.currentWeek(weekStart);
      return true;
    } catch (e, st) {
      actionError = requestErrorMessage(e, stackTrace: st);
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onSessionsChanged() {
    if (_disposed) return;
    sessions = _repository.currentWeek(weekStart);
    _notify();
  }

  void _onSubjectsChanged() {
    if (_disposed) return;
    subjects = _subjectsRepository.currentSubjects;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _repository.removeListener(_onSessionsChanged);
    _subjectsRepository.removeListener(_onSubjectsChanged);
    _topicRequest++;
    super.dispose();
  }
}
