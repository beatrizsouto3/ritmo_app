import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/planned_session_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../../domain/models/planned_session.dart';
import '../../domain/models/question_record.dart';
import '../../domain/models/daily_question_accuracy.dart';
import '../../domain/models/study_topic.dart';

class UrgentTopic {
  const UrgentTopic(this.topic, this.reason);
  final StudyTopic topic;
  final String reason;
}

class DashboardMetricsViewModel extends ChangeNotifier {
  DashboardMetricsViewModel(this._questions, this._topics, this._planned);

  final QuestionRepository _questions;
  final TopicRepository _topics;
  final PlannedSessionRepository _planned;
  List<QuestionRecord> _records = [];
  List<StudyTopic> _allTopics = [];
  List<PlannedSession> _week = [];
  bool busy = false;
  bool loaded = false;
  bool _disposed = false;
  String? error;

  List<QuestionRecord> get records => List.unmodifiable(_records);
  List<PlannedSession> get week => List.unmodifiable(_week);

  int get totalQuestions => _records.fold(0, (sum, row) => sum + row.total);
  int get totalCorrect => _records.fold(0, (sum, row) => sum + row.correct);
  double? get accuracy =>
      totalQuestions == 0 ? null : totalCorrect / totalQuestions;

  List<DailyQuestionAccuracy> dailyAccuracy(DateTime now) =>
      calculateDailyQuestionAccuracy(_records, now);

  List<PlannedSession> sessionsToday(DateTime now) => _week.where((row) {
    final day = row.startsAt.toLocal();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day &&
        row.status == PlannedSessionStatus.planned;
  }).toList();

  List<UrgentTopic> urgentTopics(DateTime now) {
    final cutoff = now.subtract(const Duration(days: 7));
    final result = <UrgentTopic>[];
    for (final topic in _allTopics) {
      final records = _records.where((row) => row.topicId == topic.id).toList();
      final total = records.fold(0, (sum, row) => sum + row.total);
      final correct = records.fold(0, (sum, row) => sum + row.correct);
      final accuracy = total == 0 ? null : correct / total;
      final lastReviewedAt = topic.lastReviewedAt;
      final overdue = lastReviewedAt == null || lastReviewedAt.isBefore(cutoff);
      if (accuracy == null || accuracy < 0.7 || overdue) {
        final reason = accuracy == null
            ? 'Sem questões registradas'
            : accuracy < 0.7
            ? '${(accuracy * 100).round()}% de acerto (abaixo de 70%)'
            : lastReviewedAt == null
            ? 'Ainda não revisado'
            : 'Última revisão há mais de 7 dias';
        result.add(UrgentTopic(topic, reason));
      }
    }
    return result;
  }

  Future<void> load() async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _questions.getRecords(),
        _topics.getAllTopics(),
        _planned.getWeek(DateTime.now()),
      ]);
      if (_disposed) return;
      _records = results[0] as List<QuestionRecord>;
      _allTopics = results[1] as List<StudyTopic>;
      _week = results[2] as List<PlannedSession>;
      loaded = true;
    } catch (e, st) {
      error = requestErrorMessage(e, stackTrace: st);
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
