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

/// Pause between feedback and the loop resuming.
const _postFeedbackPause = Duration(milliseconds: 50);

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
      ),
    );
  }

  /// A harness on the first digit, `0`.
  factory _Harness.firstDigit({GestureClassifier? classifier}) =>
      _Harness(SessionNotifier(MorseLanguage.english), classifier: classifier);

  /// A harness on the last digit, `9`.
  factory _Harness.lastDigit({GestureClassifier? classifier}) {
    final session = SessionNotifier(MorseLanguage.english);
    while (session.state.positionIndex <
        session.state.currentLevel.characters.length - 1) {
      session.nextPosition();
    }
    return _Harness(session, classifier: classifier);
  }

  final SessionNotifier session;
  final GestureClassifier classifier;
  final vibration = _HeldVibration();
  late final TeachingOrchestrator orchestrator;

  /// The classifier as a fake, for tests that inject events directly.
  FakeGestureClassifier get gestures => classifier as FakeGestureClassifier;

  SessionPhase get phase => session.state.phase;

  /// The correct answer for the current (character level) item.
  InputComplete get correctAnswer {
    final state = session.state;
    final pattern = state.currentLevel.patterns[state.currentCharacter]!;
    return InputComplete([for (final s in pattern) Signal(s)]);
  }

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

/// A boundary item and the swipe that would move past it.
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
    'NavigateNext on the last item': (
      harness: _Harness.lastDigit,
      swipe: const NavigateNext(),
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
        t.vibration.holdNext = VibrationCallType.playMorsePattern;
        t.orchestrator.start();
        await settle();
        expect(t.vibration.isHolding, isTrue);
        expect(t.vibration.patterns, hasLength(1));

        t.gestures.addEvent(boundary.swipe);
        await settle();

        // Neither cancelled nor restarted from the beginning.
        expect(t.vibration.callLog, isNot(contains('cancel')));
        expect(t.vibration.patterns, hasLength(1));
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
        await t.expectLoopRepeating(character);

        await t.tearDown();
      });
    });
  }

  // -------------------------------------------------------------------------
  // With the real classifier
  // -------------------------------------------------------------------------
  group('with a real classifier', () {
    test('a dot then a swipe past the first item: the loop restarts and the '
        'discarded dot is never judged', () async {
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

      // A fast swipe to the left.
      classifier
        ..handleTouch(
          const TouchDown(
            timestamp: Duration(milliseconds: 100),
            position: 600,
          ),
        )
        ..handleTouch(
          const TouchUp(timestamp: Duration(milliseconds: 150), position: 100),
        );
      await settle();
      expect(events.last, const NavigatePrevious());
      expect(t.session.state.positionIndex, 0);

      await t.expectLoopRepeating('0');
      expect(events.whereType<InputComplete>(), isEmpty);
      expect(t.vibration.callLog, isNot(contains('playError')));

      await subscription.cancel();
      await t.tearDown();
    });
  });
}
