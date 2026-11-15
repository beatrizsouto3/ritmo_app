class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.order,
    required this.theoryRead,
    required this.summaryMade,
    required this.exercisesSolved,
    this.lastReviewedAt,
  });

  final int id;
  final int subjectId;
  final String name;
  final int order;
  final bool theoryRead;
  final bool summaryMade;
  final bool exercisesSolved;
  final DateTime? lastReviewedAt;

  StudyTopic copyWith({
    String? name,
    int? order,
    bool? theoryRead,
    bool? summaryMade,
    bool? exercisesSolved,
  }) {
    return StudyTopic(
      id: id,
      subjectId: subjectId,
      name: name ?? this.name,
      order: order ?? this.order,
      theoryRead: theoryRead ?? this.theoryRead,
      summaryMade: summaryMade ?? this.summaryMade,
      exercisesSolved: exercisesSolved ?? this.exercisesSolved,
      lastReviewedAt: lastReviewedAt,
    );
  }

  int get completedSteps =>
      [theoryRead, summaryMade, exercisesSolved].where((step) => step).length;

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Informe o nome do tópico.';
    if (name.length > 160) return 'Use no máximo 160 caracteres.';
    return null;
  }
}
