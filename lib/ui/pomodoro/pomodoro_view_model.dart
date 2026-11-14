import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/errors/request_error.dart';
import '../../data/repositories/study_repository.dart';
import '../../domain/models/study_preferences.dart';

enum FocusMode { focus, shortBreak, longBreak }

class PomodoroViewModel extends ChangeNotifier {
  PomodoroViewModel(this._repository, this.preferences, {Stopwatch? stopwatch})
    : _watch = stopwatch ?? Stopwatch();
  final StudyRepository _repository;
  final StudyPreferences preferences;
  FocusMode mode = FocusMode.focus;
  int? subjectId;
  int completedCycles = 0;
  int _elapsedMicros = 0;
  final Stopwatch _watch;
  Timer? _ticker;
  FocusSession? _pending;
  bool saving = false, _disposed = false;
  String? error;
  int get durationSeconds =>
      (switch (mode) {
        FocusMode.focus => preferences.focusMinutes,
        FocusMode.shortBreak => preferences.shortBreak,
        FocusMode.longBreak => preferences.longBreak,
      }) *
      60;
  int get remaining => max(
    0,
    durationSeconds -
        ((_elapsedMicros + _watch.elapsedMicroseconds) ~/ 1000000),
  );
  bool get running => _watch.isRunning;
  bool get hasStarted => running || _elapsedMicros > 0 || _pending != null;
  bool get needsSave => _pending != null;
  double get progress => (durationSeconds - remaining) / durationSeconds;
  String get clock =>
      '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
  String get label => switch (mode) {
    FocusMode.focus => 'Foco máximo',
    FocusMode.shortBreak => 'Pausa curta',
    FocusMode.longBreak => 'Pausa longa',
  };
  void selectSubject(int? id) {
    if (hasStarted || saving) return;
    subjectId = id;
    _notify();
  }

  void selectMode(FocusMode value) {
    if (hasStarted || saving) return;
    mode = value;
    error = null;
    _notify();
  }

  void toggle() {
    if (saving || needsSave || (mode == FocusMode.focus && subjectId == null)) {
      return;
    }
    if (running) {
      _pause();
    } else {
      _watch.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (remaining == 0) {
          unawaited(_finish());
        } else {
          _notify();
        }
      });
    }
    _notify();
  }

  void _pause() {
    _watch.stop();
    _elapsedMicros += _watch.elapsedMicroseconds;
    _watch.reset();
    _ticker?.cancel();
  }

  void cancel() {
    if (saving) return;
    _pause();
    _elapsedMicros = 0;
    _pending = null;
    error = null;
    _notify();
  }

  void skipBreak() {
    if (mode == FocusMode.focus || saving || needsSave) return;
    _pause();
    _elapsedMicros = 0;
    mode = FocusMode.focus;
    error = null;
    _notify();
  }

  Future<void> _finish() async {
    _pause();
    if (mode != FocusMode.focus) {
      mode = FocusMode.focus;
      _elapsedMicros = 0;
      _notify();
      return;
    }
    final random = Random.secure();
    _pending = FocusSession(
      id: '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}',
      subjectId: subjectId!,
      seconds: durationSeconds,
      completedAt: DateTime.now(),
    );
    await retrySave();
  }

  Future<void> retrySave() async {
    if (_pending == null || saving) return;
    saving = true;
    error = null;
    _notify();
    try {
      await _repository.saveSession(_pending!);
      _pending = null;
      completedCycles++;
      mode = completedCycles % 4 == 0
          ? FocusMode.longBreak
          : FocusMode.shortBreak;
      _elapsedMicros = 0;
    } catch (e, st) {
      error = requestErrorMessage(e, stackTrace: st);
    } finally {
      saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watch.stop();
    _ticker?.cancel();
    super.dispose();
  }
}
