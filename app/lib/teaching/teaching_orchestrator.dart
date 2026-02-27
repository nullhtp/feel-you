import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse_utils.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state of the teaching orchestrator.
///
/// Tracks whether the play-wait-repeat loop is active and whether
/// it has been interrupted by user input.
@immutable
class TeachingOrchestratorState {
  const TeachingOrchestratorState({
    this.isRunning = false,
    this.isInterrupted = false,
  });

  /// Whether the play-wait-repeat loop is currently active.
  final bool isRunning;

  /// Whether the current loop iteration was interrupted by user input.
  final bool isInterrupted;

  TeachingOrchestratorState copyWith({bool? isRunning, bool? isInterrupted}) {
    return TeachingOrchestratorState(
      isRunning: isRunning ?? this.isRunning,
      isInterrupted: isInterrupted ?? this.isInterrupted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeachingOrchestratorState &&
          isRunning == other.isRunning &&
          isInterrupted == other.isInterrupted;

  @override
  int get hashCode => Object.hash(isRunning, isInterrupted);

  @override
  String toString() =>
      'TeachingOrchestratorState(isRunning: $isRunning, '
      'isInterrupted: $isInterrupted)';
}

/// The teaching loop orchestrator.
///
/// Connects gesture input, vibration output, and session state into
/// a continuous learn-by-repetition loop. Subscribes to gesture events,
/// drives the vibration engine, and manages session phase transitions.
///
/// Does not auto-start on creation — call [start] to begin the loop.
class TeachingOrchestrator extends StateNotifier<TeachingOrchestratorState> {
  TeachingOrchestrator({
    required GestureClassifier gestureClassifier,
    required this.vibrationService,
    required this.sessionNotifier,
    this.config = const TeachingTimingConfig(),
  }) : super(const TeachingOrchestratorState()) {
    _gestureSubscription = gestureClassifier.events.listen(_onGestureEvent);
  }

  final VibrationService vibrationService;
  final SessionNotifier sessionNotifier;
  final TeachingTimingConfig config;

  late final StreamSubscription<GestureEvent> _gestureSubscription;

  /// Completer used to cancel the pause between pattern repetitions.
  /// Completing it breaks the delay early so the loop can exit.
  Completer<void>? _pauseCompleter;

  /// Internal flag that survives after [dispose]. The async loop checks this
  /// instead of [state] so it can safely exit even after the notifier has
  /// been disposed.
  bool _disposed = false;

  /// Whether the loop should keep running. Checked by the async loop to
  /// avoid accessing [state] after dispose.
  bool get _shouldRun => !_disposed && mounted && state.isRunning;

  /// Whether the current iteration was interrupted.
  bool get _isInterrupted => _disposed || !mounted || state.isInterrupted;

  /// Starts the play-wait-repeat loop for the current letter.
  ///
  /// No-op if already running.
  void start() {
    if (!mounted || state.isRunning) return;
    state = state.copyWith(isRunning: true, isInterrupted: false);
    unawaited(_runLoop());
  }

  /// Stops the play-wait-repeat loop and cancels any ongoing vibration.
  Future<void> stop() async {
    if (!mounted || !state.isRunning) return;
    state = state.copyWith(isRunning: false, isInterrupted: true);
    _cancelPause();
    await vibrationService.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _gestureSubscription.cancel();
    _cancelPause();
    // Best-effort cancel; we can't await in dispose.
    vibrationService.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Play-wait-repeat loop
  // ---------------------------------------------------------------------------

  Future<void> _runLoop() async {
    if (_disposed) return;
    sessionNotifier.setPhase(SessionPhase.playing);

    while (_shouldRun && !_isInterrupted) {
      // Look up the current letter's Morse pattern.
      final letter = sessionNotifier.state.currentLetter;
      final pattern = encodeLetter(letter);
      if (pattern == null) break; // Should never happen for A-Z.

      // Play the pattern.
      await vibrationService.playMorsePattern(pattern);

      // Check if interrupted during playback.
      if (!_shouldRun || _isInterrupted) break;

      // Wait for the configured pause.
      _pauseCompleter = Completer<void>();
      final delayed = Future<void>.delayed(config.repeatPause);
      await Future.any([delayed, _pauseCompleter!.future]);
      _pauseCompleter = null;

      // Check again after the pause.
      if (!_shouldRun || _isInterrupted) break;
    }
  }

  void _cancelPause() {
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
  }

  // ---------------------------------------------------------------------------
  // Gesture event handling
  // ---------------------------------------------------------------------------

  void _onGestureEvent(GestureEvent event) {
    if (_disposed || !mounted) return;
    switch (event) {
      case MorseInput():
        _onMorseInput();
      case InputComplete():
        _onInputComplete(event);
      case NavigateNext():
        _onNavigate(sessionNotifier.nextLetter, clampAtBoundary: true);
      case NavigatePrevious():
        _onNavigate(sessionNotifier.previousLetter, clampAtBoundary: true);
      case Reset():
        _onNavigate(sessionNotifier.reset);
    }
  }

  void _onMorseInput() {
    final phase = sessionNotifier.state.phase;

    // Only react to first tap during playing phase.
    if (phase != SessionPhase.playing) return;

    // Interrupt the playback loop.
    state = state.copyWith(isInterrupted: true);
    _cancelPause();
    vibrationService.cancel();
    sessionNotifier.setPhase(SessionPhase.listening);
  }

  void _onInputComplete(InputComplete event) {
    final phase = sessionNotifier.state.phase;

    // Only evaluate input during listening phase.
    if (phase != SessionPhase.listening) return;

    final letter = sessionNotifier.state.currentLetter;
    final expected = encodeLetter(letter);

    final isCorrect =
        expected != null && patternsEqual(event.symbols, expected);

    if (isCorrect) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  Future<void> _handleCorrectAnswer() async {
    if (_disposed) return;
    sessionNotifier.setPhase(SessionPhase.feedback);
    await vibrationService.playSuccess();

    // Check if disposed or navigation happened during feedback.
    if (_disposed || !mounted) return;
    if (sessionNotifier.state.phase != SessionPhase.feedback) return;

    // Resume the loop (fire-and-forget — the loop manages its own lifecycle).
    state = state.copyWith(isInterrupted: false);
    unawaited(_runLoop());
  }

  Future<void> _handleWrongAnswer() async {
    if (_disposed) return;
    sessionNotifier.setPhase(SessionPhase.feedback);
    await vibrationService.playError();

    // Check if disposed or navigation happened during feedback.
    if (_disposed || !mounted) return;
    if (sessionNotifier.state.phase != SessionPhase.feedback) return;

    // Replay the correct pattern.
    final letter = sessionNotifier.state.currentLetter;
    final pattern = encodeLetter(letter);
    if (pattern != null) {
      await vibrationService.playMorsePattern(pattern);
    }

    // Check again after replay.
    if (_disposed || !mounted) return;
    if (sessionNotifier.state.phase != SessionPhase.feedback) return;

    // Resume the loop (fire-and-forget — the loop manages its own lifecycle).
    state = state.copyWith(isInterrupted: false);
    unawaited(_runLoop());
  }

  void _onNavigate(
    void Function() navigationAction, {
    bool clampAtBoundary = false,
  }) {
    // Navigation works in any phase.
    // Stop any ongoing activity.
    state = state.copyWith(isInterrupted: true);
    _cancelPause();
    vibrationService.cancel();

    // Capture index before navigation to detect boundary no-ops.
    final indexBefore = sessionNotifier.state.letterIndex;

    // Perform the navigation (this resets phase to playing).
    navigationAction();

    final indexAfter = sessionNotifier.state.letterIndex;

    // For next/previous: if already at the boundary (A or Z), the
    // navigation is a no-op. Don't restart the loop to avoid an
    // unexpected vibration pattern replay.
    if (clampAtBoundary && indexBefore == indexAfter) return;

    // Restart the loop for the new (or reset) letter.
    state = state.copyWith(isRunning: true, isInterrupted: false);
    unawaited(_runLoop());
  }
}
