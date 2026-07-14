import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/timer_state.dart';
import '../models/session_model.dart';
import '../models/subject_model.dart';
import 'core_providers.dart';

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;
  final Ref _ref;
  final Uuid _uuid = const Uuid();
  int _secondsSinceLastPersist = 0;

  TimerNotifier(this._ref) : super(const TimerState());

  void configure({
    required SubjectModel subject,
    required String chapter,
    required String revisionStage,
    String? notes,
  }) {
    if (state.isActive) return;
    state = state.copyWith(
      subject: subject,
      chapter: chapter,
      revisionStage: revisionStage,
      notes: notes,
    );
  }

  void start() {
    if (state.isRunning) return;
    if (state.subject == null) return;

    final now = DateTime.now();
    final sessionId = state.sessionId ?? _uuid.v4();

    state = state.copyWith(
      status: TimerStatus.running,
      startTime: state.startTime ?? now,
      sessionId: sessionId,
      clearPauseTime: true,
    );

    _persistPendingTimer();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
      );
      // Persist every 5 seconds while running rather than every tick —
      // enough to survive a forced close without hammering disk I/O
      // every single second.
      _secondsSinceLastPersist++;
      if (_secondsSinceLastPersist >= 5) {
        _secondsSinceLastPersist = 0;
        _persistPendingTimer();
      }
    });
  }

  void pause() {
    if (!state.isRunning) return;
    _ticker?.cancel();
    state = state.copyWith(
      status: TimerStatus.paused,
      pauseTime: DateTime.now(),
    );
    _persistPendingTimer();
  }

  void resume() {
    if (!state.isPaused) return;
    _ticker?.cancel();
    state = state.copyWith(
      status: TimerStatus.running,
      clearPauseTime: true,
    );
    _persistPendingTimer();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
      );
      _secondsSinceLastPersist++;
      if (_secondsSinceLastPersist >= 5) {
        _secondsSinceLastPersist = 0;
        _persistPendingTimer();
      }
    });
  }

  void _persistPendingTimer() {
    if (!state.isActive || state.subject == null || state.startTime == null) return;
    _ref.read(settingsServiceProvider).savePendingTimer(
          subjectId: state.subject!.id,
          subjectName: state.subject!.name,
          chapter: state.chapter,
          stage: state.revisionStage,
          notes: state.notes,
          startTime: state.startTime!,
          elapsedSeconds: state.elapsedSeconds,
          sessionId: state.sessionId ?? _uuid.v4(),
        );
  }

  Future<void> stop() async {
    if (state.isIdle) return;
    _ticker?.cancel();

    final endTime = DateTime.now();
    final durationSeconds = state.elapsedSeconds;

    if (durationSeconds >= 10 && state.subject != null && state.startTime != null) {
      final session = SessionModel(
        id: state.sessionId ?? _uuid.v4(),
        subjectId: state.subject!.id,
        subjectName: state.subject!.name,
        chapter: state.chapter,
        revisionStage: state.revisionStage,
        notes: state.notes,
        startTime: state.startTime!,
        endTime: endTime,
        durationSeconds: durationSeconds,
      );

      await _ref.read(sessionRepositoryProvider).insertSession(session);
      _ref.invalidate(todaySessionsProvider);
      _ref.invalidate(todayTotalSecondsProvider);
    }

    await _ref.read(settingsServiceProvider).clearPendingTimer();
    state = const TimerState();
  }

  void reset() {
    _ticker?.cancel();
    _ref.read(settingsServiceProvider).clearPendingTimer();
    state = const TimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});

// Today's sessions
final todaySessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  return ref.read(sessionRepositoryProvider).getSessionsByDate(DateTime.now());
});

/// The most recently logged session (any day) — powers the "Resume last
/// session" quick-start shortcut so an accidental close doesn't mean
/// starting completely from scratch.
final lastSessionProvider = FutureProvider<SessionModel?>((ref) async {
  return ref.read(sessionRepositoryProvider).getMostRecentSession();
});

// These two are deliberately plain (synchronous) Providers, not
// FutureProviders. The underlying math is instant (just combining an
// already-fetched session list with the live timer's elapsed seconds), so
// there's no real async work here. Making them FutureProviders that watch
// timerProvider caused them to flash through a "loading" state on every
// single timer tick (once a second) — visible as the whole card blinking
// blank-then-filled every second. A plain Provider recomputes instantly
// with no loading phase at all, so this never happens.
final todayTotalSecondsProvider = Provider<int>((ref) {
  final sessions = ref.watch(todaySessionsProvider).valueOrNull ?? [];
  final timerState = ref.watch(timerProvider);
  final sessionSeconds = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  final runningSeconds = timerState.isActive ? timerState.elapsedSeconds : 0;
  return sessionSeconds + runningSeconds;
});

final todaySubjectBreakdownProvider = Provider<Map<String, int>>((ref) {
  final sessions = ref.watch(todaySessionsProvider).valueOrNull ?? [];
  final timerState = ref.watch(timerProvider);
  final Map<String, int> breakdown = {};

  for (final s in sessions) {
    breakdown[s.subjectId] = (breakdown[s.subjectId] ?? 0) + s.durationSeconds;
  }

  if (timerState.isActive && timerState.subject != null) {
    final id = timerState.subject!.id;
    breakdown[id] = (breakdown[id] ?? 0) + timerState.elapsedSeconds;
  }

  return breakdown;
});
