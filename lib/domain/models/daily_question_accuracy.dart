import 'question_record.dart';

class DailyQuestionAccuracy {
  const DailyQuestionAccuracy({
    required this.day,
    required this.correct,
    required this.total,
  });

  final DateTime day;
  final int correct;
  final int total;

  double get accuracy => correct / total;
}

List<DailyQuestionAccuracy> calculateDailyQuestionAccuracy(
  Iterable<QuestionRecord> records,
  DateTime now,
) {
  final firstDay = DateTime(now.year, now.month, now.day - 29);
  final lastDay = DateTime(now.year, now.month, now.day);
  final totalsByDay = <DateTime, (int, int)>{};
  for (final record in records) {
    final local = record.recordedAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (day.isBefore(firstDay) || day.isAfter(lastDay)) continue;
    final previous = totalsByDay[day] ?? (0, 0);
    totalsByDay[day] = (
      previous.$1 + record.correct,
      previous.$2 + record.total,
    );
  }
  final days = totalsByDay.keys.toList()..sort();
  return days.map((day) {
    final totals = totalsByDay[day]!;
    return DailyQuestionAccuracy(
      day: day,
      correct: totals.$1,
      total: totals.$2,
    );
  }).toList();
}
