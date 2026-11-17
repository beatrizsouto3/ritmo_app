class StudyPreferences {
  const StudyPreferences({
    this.name = '',
    this.goal = 'Universidade',
    this.dailyHours = 2,
    this.focusMinutes = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.days = const [1, 2, 3, 4, 5],
    this.shift = 'Manhã',
    this.configured = false,
  });
  final String name, goal, shift;
  final int dailyHours, focusMinutes, shortBreak, longBreak;
  final List<int> days;
  final bool configured;

  StudyPreferences copyWith({
    String? name,
    String? goal,
    String? shift,
    int? dailyHours,
    int? focusMinutes,
    int? shortBreak,
    int? longBreak,
    List<int>? days,
    bool? configured,
  }) => StudyPreferences(
    name: name ?? this.name,
    goal: goal ?? this.goal,
    shift: shift ?? this.shift,
    dailyHours: dailyHours ?? this.dailyHours,
    focusMinutes: focusMinutes ?? this.focusMinutes,
    shortBreak: shortBreak ?? this.shortBreak,
    longBreak: longBreak ?? this.longBreak,
    days: List<int>.unmodifiable(days ?? this.days),
    configured: configured ?? this.configured,
  );
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.subjectId,
    required this.seconds,
    required this.completedAt,
  });
  final String id;
  final int subjectId, seconds;
  final DateTime completedAt;
}
