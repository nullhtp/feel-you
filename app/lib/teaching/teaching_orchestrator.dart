import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state of the teaching orchestrator.
///
/// Tracks whether the play-wait-repeat loop is active and whether
/// it has been interrupted by user input.
@immutable
class TeachingOrchestratorState extends Equatable {
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
  List<Object?> get props => [isRunning, isInterrupted];

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
///
/// Gesture events (including shakes) are only handled while the loop is
/// running. Before [start], after [stop] (e.g. while the app is in the
/// background) and after [dispose] they are ignored, so nothing can restart
/// the loop or play feedback while the loop is stopped.
class TeachingOrchestrator extends StateNotifier<TeachingOrchestratorState> {
  TeachingOrchestrator({
    required GestureClassifier gestureClassifier,
    required this.vibrationService,
    required this.sessionNotifier,
    this.config = const TeachingTimingConfig(),
    ShakeDetector? shakeDetector,
  }) : _gestureClassifier = gestureClassifier,
       _shakeDetector = shakeDetector,
       super(const TeachingOrchestratorState()) {
    _gestureSubscription = gestureClassifier.events.listen(_onGestureEvent);
    _shakeSubscription = shakeDetector?.events.listen(_onGestureEvent);
  }

  final GestureClassifier _gestureClassifier;
  final ShakeDetector? _shakeDetector;
  final VibrationService vibrationService;
  final SessionNotifier sessionNotifier;
  final TeachingTimingConfig config;

  late final StreamSubscription<GestureEvent> _gestureSubscription;
  StreamSubscription<GestureEvent>? _shakeSubscription;

  /// Completer used to cancel the pause between pattern repetitions.
  /// Completing it breaks the delay early so the loop can exit.
  Completer<void>? _pauseCompleter;

  /// Internal flag that survives after [dispose]. The async loop checks this
  /// instead of [state] so it can safely exit even after the notifier has
  /// been disposed.
  bool _disposed = false;

  /// Generation counter to invalidate stale loops. Each call to [_runLoop]
  /// and [_handleFeedback] captures the current generation; if it changes
  /// (due to start, stop or navigation), the stale loop or feedback
  /// sequence exits.
  int _loopGeneration = 0;

  /// Whether the loop should keep running. Checked by the async loop to
  /// avoid accessing [state] after dispose.
  bool get _shouldRun => !_disposed && mounted && state.isRunning;

  /// Whether the current iteration was interrupted.
  bool get _isInterrupted => _disposed || !mounted || state.isInterrupted;

  /// Starts the play-wait-repeat loop for the current character.
  ///
  /// Resumes shake detection and discards any input the classifier buffered
  /// while the loop was stopped: those taps were ignored, so they must not
  /// become the start of the next pattern.
  ///
  /// No-op if already running.
  void start() {
    if (!mounted || state.isRunning) return;
    _loopGeneration++;
    state = state.copyWith(isRunning: true, isInterrupted: false);
    _gestureClassifier.clearInput();
    _shakeDetector?.resume();
    unawaited(_runLoop());
  }

