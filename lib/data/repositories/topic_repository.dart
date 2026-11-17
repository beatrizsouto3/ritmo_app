import 'package:flutter/foundation.dart';

import '../../domain/models/study_topic.dart';
import '../services/topic_contract.dart';
import '../services/topic_service.dart';

class TopicRepository extends ChangeNotifier {
  TopicRepository(this._service);

  final TopicService _service;
  List<StudyTopic>? _allTopics;
  bool _disposed = false;

  List<StudyTopic> get currentTopics =>
      List.unmodifiable(_allTopics ?? const []);

  Future<List<StudyTopic>> getTopics(int subjectId) async {
    if (subjectId <= 0) throw ArgumentError.value(subjectId, 'subjectId');
    final topics = (await _service.fetchTopics(subjectId))
        .map(_fromRow)
        .toList();
    if (_allTopics != null) {
      _allTopics = [
        for (final topic in _allTopics!)
          if (topic.subjectId != subjectId) topic,
        ...topics,
      ];
      _notify();
    }
    return topics;
  }

  Future<List<StudyTopic>> getAllTopics() async {
    _allTopics = (await _service.fetchAllTopics()).map(_fromRow).toList();
    _notify();
    return currentTopics;
  }

  Future<StudyTopic> createTopic({
    required int subjectId,
    required String name,
    int order = 0,
  }) async {
    _validate(subjectId: subjectId, name: name, order: order);
    final created = _fromRow(
      await _service.createTopic(
        subjectId: subjectId,
        name: name.trim(),
        order: order,
      ),
    );
    _replaceCached(created);
    return created;
  }

  Future<StudyTopic> updateTopic(StudyTopic topic) async {
    _validate(subjectId: topic.subjectId, name: topic.name, order: topic.order);
    final updated = _fromRow(
      await _service.updateTopic(
        topicId: topic.id,
        name: topic.name.trim(),
        order: topic.order,
        theoryRead: topic.theoryRead,
        summaryMade: topic.summaryMade,
        exercisesSolved: topic.exercisesSolved,
      ),
    );
    _replaceCached(updated);
    return updated;
  }

  Future<void> deleteTopic(int topicId) async {
    if (topicId <= 0) throw ArgumentError.value(topicId, 'topicId');
    await _service.deleteTopic(topicId);
    if (_allTopics != null) {
      _allTopics = _allTopics!.where((topic) => topic.id != topicId).toList();
      _notify();
    }
  }

  Future<StudyTopic> markReviewed(int topicId) async {
    if (topicId <= 0) throw ArgumentError.value(topicId, 'topicId');
    final reviewed = _fromRow(await _service.markReviewed(topicId));
    _replaceCached(reviewed);
    return reviewed;
  }

  void _replaceCached(StudyTopic topic) {
    if (_allTopics == null) return;
    _allTopics = [
      for (final current in _allTopics!)
        if (current.id != topic.id) current,
      topic,
    ];
    _notify();
  }

  void _validate({
    required int subjectId,
    required String name,
    required int order,
  }) {
    final nameError = StudyTopic.validateName(name);
    if (subjectId <= 0) throw ArgumentError.value(subjectId, 'subjectId');
    if (nameError != null) throw ArgumentError(nameError);
    if (order < 0) throw ArgumentError.value(order, 'order');
  }

  StudyTopic _fromRow(Map<String, Object?> row) {
    return StudyTopic(
      id: _requiredInt(row, TopicContract.idColumn),
      subjectId: _requiredInt(row, TopicContract.subjectIdColumn),
      name: _requiredString(row, TopicContract.nameColumn),
      order: _requiredInt(row, TopicContract.orderColumn),
      theoryRead: _requiredBool(row, TopicContract.theoryReadColumn),
      summaryMade: _requiredBool(row, TopicContract.summaryMadeColumn),
      exercisesSolved: _requiredBool(row, TopicContract.exercisesSolvedColumn),
      lastReviewedAt: switch (row[TopicContract.lastReviewedAtColumn]) {
        String value => DateTime.parse(value),
        null => null,
        _ => throw const FormatException('Data de revisão inválida.'),
      },
    );
  }

  int _requiredInt(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is int) return value;
    throw FormatException('Campo $key inválido na resposta de tópicos.');
  }

  String _requiredString(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is String) return value;
    throw FormatException('Campo $key inválido na resposta de tópicos.');
  }

  bool _requiredBool(Map<String, Object?> row, String key) {
    final value = row[key];
    if (value is bool) return value;
    throw FormatException('Campo $key inválido na resposta de tópicos.');
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
