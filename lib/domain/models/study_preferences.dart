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

  factory StudyPreferences.fromJson(Map<String, dynamic> json) =>
      StudyPreferences(
        name: json['nome'] as String,
        goal: json['objetivo'] as String,
        dailyHours: json['horas_diarias'] as int,
        focusMinutes: json['foco_minutos'] as int,
        shortBreak: json['pausa_curta'] as int,
        longBreak: json['pausa_longa'] as int,
        days: List<int>.unmodifiable((json['dias'] as List).cast<int>()),
        shift: json['turno'] as String,
        configured: json['configurado'] as bool,
      );

  Map<String, Object> toJson() => {
    'nome': name.trim(),
    'objetivo': goal,
    'horas_diarias': dailyHours,
    'foco_minutos': focusMinutes,
    'pausa_curta': shortBreak,
    'pausa_longa': longBreak,
    'dias': days,
    'turno': shift,
    'configurado': configured,
  };

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
  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'] as String,
    subjectId: json['disciplina_id'] as int,
    seconds: json['segundos'] as int,
    completedAt: DateTime.parse(json['concluido_em'] as String),
  );
  Map<String, Object> toJson() => {
    'id': id,
    'disciplina_id': subjectId,
    'segundos': seconds,
    'concluido_em': completedAt.toUtc().toIso8601String(),
  };
}
