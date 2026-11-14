import '../../domain/models/question_record.dart';
import '../services/planning_service.dart';

class QuestionRepository {
  const QuestionRepository(this._service);

  final PlanningService _service;
  static const _table = 'registros_questoes';

  Future<List<QuestionRecord>> getRecords({int? subjectId}) async {
    if (subjectId != null && subjectId <= 0) {
      throw ArgumentError.value(subjectId, 'subjectId');
    }
    final rows = await _service.request(
      'GET',
      _table,
      query: {
        if (subjectId != null) 'disciplina_id': 'eq.$subjectId',
        'order': 'realizado_em.desc',
      },
    );
    return rows.map(QuestionRecord.fromJson).toList();
  }

  Future<QuestionRecord> create(QuestionRecord record) async {
    _validate(record);
    return _single(
      await _service.request('POST', _table, body: record.toJson()),
    );
  }

  Future<QuestionRecord> update(QuestionRecord record) async {
    if (record.id <= 0) throw ArgumentError.value(record.id, 'id');
    _validate(record);
    return _single(
      await _service.request(
        'PATCH',
        _table,
        query: {'id': 'eq.${record.id}'},
        body: record.toJson(),
      ),
    );
  }

  Future<void> delete(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    _single(
      await _service.request(
        'DELETE',
        _table,
        query: {'id': 'eq.$id', 'select': 'id'},
      ),
    );
  }

  void _validate(QuestionRecord record) {
    if (record.subjectId <= 0 ||
        record.topicId != null && record.topicId! <= 0 ||
        record.total <= 0 ||
        record.correct < 0 ||
        record.incorrect < 0 ||
        record.total != record.correct + record.incorrect) {
      throw ArgumentError(
        'Confira a disciplina, o tópico e as quantidades de questões.',
      );
    }
  }

  QuestionRecord _single(List<Map<String, dynamic>> rows) {
    if (rows.length != 1) {
      throw const FormatException('Registro de questões não encontrado.');
    }
    return QuestionRecord.fromJson(rows.single);
  }
}
