import 'package:flutter/foundation.dart';

import '../../domain/models/question_record.dart';
import '../services/planning_service.dart';

class QuestionRepository extends ChangeNotifier {
  QuestionRepository(this._service);

  final PlanningService _service;
  static const _table = 'registros_questoes';
  List<QuestionRecord>? _records;
  bool _disposed = false;

  List<QuestionRecord> get currentRecords =>
      List.unmodifiable(_records ?? const []);

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
    final records = rows.map(_fromRow).toList();
    if (subjectId == null) {
      _records = records;
      _notify();
    }
    return records;
  }

  Future<QuestionRecord> create(QuestionRecord record) async {
    _validate(record);
    final created = _single(
      await _service.request('POST', _table, body: _toRow(record)),
    );
    if (_records != null) {
      _records = [created, ..._records!];
      _notify();
    }
    return created;
  }

  Future<QuestionRecord> update(QuestionRecord record) async {
    if (record.id <= 0) throw ArgumentError.value(record.id, 'id');
    _validate(record);
    final updated = _single(
      await _service.request(
        'PATCH',
        _table,
        query: {'id': 'eq.${record.id}'},
        body: _toRow(record),
      ),
    );
    if (_records != null) {
      _records = [
        for (final current in _records!)
          if (current.id == updated.id) updated else current,
      ]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      _notify();
    }
    return updated;
  }

  Future<void> delete(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    final rows = await _service.request(
      'DELETE',
      _table,
      query: {'id': 'eq.$id', 'select': 'id'},
    );
    if (rows.length != 1 || rows.single['id'] != id) {
      throw const FormatException('Registro de questões não encontrado.');
    }
    if (_records != null) {
      _records = _records!.where((record) => record.id != id).toList();
      _notify();
    }
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
    return _fromRow(rows.single);
  }

  QuestionRecord _fromRow(Map<String, dynamic> row) => QuestionRecord(
    id: row['id'] as int,
    subjectId: row['disciplina_id'] as int,
    topicId: row['topico_id'] as int?,
    total: row['total'] as int,
    correct: row['acertos'] as int,
    incorrect: row['erros'] as int,
    recordedAt: DateTime.parse(row['realizado_em'] as String),
  );

  Map<String, Object?> _toRow(QuestionRecord record) => {
    'disciplina_id': record.subjectId,
    'topico_id': record.topicId,
    'total': record.total,
    'acertos': record.correct,
    'erros': record.incorrect,
    'realizado_em': record.recordedAt.toUtc().toIso8601String(),
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
