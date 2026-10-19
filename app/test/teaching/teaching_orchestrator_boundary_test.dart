import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/mock_vibration_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pause between pattern repetitions. Short to keep the tests fast.
const _repeatPause = Duration(milliseconds: 10);

/// Silence between the letters of a spelled word. Short to keep the tests
/// fast.
const _spellingLetterGap = Duration(milliseconds: 10);

/// Pause between feedback and the loop resuming.
const _postFeedbackPause = Duration(milliseconds: 50);

/// Silence after the quiz's `?` marker. Short to keep the tests fast.
const _quizMarkerGap = Duration(milliseconds: 10);

/// Long enough for the loop to have started and played once.
const _loopStarted = Duration(milliseconds: 20);

/// Long enough for the loop to have repeated several times.
const _severalRepeatCycles = Duration(milliseconds: 100);

/// Lets stream events and short loop iterations run.
Future<void> settle([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

/// A [MockVibrationService] that can hold the next call of one type open
/// until the test calls [release], so the test can act while the
/// orchestrator is awaiting it.
///
/// Only the next call of the type set in [holdNext] is held; later calls
/// complete at once.
class _HeldVibration extends MockVibrationService {
  Completer<void>? _held;

  /// The type of the next call to hold open until [release] is called, or
  /// null to hold nothing.
  VibrationCallType? holdNext;

  /// Whether a held call has started and is waiting for [release].
  bool get isHolding => _held != null && !_held!.isCompleted;

  /// Lets the held call complete and drops any hold not yet taken.
  void release() {
    holdNext = null;
    if (isHolding) _held!.complete();
  }

  Future<void> _maybeHold(VibrationCallType type) async {
    if (holdNext != type) return;
    holdNext = null;
    _held = Completer<void>();
    await _held!.future;
  }

  @override
  Future<void> playMorsePattern(List<MorseSignal> signals) async {
    await super.playMorsePattern(signals);
    await _maybeHold(VibrationCallType.playMorsePattern);
  }

  @override
  Future<void> playMorseTokenPattern(List<MorseToken> tokens) async {
    await super.playMorseTokenPattern(tokens);
    await _maybeHold(VibrationCallType.playMorseTokenPattern);
  }

  @override
  Future<void> playSuccess() async {
    await super.playSuccess();
    await _maybeHold(VibrationCallType.playSuccess);
  }
}

/// An orchestrator wired to test doubles.
class _Harness {
  _Harness(this.session, {GestureClassifier? classifier})
    : classifier = classifier ?? FakeGestureClassifier() {
    orchestrator = TeachingOrchestrator(
      gestureClassifier: this.classifier,
      vibrationService: vibration,
      sessionNotifier: session,
      config: const TeachingTimingConfig(
        repeatPause: _repeatPause,
        postFeedbackPause: _postFeedbackPause,
        spellingLetterGap: _spellingLetterGap,
        quizMarkerGap: _quizMarkerGap,
      ),
    );
  }

  /// A harness on the first digit, `0`, which is also the first item of the
  /// first level.
  factory _Harness.firstDigit({GestureClassifier? classifier}) =>
      _Harness(SessionNotifier(MorseLanguage.english), classifier: classifier);

  /// A harness in the quiz of the digits level, the first level.
  factory _Harness.firstLevelQuiz({GestureClassifier? classifier}) => _Harness(
    _enterQuiz(SessionNotifier(MorseLanguage.english)),
    classifier: classifier,
  );

  /// A harness on the first word of the words level, the last level.
  factory _Harness.lastLevel({GestureClassifier? classifier}) =>
      _Harness(_lastLevel(), classifier: classifier);

  /// A harness in the quiz of the words level, the last level.
  factory _Harness.lastLevelQuiz({GestureClassifier? classifier}) =>
      _Harness(_enterQuiz(_lastLevel()), classifier: classifier);

  static SessionNotifier _lastLevel() {
    final session = SessionNotifier(MorseLanguage.english);
    while (session.state.levelIndex < session.state.levels.length - 1) {
      session.nextLevel();
    }
    expect(session.state.currentLevel.kind, LevelKind.words);
    return session;
  }

  /// Moves [session] past the last item of its level, into the quiz.
  static SessionNotifier _enterQuiz(SessionNotifier session) {
    while (!session.state.isInQuiz) {
      session.nextPosition();
    }
    return session;
  }

  final SessionNotifier session;
  final GestureClassifier classifier;
  final vibration = _HeldVibration();
  late final TeachingOrchestrator orchestrator;

  /// The classifier as a fake, for tests that inject events directly.
  FakeGestureClassifier get gestures => classifier as FakeGestureClassifier;

  SessionPhase get phase => session.state.phase;

  bool get _isWordsLevel => session.state.currentLevel.kind == LevelKind.words;

  /// The correct answer for the current item.
  InputComplete get correctAnswer {
    final state = session.state;
    final level = state.currentLevel;
    if (_isWordsLevel) {
      return InputComplete(level.wordPatterns![state.currentCharacter]!);
    }
    final pattern = level.patterns[state.currentCharacter]!;
    return InputComplete([for (final s in pattern) Signal(s)]);
  }

  /// The vibration call that plays first when the loop starts: the
  /// character's pattern, or the first letter of the spelled word. Both are
  /// signal patterns.
  VibrationCallType get firstPlaybackCall => VibrationCallType.playMorsePattern;

  /// How many patterns (signal or word token patterns) were played since
  /// the vibration calls were last reset.
  int get playbacks => vibration.calls
      .where(
        (c) =>
            c.type == VibrationCallType.playMorsePattern ||
            c.type == VibrationCallType.playMorseTokenPattern,
      )
      .length;

  /// Starts the loop and lets it play the first pattern.
  Future<void> start() async {
    orchestrator.start();
    await settle(_loopStarted);
    expect(phase, SessionPhase.playing);
  }

  /// Expects the loop to be running uninterrupted and repeating the pattern
  /// of [character].
  Future<void> expectLoopRepeating(String character) async {
    vibration.reset();
    await settle(_severalRepeatCycles);
    expect(session.state.currentCharacter, character);
    expect(phase, SessionPhase.playing);
    expect(orchestrator.state.isRunning, isTrue);
    expect(orchestrator.state.isInterrupted, isFalse);
    expect(playbacks, greaterThan(1));
  }

  Future<void> tearDown() async {
    vibration.release();
    await orchestrator.stop();
    await settle(_loopStarted);
    orchestrator.dispose();
    classifier.dispose();
  }
}

/// A boundary item or level and the swipe that would move past it.
typedef _Boundary = ({
  _Harness Function({GestureClassifier? classifier}) harness,
  GestureEvent swipe,
});

void main() {
  final boundaries = <String, _Boundary>{
    'NavigatePrevious on the first item': (
      harness: _Harness.firstDigit,
      swipe: const NavigatePrevious(),
    ),
    // Swiping right on the last item enters the quiz, so it is no boundary;
    // the quiz has its own at the first and last level.
    'NavigateDown in the quiz of the first level': (
      harness: _Harness.firstLevelQuiz,
      swipe: const NavigateDown(),
    ),
    'NavigateDown on the first level': (
      harness: _Harness.firstDigit,
      swipe: const NavigateDown(),
    ),
    'NavigateUp on the last level': (
      harness: _Harness.lastLevel,
      swipe: const NavigateUp(),
    ),
    'NavigateUp in the quiz of the last level': (
      harness: _Harness.lastLevelQuiz,
      swipe: const NavigateUp(),
    ),
  };

  for (final MapEntry(key: name, value: boundary) in boundaries.entries) {
    group(name, () {
      // ---------------------------------------------------------------------
      // During playing: the loop is left untouched
      // ---------------------------------------------------------------------
      test('during playing: the pattern keeps repeating', () async {
        final t = boundary.harness();
        await t.start();
        final character = t.session.state.currentCharacter;
        t.vibration.reset();

        t.gestures.addEvent(boundary.swipe);
        await settle();

        expect(t.vibration.callLog, isNot(contains('cancel')));
        await t.expectLoopRepeating(character);

        await t.tearDown();
      });

      test('during playing: the pattern in progress is not cut short or '
          'replayed', () async {
        final t = boundary.harness();
        t.vibration.holdNext = t.firstPlaybackCall;
        t.orchestrator.start();
        await settle();
        expect(t.vibration.isHolding, isTrue);
        expect(t.playbacks, 1);

        t.gestures.addEvent(boundary.swipe);
        await settle();

        // Neither cancelled nor restarted from the beginning.
        expect(t.vibration.callLog, isNot(contains('cancel')));
        expect(t.playbacks, 1);
        expect(t.orchestrator.state.isInterrupted, isFalse);

        // Once the pattern has played, the same loop repeats it.
        t.vibration.release();
        await t.expectLoopRepeating(t.session.state.currentCharacter);

        await t.tearDown();
      });

      // ---------------------------------------------------------------------
      // During listening: the loop restarts
      // ---------------------------------------------------------------------
      test('during listening: the loop restarts for the same item', () async {
        final t = boundary.harness();
        await t.start();
        final character = t.session.state.currentCharacter;
        t.gestures.addEvent(const MorseInput(MorseSignal.dot));
        await settle();
        expect(t.phase, SessionPhase.listening);

        t.gestures.addEvent(boundary.swipe);
        await settle();

        expect(t.phase, SessionPhase.playing);
        await t.expectLoopRepeating(character);

        // A tap still interrupts the restarted loop.
        t.gestures.addEvent(const MorseInput(MorseSignal.dot));
        await settle();
        expect(t.phase, SessionPhase.listening);
        t.vibration.reset();
        await settle(_severalRepeatCycles);
        expect(t.playbacks, 0);

        await t.tearDown();
      });

      // ---------------------------------------------------------------------
      // During feedback: the feedback finishes and resumes the loop
      // ---------------------------------------------------------------------
      test('during feedback: the feedback is not cut short and resumes the '
          'loop', () async {
        final t = boundary.harness();
        await t.start();
        final character = t.session.state.currentCharacter;
        t.gestures.addEvent(const MorseInput(MorseSignal.dot));
        await settle();

        t.vibration.holdNext = VibrationCallType.playSuccess;
        t.gestures.addEvent(t.correctAnswer);
        await settle();
        expect(t.vibration.isHolding, isTrue);
        expect(t.phase, SessionPhase.feedback);
        t.vibration.reset();

        t.gestures.addEvent(boundary.swipe);
        await settle();

        expect(t.vibration.callLog, isNot(contains('cancel')));
        expect(t.phase, SessionPhase.feedback);

        // The feedback finishes, and the loop resumes after the pause.
        t.vibration.release();
        await settle();
        expect(t.phase, SessionPhase.feedback);
        expect(t.playbacks, 0);
        await settle(_postFeedbackPause + _loopStarted);
        final resumedOn = t.session.state.currentCharacter;
        if (t.session.state.isInQuiz) {
          // A correct quiz answer moves on to a new quiz item.
          expect(resumedOn, isNot(character));
        } else {
          expect(resumedOn, character);
        }
        await t.expectLoopRepeating(resumedOn);

        await t.tearDown();
      });
    });
  }

  // -------------------------------------------------------------------------
  // With the real classifier
  // -------------------------------------------------------------------------
  group('with a real classifier', () {
    // Fast swipes, from the first touch to the release, starting after the
    // dot has been tapped.
    final swipes = <String, ({GestureEvent event, TouchDown down, TouchUp up})>{
      'to the left past the first item': (
        event: const NavigatePrevious(),
        down: const TouchDown(
          timestamp: Duration(milliseconds: 100),
          position: 600,
        ),
        up: const TouchUp(
          timestamp: Duration(milliseconds: 150),
          position: 100,
        ),
      ),
      'down past the first level': (
        event: const NavigateDown(),
        down: const TouchDown(
          timestamp: Duration(milliseconds: 100),
          position: 100,
          y: 100,
        ),
        up: const TouchUp(
          timestamp: Duration(milliseconds: 150),
          position: 100,
          y: 600,
        ),
      ),
    };

    for (final MapEntry(key: name, value: swipe) in swipes.entries) {
      test('a dot then a swipe $name: the loop restarts and the discarded '
          'dot is never judged', () async {
        final classifier = GestureClassifier(
          screenWidth: 800,
          config: const GestureTimingConfig(silenceTimeout: 50),
        );
        final events = <GestureEvent>[];
        final subscription = classifier.events.listen(events.add);
        final t = _Harness.firstDigit(classifier: classifier);
        await t.start();

        // A dot on the left half.
        classifier
          ..handleTouch(const TouchDown(timestamp: Duration.zero, position: 1))
          ..handleTouch(
            const TouchUp(timestamp: Duration(milliseconds: 50), position: 1),
          );
        await settle();
        expect(t.phase, SessionPhase.listening);

        classifier
          ..handleTouch(swipe.down)
          ..handleTouch(swipe.up);
        await settle();
        expect(events.last, swipe.event);
        expect(t.session.state.levelIndex, 0);
        expect(t.session.state.positionIndex, 0);

        await t.expectLoopRepeating('0');
        expect(events.whereType<InputComplete>(), isEmpty);
        expect(t.vibration.callLog, isNot(contains('playError')));

        await subscription.cancel();
        await t.tearDown();
      });
    }
  });
}
