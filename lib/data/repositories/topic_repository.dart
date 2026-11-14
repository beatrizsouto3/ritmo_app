import '../../domain/models/study_topic.dart';
import '../services/topic_contract.dart';
import '../services/topic_service.dart';

class TopicRepository {
  const TopicRepository(this._service);

  final TopicService _service;

  Future<List<StudyTopic>> getTopics(int subjectId) async {
    if (subjectId <= 0) throw ArgumentError.value(subjectId, 'subjectId');
    return (await _service.fetchTopics(subjectId)).map(_fromRow).toList();
  }

  Future<List<StudyTopic>> getAllTopics() async =>
      (await _service.fetchAllTopics()).map(_fromRow).toList();

  Future<StudyTopic> createTopic({
    required int subjectId,
    required String name,
    int order = 0,
  }) async {
    _validate(subjectId: subjectId, name: name, order: order);
    return _fromRow(
      await _service.createTopic(
        subjectId: subjectId,
        name: name.trim(),
        order: order,
      ),
    );
  }

  Future<StudyTopic> updateTopic(StudyTopic topic) async {
    _validate(subjectId: topic.subjectId, name: topic.name, order: topic.order);
    return _fromRow(
      await _service.updateTopic(
        topicId: topic.id,
        name: topic.name.trim(),
        order: topic.order,
        theoryRead: topic.theoryRead,
        summaryMade: topic.summaryMade,
        exercisesSolved: topic.exercisesSolved,
      ),
    );
  }

  Future<void> deleteTopic(int topicId) {
    if (topicId <= 0) throw ArgumentError.value(topicId, 'topicId');
    return _service.deleteTopic(topicId);
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
}
