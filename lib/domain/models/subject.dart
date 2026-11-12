class Subject {
  const Subject({required this.id, required this.name});

  final int id;
  final String name;

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome da disciplina.';
    }
    return null;
  }
}
