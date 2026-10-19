import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_time.dart';
import '../test_doubles/mock_vibration_service.dart';

// The tests run in fake time: `test` is the one from fake_time.dart. The
// loop's pauses, the classifier's silence timer and a test's waits then
// always end in the same order.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pause between pattern repetitions, short next to a test's waits.
const _repeatPause = Duration(milliseconds: 10);

/// Pause between feedback and the loop resuming.
const _postFeedbackPause = Duration(milliseconds: 20);

/// The classifier's silence timeout. Much longer than the steps of a test,
/// so a stale signal is still pending when the next answer starts, as when
/// a user acts within the real one-second timeout.
const _silenceTimeout = Duration(milliseconds: 200);

/// Well past the silence timeout.
const _afterSilence = Duration(milliseconds: 300);

/// Long enough for the loop to have started and played once.
const _loopStarted = Duration(milliseconds: 20);

/// The pattern of `0`, the first digit (dash x5).
const _zero = [
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
];

/// Every event that navigates when not at a boundary.
const _navigationEvents = <GestureEvent>[
  NavigateNext(),
  NavigatePrevious(),
  Reset(),
  NavigateUp(),
  NavigateDown(),
  Home(),
];

/// Waits [duration] of fake time: the stream events and loop iterations due
/// by then have run, and none due later.
Future<void> settle([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

/// A [MockVibrationService] whose success feedback can be held open until
/// [release] is called, so a test can tap while it is playing.
class _HeldFeedbackVibration extends MockVibrationService {
  /// Whether the next success feedback is held until [release].
  bool holdNextSuccess = false;

  Completer<void>? _held;

  /// Whether a held success feedback is waiting for [release].
  bool get isHolding => _held != null && !_held!.isCompleted;

  /// Lets the held feedback complete and drops any hold not yet taken.
  void release() {
    holdNextSuccess = false;
    if (isHolding) _held!.complete();
  }

  @override
  Future<void> playSuccess() async {
    await super.playSuccess();
    if (!holdNextSuccess) return;
    holdNextSuccess = false;
    _held = Completer<void>();
    await _held!.future;
  }
}

/// An orchestrator wired to a real [GestureClassifier], a fake shake
/// detector and a recording vibration service.
class _Harness {
  _Harness(this.session) {
    subscription = classifier.events.listen(events.add);
    orchestrator = TeachingOrchestrator(
      gestureClassifier: classifier,
      vibrationService: vibration,
      sessionNotifier: session,
      shakeDetector: shake,
      config: const TeachingTimingConfig(
        repeatPause: _repeatPause,
        postFeedbackPause: _postFeedbackPause,
      ),
    );
  }

  final SessionNotifier session;
  final classifier = GestureClassifier(
    screenWidth: 800,
    config: GestureTimingConfig(silenceTimeout: _silenceTimeout.inMilliseconds),
  );
  final vibration = _HeldFeedbackVibration();
  final shake = FakeShakeDetector();
  final events = <GestureEvent>[];
  late final StreamSubscription<GestureEvent> subscription;
  late final TeachingOrchestrator orchestrator;

  SessionPhase get phase => session.state.phase;

  /// The input the classifier has buffered, as the companion overlay shows
  /// it.
  List<MorseToken> get buffer => classifier.inputBufferNotifier.value;

  int count(String call) => vibration.callLog.where((c) => c == call).length;

  /// Taps [signals] on the left (dot) or right (dash) half of the screen.
  void tap(List<MorseSignal> signals) {
    for (final signal in signals) {
      final x = signal == MorseSignal.dot ? 100.0 : 600.0;
      classifier
        ..handleTouch(TouchDown(timestamp: Duration.zero, position: x))
        ..handleTouch(
          TouchUp(timestamp: const Duration(milliseconds: 50), position: x),
        );
    }
  }

  /// Starts the loop and lets it play the first pattern.
  Future<void> start() async {
    orchestrator.start();
    await settle(_loopStarted);
    expect(phase, SessionPhase.playing);
  }

  Future<void> tearDown() async {
    vibration.release();
    await orchestrator.stop();
    await settle(_loopStarted);
    await subscription.cancel();
    orchestrator.dispose();
    classifier.dispose();
    shake.dispose();
  }
}

void main() {
  // -------------------------------------------------------------------------
  // A shake (Home) does not pass through the classifier
  // -------------------------------------------------------------------------
  group('Home from the shake detector', () {
    test('discards a dot tapped just before the shake', () async {
      // On the letters level, at A.
      final t = _Harness(SessionNotifier(MorseLanguage.english)..nextLevel());
      await t.start();

      t.tap([MorseSignal.dot]);
      await settle();
      expect(t.phase, SessionPhase.listening);
      expect(t.buffer, isNotEmpty);

      t.shake.addEvent(const Home());
      await settle();

      // Back on 0, with nothing left over: the overlay shows no input, and
      // the dot's silence timer never completes it.
      expect(t.session.state.currentCharacter, '0');
      expect(t.phase, SessionPhase.playing);
      expect(t.buffer, isEmpty);
      await settle(_afterSilence);
      expect(t.events.whereType<InputComplete>(), isEmpty);

      await t.tearDown();
    });

    test('dot, Home, then the correct answer is accepted', () async {
      final t = _Harness(SessionNotifier(MorseLanguage.english)..nextLevel());
      await t.start();

      t.tap([MorseSignal.dot]);
      await settle();
      t.shake.addEvent(const Home());
      await settle(_loopStarted);
      expect(t.session.state.currentCharacter, '0');

      // Well within the dot's silence timeout.
      t.tap(_zero);
      await settle(_afterSilence);

      final answers = t.events.whereType<InputComplete>().toList();
      expect(answers, [
        InputComplete([for (final s in _zero) Signal(s)]),
      ]);
      expect(t.count('playSuccess'), 1);
      expect(t.count('playError'), 0);

      await t.tearDown();
    });
  });

  // -------------------------------------------------------------------------
  // Taps during feedback are ignored, and must not be kept
  // -------------------------------------------------------------------------
  group('tap during feedback', () {
    /// Answers `0` correctly and leaves the success feedback playing.
    Future<_Harness> startInFeedback() async {
      final t = _Harness(SessionNotifier(MorseLanguage.english));
      await t.start();
      t.vibration.holdNextSuccess = true;
      t.tap(_zero);
      await settle(_afterSilence);
      expect(t.vibration.isHolding, isTrue);
      expect(t.phase, SessionPhase.feedback);
      return t;
    }

    test('is discarded when the loop resumes', () async {
      final t = await startInFeedback();

      t.tap([MorseSignal.dot]);
      await settle();
      expect(t.phase, SessionPhase.feedback);
      expect(t.buffer, isNotEmpty);
      t.events.clear();

      t.vibration.release();
      await settle(_postFeedbackPause + _loopStarted);
      expect(t.phase, SessionPhase.playing);
      expect(t.buffer, isEmpty);

      // The dot's silence timer never completes it.
      await settle(_afterSilence);
      expect(t.events.whereType<InputComplete>(), isEmpty);
      expect(t.phase, SessionPhase.playing);

      await t.tearDown();
    });

    test(
      'dot during feedback, resume, then the correct answer is accepted',
      () async {
        final t = await startInFeedback();

        t.tap([MorseSignal.dot]);
        await settle();
        t.vibration.release();
        await settle(_postFeedbackPause + _loopStarted);
        expect(t.phase, SessionPhase.playing);
        t.events.clear();
        t.vibration.reset();

        // Well within the dot's silence timeout.
        t.tap(_zero);
        await settle(_afterSilence);

        final answers = t.events.whereType<InputComplete>().toList();
        expect(answers, [
          InputComplete([for (final s in _zero) Signal(s)]),
        ]);
        expect(t.count('playSuccess'), 1);
        expect(t.count('playError'), 0);

        await t.tearDown();
      },
    );
  });

  // -------------------------------------------------------------------------
  // Every navigation source clears the input
  // -------------------------------------------------------------------------
  group('navigation clears the classifier input', () {
    for (final event in _navigationEvents) {
      test('$event', () async {
        final gestures = FakeGestureClassifier();
        final shake = FakeShakeDetector();
        // Letters level, at D: every navigation moves the session.
        final session = SessionNotifier(MorseLanguage.english)
          ..nextLevel()
          ..nextPosition()
          ..nextPosition()
          ..nextPosition();
        final orchestrator = TeachingOrchestrator(
          gestureClassifier: gestures,
          vibrationService: MockVibrationService(),
          sessionNotifier: session,
          shakeDetector: shake,
          config: const TeachingTimingConfig(repeatPause: _repeatPause),
        )..start();
        await settle(_loopStarted);
        final sessionBefore = session.state;
        final clearsBefore = gestures.clearInputCallCount;

        if (event is Home) {
          shake.addEvent(event);
        } else {
          gestures.addEvent(event);
        }
        await settle();

        expect(session.state, isNot(sessionBefore));
        expect(gestures.clearInputCallCount, clearsBefore + 1);

        await orchestrator.stop();
        await settle(_loopStarted);
        orchestrator.dispose();
        gestures.dispose();
        shake.dispose();
      });
    }
  });
}
