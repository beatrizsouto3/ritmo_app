import 'package:flutter/foundation.dart';

import '../../data/repositories/topic_repository.dart';
import '../../domain/models/study_topic.dart';

class TopicsViewModel extends ChangeNotifier {
  TopicsViewModel(this._repository, this.subjectId) {
    if (subjectId <= 0) throw ArgumentError.value(subjectId, 'subjectId');
  }

  final TopicRepository _repository;
  final int subjectId;
  List<StudyTopic> _topics = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;
  bool _disposed = false;

  List<StudyTopic> get topics => List.unmodifiable(_topics);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadError => _loadError;
  String? get saveError => _saveError;

  int get completedCount =>
      _topics.where((topic) => topic.completedSteps == 3).length;

  double get progress => _topics.isEmpty
      ? 0
      : _topics.fold<int>(0, (sum, topic) => sum + topic.completedSteps) /
            (_topics.length * 3);

  Future<void> loadTopics() async {
    if (_isLoading || _isSaving) return;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final result = await _repository.getTopics(subjectId);
      if (!_disposed) _topics = result;
    } catch (_) {
      _loadError = 'Não foi possível carregar os tópicos. Tente novamente.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clearSaveError() {
    _saveError = null;
    notifyListeners();
  }

  Future<bool> createTopic(String name) async {
    final validation = StudyTopic.validateName(name);
    if (validation != null) {
      _saveError = validation;
      notifyListeners();
      return false;
    }
    if (_isSaving || _isLoading || _loadError != null) return false;
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final topic = await _repository.createTopic(
        subjectId: subjectId,
        name: name,
        order: _topics.length,
      );
      if (_disposed) return false;
      _topics = [..._topics, topic];
      return true;
    } catch (_) {
      _saveError = 'Não foi possível salvar o tópico. Tente novamente.';
      return false;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> updateTopic(StudyTopic topic) async {
    if (_isSaving || _isLoading) return false;
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final updated = await _repository.updateTopic(topic);
      if (_disposed) return false;
      _topics = [
        for (final current in _topics)
          if (current.id == updated.id) updated else current,
      ];
      return true;
    } catch (_) {
      _saveError = 'Não foi possível atualizar o tópico. Tente novamente.';
      return false;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> deleteTopic(int topicId) async {
    if (_isSaving || _isLoading) return false;
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      await _repository.deleteTopic(topicId);
      if (_disposed) return false;
      _topics = _topics.where((topic) => topic.id != topicId).toList();
      return true;
    } catch (_) {
      _saveError = 'Não foi possível excluir o tópico. Tente novamente.';
      return false;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> markReviewed(int topicId) async {
    if (_isSaving || _isLoading) return false;
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final updated = await _repository.markReviewed(topicId);
      if (_disposed) return false;
      _topics = [
        for (final topic in _topics)
          if (topic.id == updated.id) updated else topic,
      ];
      return true;
    } catch (_) {
      _saveError = 'Não foi possível registrar a revisão. Tente novamente.';
      return false;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _topics = [];
    super.dispose();
  }
}
