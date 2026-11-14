import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/subject_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../domain/models/question_record.dart';
import '../../domain/models/study_topic.dart';
import '../../domain/models/subject.dart';

class QuestionRecordsViewModel extends ChangeNotifier {
  QuestionRecordsViewModel(
    this._questionRepository,
    this._subjectRepository,
    this._topicRepository,
  );

  final QuestionRepository _questionRepository;
  final SubjectRepository _subjectRepository;
  final TopicRepository _topicRepository;

  List<QuestionRecord> _records = [];
  List<Subject> _subjects = [];
  List<StudyTopic> _topics = [];
  final Map<int, List<StudyTopic>> _topicsBySubject = {};
  bool _isLoading = false;
  bool _isLoadingTopics = false;
  bool _isSaving = false;
  bool _disposed = false;
  int _topicRequest = 0;
  String? _loadError;
  String? _topicError;
  String? _saveError;

  List<QuestionRecord> get records => List.unmodifiable(_records);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<StudyTopic> get topics => List.unmodifiable(_topics);
  bool get isLoading => _isLoading;
  bool get isLoadingTopics => _isLoadingTopics;
  bool get isSaving => _isSaving;
  String? get loadError => _loadError;
  String? get topicError => _topicError;
  String? get saveError => _saveError;
  int get totalQuestions =>
      _records.fold(0, (sum, record) => sum + record.total);
  int get correctAnswers =>
      _records.fold(0, (sum, record) => sum + record.correct);
  double get accuracy =>
      totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;

  String subjectName(int subjectId) =>
      _subjects
          .where((subject) => subject.id == subjectId)
          .map((subject) => subject.name)
          .firstOrNull ??
      'Disciplina';

  String? topicName(int? subjectId, int? topicId) {
    if (topicId == null) return null;
    return _topicsBySubject[subjectId]
            ?.where((topic) => topic.id == topicId)
            .map((topic) => topic.name)
            .firstOrNull ??
        'Tópico';
  }

  Future<void> load() async {
    if (_isLoading || _isSaving) return;
    _isLoading = true;
    _loadError = null;
    _notify();
    try {
      _subjects = await _subjectRepository.getSubjects();
      if (_disposed) return;
    } catch (error, stackTrace) {
      _loadError = requestErrorMessage(
        error,
        stackTrace: stackTrace,
        fallback: 'Não foi possível carregar as disciplinas.',
      );
    }
    if (_subjects.isNotEmpty) {
      try {
        _records = await _questionRepository.getRecords();
      } catch (error, stackTrace) {
        _loadError ??= requestErrorMessage(
          error,
          stackTrace: stackTrace,
          fallback: 'Não foi possível carregar os registros de questões.',
        );
      }
    }
    try {
      final topicsBySubject = <int, List<StudyTopic>>{};
      await Future.wait(
        _subjects.map((subject) async {
          try {
            topicsBySubject[subject.id] = await _topicRepository.getTopics(
              subject.id,
            );
          } catch (_) {
            // Keep failed loads uncached so selecting the subject can retry.
          }
        }),
      );
      if (_disposed) return;
      _topicsBySubject
        ..clear()
        ..addAll(topicsBySubject);
    } catch (error, stackTrace) {
      _loadError ??= requestErrorMessage(
        error,
        stackTrace: stackTrace,
        fallback: 'Não foi possível preparar os dados de questões.',
      );
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> loadTopics(int? subjectId) async {
    final request = ++_topicRequest;
    _topics = [];
    _topicError = null;
    if (subjectId == null) {
      _isLoadingTopics = false;
      _notify();
      return;
    }
    _isLoadingTopics = true;
    _notify();
    try {
      final topics =
          _topicsBySubject[subjectId] ??
          await _topicRepository.getTopics(subjectId);
      if (_disposed || request != _topicRequest) return;
      _topics = topics;
      _topicsBySubject[subjectId] = topics;
    } catch (error, stackTrace) {
      if (_disposed || request != _topicRequest) return;
      _topicError = requestErrorMessage(
        error,
        stackTrace: stackTrace,
        fallback: 'Não foi possível carregar os tópicos desta disciplina.',
      );
    } finally {
      if (!_disposed && request == _topicRequest) {
        _isLoadingTopics = false;
        _notify();
      }
    }
  }

  void clearSaveError() {
    _saveError = null;
    _notify();
  }

  Future<bool> createRecord({
    required int subjectId,
    required int? topicId,
    required int total,
    required int correct,
    required int incorrect,
    required DateTime recordedAt,
  }) async {
    if (_isSaving || _isLoading) return false;
    _saveError = _validate(
      subjectId: subjectId,
      total: total,
      correct: correct,
      incorrect: incorrect,
    );
    if (_saveError != null) {
      _notify();
      return false;
    }
    _isSaving = true;
    _notify();
    try {
      final record = await _questionRepository.create(
        QuestionRecord(
          id: 0,
          subjectId: subjectId,
          topicId: topicId,
          total: total,
          correct: correct,
          incorrect: incorrect,
          recordedAt: recordedAt,
        ),
      );
      if (_disposed) return false;
      _records = [record, ..._records];
      return true;
    } catch (error, stackTrace) {
      _saveError = requestErrorMessage(
        error,
        stackTrace: stackTrace,
        fallback: 'Não foi possível salvar o registro. Tente novamente.',
      );
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  String? _validate({
    required int subjectId,
    required int total,
    required int correct,
    required int incorrect,
  }) {
    if (subjectId <= 0) return 'Selecione uma disciplina.';
    if (total < 1) return 'Informe um total maior que zero.';
    if (correct < 0 || incorrect < 0) {
      return 'Acertos e erros não podem ser negativos.';
    }
    if (correct + incorrect != total) {
      return 'O total deve ser igual à soma de acertos e erros.';
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _topicRequest++;
    super.dispose();
  }
}
