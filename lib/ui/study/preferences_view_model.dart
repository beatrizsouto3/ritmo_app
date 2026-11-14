import 'package:flutter/foundation.dart';

import '../../domain/models/study_preferences.dart';
import 'study_view_model.dart';

class PreferencesViewModel extends ChangeNotifier {
  PreferencesViewModel(this.source) : draft = source.preferences;
  final StudyViewModel source;
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
    final saved = await source.savePreferences(
      draft.copyWith(configured: complete || draft.configured),
    );
    if (_disposed) return saved;
    saving = false;
    error = source.error;
    notifyListeners();
    return saved;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
