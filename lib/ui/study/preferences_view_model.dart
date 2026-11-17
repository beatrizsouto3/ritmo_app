import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/models/study_preferences.dart';

class PreferencesViewModel extends ChangeNotifier {
  PreferencesViewModel(this._repository)
    : draft = _repository.currentPreferences;
  final StudyRepository _repository;
  StudyPreferences draft;
  int step = 0;
  bool saving = false;
  String? error;
  bool _disposed = false;
  void change(StudyPreferences value) {
    draft = value;
    error = null;
    notifyListeners();
  }

  void go(int value) {
    step = value;
    notifyListeners();
  }

  Future<bool> save({bool complete = false}) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.savePreferences(
        draft.copyWith(configured: complete || draft.configured),
      );
      return true;
    } catch (exception, stackTrace) {
      error = requestErrorMessage(exception, stackTrace: stackTrace);
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
