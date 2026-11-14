import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo_app/domain/models/daily_question_accuracy.dart';
import 'package:ritmo_app/domain/models/question_record.dart';

void main() {
  QuestionRecord record(int id, DateTime at, int correct, int total) =>
      QuestionRecord(
        id: id,
        subjectId: 1,
        topicId: null,
        total: total,
        correct: correct,
        incorrect: total - correct,
        recordedAt: at,
      );

  test('groups by local day and weights accuracy by question count', () {
    final now = DateTime(2026, 12, 1, 18);
    final result = calculateDailyQuestionAccuracy([
      record(1, DateTime(2026, 11, 30, 9), 1, 2),
      record(2, DateTime(2026, 11, 30, 15), 7, 8),
      record(3, DateTime(2026, 12, 1, 9), 2, 4),
    ], now);

    expect(result.map((day) => day.day.day), [30, 1]);
    expect(result.first.total, 10);
    expect(result.first.correct, 8);
    expect(result.first.accuracy, 0.8);
    expect(result.last.accuracy, 0.5);
  });

  test('keeps only the current day and the preceding 29 days', () {
    final now = DateTime(2026, 12, 1, 18);
    final result = calculateDailyQuestionAccuracy([
      record(1, DateTime(2026, 11, 1, 12), 1, 1),
      record(2, DateTime(2026, 11, 2, 12), 1, 1),
      record(3, DateTime(2026, 12, 2, 12), 1, 1),
    ], now);

    expect(result.length, 1);
    expect(result.single.day, DateTime(2026, 11, 2));
    expect(calculateDailyQuestionAccuracy([], now), isEmpty);
  });
}
