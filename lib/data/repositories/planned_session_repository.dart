import '../../domain/models/planned_session.dart';
import '../services/planning_service.dart';

class PlannedSessionRepository {
  const PlannedSessionRepository(this._service);

  final PlanningService _service;
  static const _table = 'sessoes_planejadas';

  Future<List<PlannedSession>> getWeek(DateTime weekStart) async {
    final start = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    ).subtract(Duration(days: weekStart.weekday - 1));
    final end = start.add(const Duration(days: 7));
    final rows = await _service.request(
      'GET',
      _table,
      query: {
        'and':
            '(inicio_em.gte.${start.toUtc().toIso8601String()},inicio_em.lt.${end.toUtc().toIso8601String()})',
        'order': 'inicio_em.asc',
      },
    );
    return rows.map(PlannedSession.fromJson).toList();
  }

  Future<PlannedSession> create(PlannedSession session) async {
    _validate(session);
    final rows = await _service.request('POST', _table, body: session.toJson());
    return _single(rows);
  }

  Future<PlannedSession> update(PlannedSession session) async {
    if (session.id <= 0) throw ArgumentError.value(session.id, 'id');
    _validate(session);
    final rows = await _service.request(
      'PATCH',
      _table,
      query: {'id': 'eq.${session.id}'},
      body: session.toJson(),
    );
    return _single(rows);
  }

  Future<void> delete(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    final rows = await _service.request(
      'DELETE',
      _table,
      query: {'id': 'eq.$id', 'select': 'id'},
    );
    _single(rows);
  }

  void _validate(PlannedSession session) {
    if (session.subjectId <= 0) {
      throw ArgumentError.value(session.subjectId, 'subjectId');
    }
    if (session.topicId != null && session.topicId! <= 0) {
      throw ArgumentError.value(session.topicId, 'topicId');
    }
    if (!session.endsAt.isAfter(session.startsAt)) {
      throw ArgumentError('O término deve ser posterior ao início.');
    }
    if (session.notes != null && session.notes!.length > 500) {
      throw ArgumentError('Use no máximo 500 caracteres nas observações.');
    }
  }

  PlannedSession _single(List<Map<String, dynamic>> rows) {
    if (rows.length != 1) {
      throw const FormatException('Sessão planejada não encontrada.');
    }
    return PlannedSession.fromJson(rows.single);
  }
}
