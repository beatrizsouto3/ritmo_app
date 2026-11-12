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
}
