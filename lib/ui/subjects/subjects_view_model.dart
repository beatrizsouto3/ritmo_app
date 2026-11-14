import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/subject_repository.dart';
import '../../domain/models/subject.dart';

class SubjectsViewModel extends ChangeNotifier {
  SubjectsViewModel(this._repository);

  final SubjectRepository _repository;
  List<Subject> _subjects = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;
  bool _isDisposed = false;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get loadError => _loadError;
  String? get saveError => _saveError;

  Future<void> loadSubjects() async {
    if (_isLoading || _isSaving) return;
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      final subjects = await _repository.getSubjects();
      if (!_isDisposed) _subjects = subjects;
    } catch (error, stackTrace) {
      _loadError = requestErrorMessage(
        error,
        stackTrace: stackTrace,
        fallback: 'Não foi possível carregar as disciplinas. Tente novamente.',
      );
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void clearSaveError() {
    _saveError = null;
    notifyListeners();
  }

  Future<bool> createSubject(String name) async {
    if (_isSaving || _isLoading || _loadError != null) return false;
    _saveError = Subject.validateName(name);
    if (_saveError != null) {
      notifyListeners();
      return false;
    }
    _isSaving = true;
    notifyListeners();
    try {
      final subject = await _repository.createSubject(name);
      if (_isDisposed) return false;
      _subjects = [..._subjects, subject];
      return true;
    } catch (error, stackTrace) {
      _saveError = requestErrorMessage(
        error,
        stackTrace: stackTrace,
        fallback: 'Não foi possível salvar a disciplina. Tente novamente.',
      );
      return false;
    } finally {
      _isSaving = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subjects = [];
    super.dispose();
  }
}
