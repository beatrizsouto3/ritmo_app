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
}
