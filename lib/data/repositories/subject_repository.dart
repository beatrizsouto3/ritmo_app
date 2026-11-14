import '../../domain/models/subject.dart';
import '../services/subject_contract.dart';
import '../services/subject_service.dart';

class SubjectRepository {
  SubjectRepository(this._service);

  final SubjectService _service;

  Future<List<Subject>> getSubjects() async {
    final rows = await _service.getSubjects();
    return rows
        .map(
          (row) => Subject(
            id: row[SubjectContract.idColumn] as int,
            name: row[SubjectContract.nameColumn] as String,
          ),
        )
        .toList();
  }

  Future<Subject> createSubject(String name) async {
    final error = Subject.validateName(name);
    if (error != null) {
      throw ArgumentError(error);
    }
    final normalizedName = name.trim();
    final id = await _service.createSubject(normalizedName);
    return Subject(id: id, name: normalizedName);
  }

  Future<Subject> updateSubject(Subject subject) async {
    if (subject.id <= 0) throw ArgumentError.value(subject.id, 'id');
    final error = Subject.validateName(subject.name);
    if (error != null) throw ArgumentError(error);
    final name = subject.name.trim();
    await _service.updateSubject(subject.id, name);
    return Subject(id: subject.id, name: name);
  }

  Future<void> deleteSubject(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    return _service.deleteSubject(id);
  }
}
