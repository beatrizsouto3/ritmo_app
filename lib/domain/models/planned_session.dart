enum PlannedSessionStatus { planned, completed, cancelled }

class PlannedSession {
  const PlannedSession({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.notes,
  });

  final int id;
  final int subjectId;
  final int? topicId;
  final DateTime startsAt;
  final DateTime endsAt;
  final PlannedSessionStatus status;
  final String? notes;

  factory PlannedSession.fromJson(Map<String, dynamic> row) => PlannedSession(
    id: row['id'] as int,
    subjectId: row['disciplina_id'] as int,
    topicId: row['topico_id'] as int?,
    startsAt: DateTime.parse(row['inicio_em'] as String),
    endsAt: DateTime.parse(row['fim_em'] as String),
    status: PlannedSessionStatus.values.byName(row['estado'] as String),
    notes: row['observacoes'] as String?,
  );

  Map<String, Object?> toJson() => {
    'disciplina_id': subjectId,
    'topico_id': topicId,
    'inicio_em': startsAt.toUtc().toIso8601String(),
    'fim_em': endsAt.toUtc().toIso8601String(),
    'estado': status.name,
    'observacoes': notes,
  };
}
