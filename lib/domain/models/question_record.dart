class QuestionRecord {
  const QuestionRecord({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.recordedAt,
  });

  final int id;
  final int subjectId;
  final int? topicId;
  final int total;
  final int correct;
  final int incorrect;
  final DateTime recordedAt;

  double get accuracy => correct / total;

  factory QuestionRecord.fromJson(Map<String, dynamic> row) => QuestionRecord(
    id: row['id'] as int,
    subjectId: row['disciplina_id'] as int,
    topicId: row['topico_id'] as int?,
    total: row['total'] as int,
    correct: row['acertos'] as int,
    incorrect: row['erros'] as int,
    recordedAt: DateTime.parse(row['realizado_em'] as String),
  );

  Map<String, Object?> toJson() => {
    'disciplina_id': subjectId,
    'topico_id': topicId,
    'total': total,
    'acertos': correct,
    'erros': incorrect,
    'realizado_em': recordedAt.toUtc().toIso8601String(),
  };
}
