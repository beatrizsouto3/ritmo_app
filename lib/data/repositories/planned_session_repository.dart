import 'package:flutter/foundation.dart';

import '../../domain/models/planned_session.dart';
import '../services/planning_service.dart';

class PlannedSessionRepository extends ChangeNotifier {
  PlannedSessionRepository(this._service);

  final PlanningService _service;
  static const _table = 'sessoes_planejadas';
  final Map<DateTime, List<PlannedSession>> _weeks = {};
  bool _disposed = false;

  DateTime _weekKey(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - 1));

  List<PlannedSession> currentWeek(DateTime date) =>
      List.unmodifiable(_weeks[_weekKey(date)] ?? const []);

  Future<List<PlannedSession>> getWeek(DateTime weekStart) async {
    final start = _weekKey(weekStart);
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
    final sessions = rows.map(_fromRow).toList();
    _weeks[start] = sessions;
    _notify();
    return sessions;
  }

  Future<bool> hasConflict(PlannedSession session) async {
    _validate(session);
    if (session.status == PlannedSessionStatus.cancelled) return false;
    final filters = [
      'inicio_em.lt.${session.endsAt.toUtc().toIso8601String()}',
      'fim_em.gt.${session.startsAt.toUtc().toIso8601String()}',
      'estado.neq.cancelled',
      if (session.id > 0) 'id.neq.${session.id}',
    ].join(',');
    final rows = await _service.request(
      'GET',
      _table,
      query: {'select': 'id', 'limit': '1', 'and': '($filters)'},
    );
    return rows.isNotEmpty;
  }

  Future<PlannedSession> create(PlannedSession session) async {
    _validate(session);
    final rows = await _service.request('POST', _table, body: _toRow(session));
    final created = _single(rows);
    _replaceCached(created);
    return created;
  }

  Future<PlannedSession> update(PlannedSession session) async {
    if (session.id <= 0) throw ArgumentError.value(session.id, 'id');
    _validate(session);
    final rows = await _service.request(
      'PATCH',
      _table,
      query: {'id': 'eq.${session.id}'},
      body: _toRow(session),
    );
    final updated = _single(rows);
    _replaceCached(updated);
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
      throw const FormatException('Sessão planejada não encontrada.');
    }
    for (final key in _weeks.keys.toList()) {
      _weeks[key] = _weeks[key]!.where((session) => session.id != id).toList();
    }
    _notify();
  }

  void _replaceCached(PlannedSession session) {
    for (final key in _weeks.keys.toList()) {
      final items = _weeks[key]!
          .where((item) => item.id != session.id)
          .toList();
      if (key == _weekKey(session.startsAt.toLocal())) items.add(session);
      items.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      _weeks[key] = items;
    }
    _notify();
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
    return _fromRow(rows.single);
  }

  PlannedSession _fromRow(Map<String, dynamic> row) => PlannedSession(
    id: row['id'] as int,
    subjectId: row['disciplina_id'] as int,
    topicId: row['topico_id'] as int?,
    startsAt: DateTime.parse(row['inicio_em'] as String),
    endsAt: DateTime.parse(row['fim_em'] as String),
    status: PlannedSessionStatus.values.byName(row['estado'] as String),
    notes: row['observacoes'] as String?,
  );

  Map<String, Object?> _toRow(PlannedSession session) => {
    'disciplina_id': session.subjectId,
    'topico_id': session.topicId,
    'inicio_em': session.startsAt.toUtc().toIso8601String(),
    'fim_em': session.endsAt.toUtc().toIso8601String(),
    'estado': session.status.name,
    'observacoes': session.notes,
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