  /// Stops the play-wait-repeat loop and cancels any ongoing vibration.
  ///
  /// Also discards any half-entered pattern (without evaluating it) and
  /// pauses shake detection. Gesture events are ignored until [start] is
  /// called again, so nothing vibrates while the loop is stopped.
  Future<void> stop() async {
    if (!mounted || !state.isRunning) return;
    _loopGeneration++;
    state = state.copyWith(isRunning: false, isInterrupted: true);
    _cancelPause();
    _gestureClassifier.clearInput();
    _shakeDetector?.pause();
    await vibrationService.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _gestureSubscription.cancel();
    _shakeSubscription?.cancel();
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

    // Capture the generation so this loop can detect if a newer loop
    // was started (e.g. by navigation) while it was awaiting.
    final gen = _loopGeneration;

    sessionNotifier.setPhase(SessionPhase.playing);

    while (_shouldRun && !_isInterrupted && gen == _loopGeneration) {
      // Look up the current character's Morse pattern from the level.
      final character = sessionNotifier.state.currentCharacter;
      final level = sessionNotifier.state.currentLevel;
      final isWordsLevel = level.kind == LevelKind.words;

      // For word levels, use the token pattern (with CharGap pauses)
      // from the level; for single-character levels, use signals.
      if (isWordsLevel) {
        final tokenPattern = level.wordPatterns?[character];
        if (tokenPattern == null) break;
        await vibrationService.playMorseTokenPattern(tokenPattern);
      } else {
        final pattern = level.patterns[character];
        if (pattern == null) break;
        await vibrationService.playMorsePattern(pattern);
      }

      // Check if interrupted during playback or superseded by a new loop.
      if (!_shouldRun || _isInterrupted || gen != _loopGeneration) break;

      // Wait for the configured pause.
      _pauseCompleter = Completer<void>();
      final delayed = Future<void>.delayed(config.repeatPause);
      await Future.any([delayed, _pauseCompleter!.future]);
      _pauseCompleter = null;

      // Check again after the pause.
      if (!_shouldRun || _isInterrupted || gen != _loopGeneration) break;
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
    // Ignore every event while the loop is stopped (before [start], after
    // [stop] and after [dispose]). Otherwise a shake (Home) or swipe would
    // restart the loop, and a late InputComplete would play success/error
    // feedback, while the app is in the background.
    if (!_shouldRun) return;
    switch (event) {
      case MorseInput():
        _onMorseInput();
      case InputComplete():
        _onInputComplete(event);
      case NavigateNext():
        _onNavigate(sessionNotifier.nextPosition, clampAtBoundary: true);
      case NavigatePrevious():
        _onNavigate(sessionNotifier.previousPosition, clampAtBoundary: true);
      case Reset():
        _onNavigate(sessionNotifier.reset);
      case NavigateUp():
        _onNavigate(sessionNotifier.nextLevel);
      case NavigateDown():
        _onNavigate(sessionNotifier.previousLevel);
      case Home():
        _onNavigate(sessionNotifier.home);
      case ChangeLanguage():
        // Not a session change: TouchSurface stops the loop and returns to
        // the language picker.
        break;
      case BottomZoneAction():
        _onBottomZoneAction();
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

    final character = sessionNotifier.state.currentCharacter;
    final level = sessionNotifier.state.currentLevel;
    final isWordsLevel = level.kind == LevelKind.words;

    final bool isCorrect;
    if (isWordsLevel) {
      // Word level: compare full token sequence including CharGap positions.
      final wordPattern = level.wordPatterns?[character];
      isCorrect =
          wordPattern != null && tokenPatternsEqual(event.tokens, wordPattern);
    } else {
      // Single-character level: extract signals and compare.
      final expected = level.patterns[character];
      final inputSignals = event.tokens
          .whereType<Signal>()
          .map((s) => s.signal)
          .toList();
      isCorrect = expected != null && patternsEqual(inputSignals, expected);
    }

    if (isCorrect) {
      _handleFeedback(vibrationService.playSuccess);
    } else {
      _handleFeedback(vibrationService.playError);
    }
  }

  /// Handles a bottom-zone tap: inserts a character gap on a words level, or
  /// submits the pending input on a character level.
  ///
  /// Like [_handleFeedback], the action is abandoned if the loop is stopped,
  /// restarted or navigated while one of its vibration calls is in flight,
  /// so it never acts on a character the user has already left. Its own
  /// interrupt of the playback does not change the generation, so it does
  /// not abandon the action.
  ///
  /// An abandoned action leaves the input buffer alone. That input belongs
  /// to the character that was left, so whatever superseded the action is
  /// responsible for it.
  Future<void> _onBottomZoneAction() async {
    final gen = _loopGeneration;
    final phase = sessionNotifier.state.phase;

    // Ignore during feedback (consistent with MorseInput/InputComplete).
    if (phase == SessionPhase.feedback) return;

    final isWordsLevel =
        sessionNotifier.state.currentLevel.kind == LevelKind.words;

    if (isWordsLevel) {
      // Words level: insert charGap into the input buffer.
      // Works during playing (triggers interrupt like MorseInput) or listening.
      if (phase == SessionPhase.playing) {
        // Interrupt playback first, same as _onMorseInput.
        state = state.copyWith(isInterrupted: true);
        _cancelPause();
        await vibrationService.cancel();
        // Stopped (e.g. backgrounded), restarted or navigated while
        // cancelling: no tap feedback, and any new loop keeps playing.
        if (!_shouldRun || gen != _loopGeneration) return;
        sessionNotifier.setPhase(SessionPhase.listening);
      }
      // Haptic confirmation *after* cancel so the two don't collide.
      await vibrationService.playTapFeedback();
      if (!_shouldRun || gen != _loopGeneration) return;
      _gestureClassifier.insertCharGap();
    } else {
      // Character levels (digits/letters): submit input immediately.
      // Only act during listening (when there's input to submit).
      if (phase != SessionPhase.listening) return;
      await vibrationService.playTapFeedback();
      if (!_shouldRun || gen != _loopGeneration) return;
      _gestureClassifier.submitInput();
    }
  }

  /// Plays feedback (success or error), pauses briefly, then resumes the loop.
  ///
  /// The sequence is abandoned if the loop is stopped, restarted or
  /// navigated while it is in flight. After a [stop] the session stays in
  /// the feedback phase and [start] resets it to playing.
  Future<void> _handleFeedback(Future<void> Function() playFeedback) async {
    if (_disposed) return;
    final gen = _loopGeneration;
    sessionNotifier.setPhase(SessionPhase.feedback);
    await playFeedback();

    // Check if stopped, disposed, restarted or navigated during feedback.
    if (!_shouldRun || gen != _loopGeneration) return;
    if (sessionNotifier.state.phase != SessionPhase.feedback) return;

    // Brief silence so the user can register the feedback before the
    // loop resumes with the Morse pattern.
    await Future<void>.delayed(config.postFeedbackPause);
    if (!_shouldRun || gen != _loopGeneration) return;
    if (sessionNotifier.state.phase != SessionPhase.feedback) return;

    // Resume the loop (fire-and-forget — the loop manages its own lifecycle).
    _loopGeneration++;
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

    // Capture state before navigation to detect boundary no-ops.
    final stateBefore = sessionNotifier.state;

    // Perform the navigation (this resets phase to playing).
    navigationAction();

    final stateAfter = sessionNotifier.state;

    // For next/previous: if already at the boundary, the navigation is a
    // no-op. Don't restart the loop to avoid an unexpected pattern replay.
    if (clampAtBoundary && stateBefore == stateAfter) return;

    // Restart the loop for the new (or reset) character. Navigation is only
    // handled while running (see _onGestureEvent), so it never starts a
    // stopped loop.
    _loopGeneration++;
    state = state.copyWith(isInterrupted: false);
    unawaited(_runLoop());
  }
}
