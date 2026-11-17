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
}
