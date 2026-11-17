import 'package:flutter/foundation.dart';

import '../../domain/models/subject.dart';
import '../services/subject_contract.dart';
import '../services/subject_service.dart';

class SubjectRepository extends ChangeNotifier {
  SubjectRepository(this._service);

  final SubjectService _service;
  List<Subject>? _subjects;
  bool _disposed = false;

  List<Subject> get currentSubjects => List.unmodifiable(_subjects ?? const []);

  Future<List<Subject>> getSubjects() async {
    final rows = await _service.getSubjects();
    _subjects = rows
        .map(
          (row) => Subject(
            id: row[SubjectContract.idColumn] as int,
            name: row[SubjectContract.nameColumn] as String,
          ),
        )
        .toList();
    _notify();
    return currentSubjects;
  }

  Future<Subject> createSubject(String name) async {
    final error = Subject.validateName(name);
    if (error != null) {
      throw ArgumentError(error);
    }
    final normalizedName = name.trim();
    final id = await _service.createSubject(normalizedName);
    final created = Subject(id: id, name: normalizedName);
    _subjects = [...?_subjects, created];
    _notify();
    return created;
  }

  Future<Subject> updateSubject(Subject subject) async {
    if (subject.id <= 0) throw ArgumentError.value(subject.id, 'id');
    final error = Subject.validateName(subject.name);
    if (error != null) throw ArgumentError(error);
    final name = subject.name.trim();
    await _service.updateSubject(subject.id, name);
    final updated = Subject(id: subject.id, name: name);
    _subjects = [
      for (final current in _subjects ?? const <Subject>[])
        if (current.id == updated.id) updated else current,
    ];
    _notify();
    return updated;
  }

  Future<void> deleteSubject(int id) async {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    await _service.deleteSubject(id);
    _subjects = (_subjects ?? const <Subject>[])
        .where((subject) => subject.id != id)
        .toList();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
