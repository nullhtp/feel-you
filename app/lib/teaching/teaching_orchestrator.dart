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

  /// Set by [stopFromDispose] until the stopped [state] is published: the
  /// loop is stopped although `state.isRunning` may still be true.
  bool _stoppedFromDispose = false;

  /// Whether the loop should keep running. Checked by the async loop to
  /// avoid accessing [state] after dispose.
  bool get _shouldRun =>
      !_disposed && !_stoppedFromDispose && mounted && state.isRunning;

  /// Whether the current iteration was interrupted.
  bool get _isInterrupted => _disposed || !mounted || state.isInterrupted;

  /// Starts the play-wait-repeat loop for the current character, spelling
  /// it first if it is a word (see [_runLoop]).
  ///
  /// Resumes shake detection and discards any input the classifier buffered
  /// while the loop was stopped: those taps were ignored, so they must not
  /// become the start of the next pattern.
  ///
  /// No-op if already running.
  void start() {
    if (!mounted || _shouldRun) return;
    _stoppedFromDispose = false;
    _loopGeneration++;
    state = state.copyWith(isRunning: true, isInterrupted: false);
    _gestureClassifier.clearInput();
    _shakeDetector?.resume();
    unawaited(_runLoop(spellWord: true));
  }

  /// Stops the play-wait-repeat loop and cancels any ongoing vibration.
  ///
  /// Also discards any half-entered pattern (without evaluating it) and
  /// pauses shake detection. Gesture events are ignored until [start] is
  /// called again, so nothing vibrates while the loop is stopped.
  Future<void> stop() async {
    if (!mounted || !state.isRunning) return;
    _stoppedFromDispose = false;
    _loopGeneration++;
    state = state.copyWith(isRunning: false, isInterrupted: true);
    _cancelPause();
    _gestureClassifier.clearInput();
    _shakeDetector?.pause();
    await vibrationService.cancel();
  }

  /// Stops the loop like [stop], but is safe to call from a widget's
  /// `dispose`.
  ///
  /// Riverpod forbids changing a provider while the widget tree is being
  /// built or finalized, and `dispose` runs during finalization. Stopping in
  /// `deactivate` instead does not help: it runs while the tree is building
  /// (and may be followed by `activate`).
  ///
  /// So everything that silences the phone happens now, without touching
  /// [state]. The generation is bumped and [_shouldRun] turns false: the
  /// loop and any in-flight feedback or bottom-zone action end, and gesture
  /// events still on their way are ignored. The pause and the vibration are
  /// cancelled, pending input is discarded and shake detection is paused.
  /// Only the stopped [state] waits, for a microtask that runs after the
  /// frame. A [start] or [stop] before then supersedes it, so a surface
  /// mounted in the same frame still starts the loop.
  void stopFromDispose() {
    if (!mounted || !_shouldRun) return;
    _stoppedFromDispose = true;
    _loopGeneration++;
    _cancelPause();
    _gestureClassifier.clearInput();
    _shakeDetector?.pause();
    unawaited(vibrationService.cancel());
    scheduleMicrotask(() {
      if (!mounted || !_stoppedFromDispose) return;
      _stoppedFromDispose = false;
      state = state.copyWith(isRunning: false, isInterrupted: true);
    });
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

  /// Runs the play-wait-repeat loop for the current character.
  ///
  /// With [spellWord], a word is spelled first (see [_spellWord]): its first
  /// playback is replaced by the spelling, followed by the usual pause and
  /// then the word itself. The loop is started this way whenever it starts
  /// on a word ([start] and navigation), but not when it resumes after
  /// feedback: the user stays on the same word and already knows it.
  /// [spellWord] has no effect on a characters level, where the position
  /// already tells the user which character is playing.
  Future<void> _runLoop({bool spellWord = false}) async {
    if (_disposed) return;

    // Capture the generation so this loop can detect if a newer loop
    // was started (e.g. by navigation) while it was awaiting.
    final gen = _loopGeneration;

    sessionNotifier.setPhase(SessionPhase.playing);

    var spell = spellWord;
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
        if (spell) {
          await _spellWord(tokenPattern, gen);
        } else {
          await vibrationService.playMorseTokenPattern(tokenPattern);
        }
      } else {
        final pattern = level.patterns[character];
        if (pattern == null) break;
        await vibrationService.playMorsePattern(pattern);
      }
      spell = false;

      // Check if interrupted during playback or superseded by a new loop.
      if (!_shouldRun || _isInterrupted || gen != _loopGeneration) break;

      // Wait for the configured pause.
      await _pause(config.repeatPause);

      // Check again after the pause.
      if (!_shouldRun || _isInterrupted || gen != _loopGeneration) break;
    }
  }

  /// Spells a word: plays its letters one at a time, with
  /// [TeachingTimingConfig.spellingLetterGap] of silence between them.
  ///
  /// The words of a level are not in an order the user can count, so the
  /// position alone does not tell them which word is playing. Spelled
  /// slowly, the word can be read with the letters they already know.
  ///
  /// Stops early, like the loop, if the loop of generation [gen] is
  /// interrupted (a tap), stopped or superseded (navigation) during a letter
  /// or a gap. Each gap is a [_pause], so [_cancelPause] ends it at once.
  Future<void> _spellWord(List<MorseToken> wordPattern, int gen) async {
    final letters = splitWordPattern(wordPattern);
    for (var i = 0; i < letters.length; i++) {
      if (i > 0) {
        await _pause(config.spellingLetterGap);
        if (!_shouldRun || _isInterrupted || gen != _loopGeneration) return;
      }
      await vibrationService.playMorsePattern(letters[i]);
      if (!_shouldRun || _isInterrupted || gen != _loopGeneration) return;
    }
  }

  /// Waits for [duration], or until [_cancelPause] ends the wait early.
  ///
  /// A loop superseded during the wait may resume after the new loop has
  /// started its own pause, so the completer is only cleared if it is still
  /// this pause's: the new loop's pause stays cancellable.
  Future<void> _pause(Duration duration) async {
    final completer = _pauseCompleter = Completer<void>();
    await Future.any([Future<void>.delayed(duration), completer.future]);
    if (identical(_pauseCompleter, completer)) _pauseCompleter = null;
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
        _onNavigate(sessionNotifier.nextLevel, clampAtBoundary: true);
      case NavigateDown():
        _onNavigate(sessionNotifier.previousLevel, clampAtBoundary: true);
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
  /// Acts only while listening, i.e. once the user has tapped a dot or dash.
  /// While the pattern plays nothing has been entered yet: there is nothing
  /// to submit, and a character gap can only follow input. The tap is then
  /// ignored and the pattern keeps repeating, so a stray touch on the strip
  /// never leaves the user with nothing vibrating. During feedback it is
  /// ignored like [MorseInput] and [InputComplete].
  ///
  /// Like [_handleFeedback], the action is abandoned if the loop is stopped,
  /// restarted or navigated while its tap feedback is in flight, so it never
  /// acts on a character the user has already left. An abandoned action
  /// leaves the input buffer alone. That input belongs to the character that
  /// was left, so whatever superseded the action is responsible for it.
  Future<void> _onBottomZoneAction() async {
    final gen = _loopGeneration;
    if (sessionNotifier.state.phase != SessionPhase.listening) return;

    final isWordsLevel =
        sessionNotifier.state.currentLevel.kind == LevelKind.words;

    await vibrationService.playTapFeedback();
    if (!_shouldRun || gen != _loopGeneration) return;
    if (isWordsLevel) {
      _gestureClassifier.insertCharGap();
    } else {
      _gestureClassifier.submitInput();
    }
  }

  /// Plays feedback (success or error), pauses briefly, then resumes the loop.
  ///
  /// The loop resumes without spelling the word again: the user has not
  /// moved, so they already know which word it is.
  ///
  /// Resuming discards any input the classifier buffered during feedback:
  /// those taps were ignored, so they must not become the start of the next
  /// answer.
  ///
  /// The sequence is abandoned if the loop is stopped, restarted or
  /// navigated while it is in flight. After a [stop] the session stays in
  /// the feedback phase and [start] resets it to playing. A swipe past the
  /// first or last item or level does not navigate, so it leaves the
  /// sequence alone (see [_onNavigate]).
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
    _gestureClassifier.clearInput();
    unawaited(_runLoop());
  }

  /// Moves the session with [navigationAction] and restarts the loop for the
  /// character it lands on.
  ///
  /// Navigation works in any phase. Restarting cuts short whatever is
  /// vibrating and abandons any feedback sequence or bottom-zone action in
  /// flight. It also discards any input the classifier has buffered, so it
  /// cannot become the start of the next answer. The classifier clears its
  /// buffer itself for its own swipes and long holds, but not for a shake
  /// ([Home]), which comes from the [ShakeDetector].
  ///
  /// With [clampAtBoundary] (next/previous item or level), a swipe past the
  /// first or last item or level does not move the session. It then
  /// interrupts nothing that brings the loop back by itself:
  /// - while the loop is playing, the pattern keeps repeating as before;
  /// - while feedback plays, the feedback finishes and resumes the loop as
  ///   usual.
  ///
  /// Otherwise (listening) the swipe has already discarded the pending input
  /// in the classifier, which would leave the user with no input and nothing
  /// vibrating. The loop then restarts for the same character instead.
  void _onNavigate(
    void Function() navigationAction, {
    bool clampAtBoundary = false,
  }) {
    // Navigating only changes the session state, so it is done first: a
    // boundary no-op is then known before anything is interrupted.
    final stateBefore = sessionNotifier.state;
    navigationAction();
    final moved = sessionNotifier.state != stateBefore;

    if (clampAtBoundary && !moved) {
      final phase = sessionNotifier.state.phase;
      final isLoopPlaying =
          phase == SessionPhase.playing && !state.isInterrupted;
      if (isLoopPlaying || phase == SessionPhase.feedback) return;
    }

    // Stop any ongoing activity and discard the input (and its pending
    // silence timer) entered before the navigation.
    state = state.copyWith(isInterrupted: true);
    _cancelPause();
    vibrationService.cancel();
    _gestureClassifier.clearInput();

    // Restart the loop for the new (or same) character, spelling it first
    // if it is a word. Navigation is only handled while running (see
    // _onGestureEvent), so it never starts a stopped loop.
    _loopGeneration++;
    state = state.copyWith(isInterrupted: false);
    unawaited(_runLoop(spellWord: true));
  }
}
