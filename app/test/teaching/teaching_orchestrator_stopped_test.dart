import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_time.dart';
import '../test_doubles/mock_vibration_service.dart';

// The tests run in fake time: `test` is the one from fake_time.dart. The
// loop's pauses, the classifier's timers and a test's waits then always end
// in the same order.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pause between pattern repetitions, short next to a test's waits.
const _repeatPause = Duration(milliseconds: 10);

/// Pause between feedback and the loop resuming.
const _postFeedbackPause = Duration(milliseconds: 50);

/// Long enough for the loop to have repeated several times.
const _severalRepeatCycles = Duration(milliseconds: 100);

/// The correct answer for the first English character, `0` (dash x5).
const _correctAnswer = InputComplete([
  Signal(MorseSignal.dash),
  Signal(MorseSignal.dash),
  Signal(MorseSignal.dash),
  Signal(MorseSignal.dash),
  Signal(MorseSignal.dash),
]);

/// Every event that would navigate (and so restart the loop) when running.
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

/// An orchestrator wired to test doubles, including a shake detector.
class _Harness {
  _Harness({
    GestureClassifier? classifier,
    MockVibrationService? vibration,
    Duration postFeedbackPause = _postFeedbackPause,
  }) : classifier = classifier ?? FakeGestureClassifier(),
       vibration = vibration ?? MockVibrationService() {
    orchestrator = TeachingOrchestrator(
      gestureClassifier: this.classifier,
      vibrationService: this.vibration,
      sessionNotifier: session,
      shakeDetector: shake,
      config: TeachingTimingConfig(
        repeatPause: _repeatPause,
        postFeedbackPause: postFeedbackPause,
      ),
    );
  }

  final GestureClassifier classifier;
  final MockVibrationService vibration;
  final session = SessionNotifier(MorseLanguage.english);
  final shake = FakeShakeDetector();
  late final TeachingOrchestrator orchestrator;

  /// The classifier as a fake, for tests that inject events directly.
  FakeGestureClassifier get gestures => classifier as FakeGestureClassifier;

  /// Moves away from the home position (level 0, position 0), so that a
  /// handled [Home] or [Reset] would be visible in the session state.
  void moveAwayFromHome() {
    session
      ..nextLevel()
      ..nextPosition();
  }

  int get feedbackCount => vibration.calls
      .where(
        (c) =>
            c.type == VibrationCallType.playSuccess ||
            c.type == VibrationCallType.playError,
      )
      .length;

  Future<void> tearDown() async {
    await orchestrator.stop();
    await settle(const Duration(milliseconds: 20));
    orchestrator.dispose();
    classifier.dispose();
    shake.dispose();
  }
}

/// A [MockVibrationService] whose success feedback only completes when
/// [finishFeedback] is called, so a test can act while it is in flight.
class _SlowFeedbackVibration extends MockVibrationService {
  Completer<void>? _feedback;

  /// Whether a success feedback is currently playing.
  bool get isPlayingFeedback => _feedback != null && !_feedback!.isCompleted;

  void finishFeedback() => _feedback?.complete();

  @override
  Future<void> playSuccess() async {
    await super.playSuccess();
    _feedback = Completer<void>();
    await _feedback!.future;
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Events are ignored while the loop is stopped
  // -------------------------------------------------------------------------
  group('while stopped', () {
    test('Home from the shake detector does not restart the loop', () async {
      final t = _Harness()..moveAwayFromHome();
      final sessionBefore = t.session.state;
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      await t.orchestrator.stop();
      await settle();
      t.vibration.reset();

      t.shake.addEvent(const Home());
      await settle(_severalRepeatCycles);

      expect(t.vibration.calls, isEmpty);
      expect(t.orchestrator.state.isRunning, isFalse);
      expect(t.session.state.levelIndex, sessionBefore.levelIndex);
      expect(t.session.state.positionIndex, sessionBefore.positionIndex);

      await t.tearDown();
    });

    test('swipe, reset and navigation events are ignored', () async {
      final t = _Harness()..moveAwayFromHome();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      await t.orchestrator.stop();
      await settle();
      final sessionBefore = t.session.state;
      t.vibration.reset();

      for (final event in _navigationEvents) {
        t.gestures.addEvent(event);
        await settle();
        expect(t.orchestrator.state.isRunning, isFalse, reason: '$event');
        expect(t.session.state, sessionBefore, reason: '$event');
      }
      await settle(_severalRepeatCycles);

      expect(t.vibration.calls, isEmpty);
      expect(t.orchestrator.state.isRunning, isFalse);
      expect(t.session.state, sessionBefore);

      await t.tearDown();
    });

    test('taps and bottom-zone actions are ignored', () async {
      final t = _Harness();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      await t.orchestrator.stop();
      await settle();
      final sessionBefore = t.session.state;
      t.vibration.reset();

      t.gestures
        ..addEvent(const MorseInput(MorseSignal.dot))
        ..addEvent(const BottomZoneAction())
        ..addEvent(_correctAnswer);
      await settle(_severalRepeatCycles);

      expect(t.vibration.calls, isEmpty);
      expect(t.session.state, sessionBefore);
      expect(t.gestures.insertCharGapCallCount, 0);
      expect(t.gestures.submitInputCallCount, 0);

      await t.tearDown();
    });

    test('events before the first start() are ignored', () async {
      final t = _Harness()..moveAwayFromHome();
      final sessionBefore = t.session.state;

      t.shake.addEvent(const Home());
      t.gestures.addEvent(const NavigateNext());
      await settle(_severalRepeatCycles);

      expect(t.vibration.calls, isEmpty);
      expect(t.orchestrator.state.isRunning, isFalse);
      expect(t.session.state, sessionBefore);

      await t.tearDown();
    });

    test('events after dispose are ignored without errors', () async {
      final t = _Harness();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      t.orchestrator.dispose();
      t.vibration.reset();

      t.shake.addEvent(const Home());
      t.gestures.addEvent(const MorseInput(MorseSignal.dot));
      await settle(_severalRepeatCycles);

      expect(t.vibration.calls, isEmpty);

      t.gestures.dispose();
      t.shake.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Pending input is discarded on stop
  // -------------------------------------------------------------------------
  group('pending input', () {
    test('stop() clears the classifier input', () async {
      final t = _Harness();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      final clearsBefore = t.gestures.clearInputCallCount;

      await t.orchestrator.stop();

      expect(t.gestures.clearInputCallCount, clearsBefore + 1);

      await t.tearDown();
    });

    test(
      'partial input then stop(): a late InputComplete plays no feedback',
      () async {
        final t = _Harness();
        t.orchestrator.start();
        await settle(const Duration(milliseconds: 20));
        t.gestures.addEvent(const MorseInput(MorseSignal.dash));
        await settle();
        expect(t.session.state.phase, SessionPhase.listening);

        await t.orchestrator.stop();
        t.vibration.reset();

        // The classifier's silence timer fires after the stop.
        t.gestures.addEvent(_correctAnswer);
        await settle(_severalRepeatCycles);

        expect(t.feedbackCount, 0);
        expect(t.vibration.calls, isEmpty);
        expect(t.orchestrator.state.isRunning, isFalse);

        await t.tearDown();
      },
    );

    test(
      'with a real classifier, a half-entered pattern is never judged',
      () async {
        final classifier = GestureClassifier(
          screenWidth: 800,
          config: const GestureTimingConfig(silenceTimeout: 50),
        );
        final events = <GestureEvent>[];
        final subscription = classifier.events.listen(events.add);
        final t = _Harness(classifier: classifier);
        t.orchestrator.start();
        await settle(const Duration(milliseconds: 20));

        // One dot of a longer pattern, then the app is backgrounded.
        classifier
          ..handleTouch(const TouchDown(timestamp: Duration.zero, position: 1))
          ..handleTouch(
            const TouchUp(timestamp: Duration(milliseconds: 50), position: 1),
          );
        await settle();
        expect(t.session.state.phase, SessionPhase.listening);
        expect(classifier.inputBufferNotifier.value, isNotEmpty);

        await t.orchestrator.stop();
        expect(classifier.inputBufferNotifier.value, isEmpty);

        // Well past the silence timeout: nothing is judged while stopped.
        await settle(const Duration(milliseconds: 150));
        expect(events.whereType<InputComplete>(), isEmpty);
        expect(t.feedbackCount, 0);

        // Nor after the loop is started again.
        t.orchestrator.start();
        await settle(const Duration(milliseconds: 150));
        expect(events.whereType<InputComplete>(), isEmpty);
        expect(t.feedbackCount, 0);
        expect(t.vibration.patterns, isNotEmpty);

        await subscription.cancel();
        await t.tearDown();
      },
    );

    test('input buffered while stopped is discarded by start()', () async {
      final classifier = GestureClassifier(
        screenWidth: 800,
        config: const GestureTimingConfig(silenceTimeout: 50),
      );
      final events = <GestureEvent>[];
      final subscription = classifier.events.listen(events.add);
      final t = _Harness(classifier: classifier);
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      await t.orchestrator.stop();

      // A tap reaches the classifier while the loop is stopped. Its
      // MorseInput is ignored, but the classifier still buffers it.
      classifier
        ..handleTouch(const TouchDown(timestamp: Duration.zero, position: 1))
        ..handleTouch(
          const TouchUp(timestamp: Duration(milliseconds: 50), position: 1),
        );
      await settle();
      expect(classifier.inputBufferNotifier.value, isNotEmpty);

      t.orchestrator.start();
      expect(classifier.inputBufferNotifier.value, isEmpty);

      await settle(const Duration(milliseconds: 150));
      expect(events.whereType<InputComplete>(), isEmpty);
      expect(t.feedbackCount, 0);

      await subscription.cancel();
      await t.tearDown();
    });
  });

  // -------------------------------------------------------------------------
  // Feedback already in flight when the loop stops
  // -------------------------------------------------------------------------
  group('feedback in flight', () {
    test(
      'stop() during the feedback vibration does not resume the loop',
      () async {
        final vibration = _SlowFeedbackVibration();
        final t = _Harness(vibration: vibration);
        t.orchestrator.start();
        await settle(const Duration(milliseconds: 20));
        t.gestures.addEvent(const MorseInput(MorseSignal.dash));
        await settle();
        t.gestures.addEvent(_correctAnswer);
        await settle();
        expect(vibration.isPlayingFeedback, isTrue);
        expect(t.session.state.phase, SessionPhase.feedback);

        await t.orchestrator.stop();
        vibration
          ..finishFeedback()
          ..reset();
        await settle(_postFeedbackPause + _severalRepeatCycles);

        expect(vibration.calls, isEmpty);
        expect(t.orchestrator.state.isRunning, isFalse);
        // The phase is left as is; start() resets it to playing.
        expect(t.session.state.phase, SessionPhase.feedback);

        t.orchestrator.start();
        await settle();
        expect(t.session.state.phase, SessionPhase.playing);
        expect(vibration.patterns, hasLength(1));

        await t.tearDown();
      },
    );

    test(
      'stop() during the post-feedback pause does not resume the loop',
      () async {
        final t = _Harness();
        t.orchestrator.start();
        await settle(const Duration(milliseconds: 20));
        t.gestures.addEvent(const MorseInput(MorseSignal.dash));
        await settle();
        t.gestures.addEvent(_correctAnswer);
        await settle(const Duration(milliseconds: 10));
        expect(t.vibration.callLog, contains('playSuccess'));
        expect(t.session.state.phase, SessionPhase.feedback);

        await t.orchestrator.stop();
        t.vibration.reset();
        await settle(_postFeedbackPause + _severalRepeatCycles);

        expect(t.vibration.calls, isEmpty);
        expect(t.orchestrator.state.isRunning, isFalse);
        expect(t.session.state.phase, SessionPhase.feedback);

        // Resume starts cleanly from the playing phase.
        t.orchestrator.start();
        await settle();
        expect(t.session.state.phase, SessionPhase.playing);
        expect(t.vibration.patterns, hasLength(1));

        await t.tearDown();
      },
    );

    test('a stale feedback sequence does not cut short a newer one', () async {
      // Long post-feedback pause so the two feedback sequences overlap.
      const pause = Duration(milliseconds: 300);
      final t = _Harness(postFeedbackPause: pause);
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));

      // First feedback, then a quick background/foreground trip.
      t.gestures.addEvent(const MorseInput(MorseSignal.dash));
      await settle();
      t.gestures.addEvent(_correctAnswer);
      await settle(const Duration(milliseconds: 10));
      await t.orchestrator.stop();
      t.orchestrator.start();

      // Second feedback starts ~150ms into the first one's pause.
      await settle(const Duration(milliseconds: 140));
      t.gestures.addEvent(const MorseInput(MorseSignal.dot));
      await settle();
      t.gestures.addEvent(const InputComplete([Signal(MorseSignal.dot)]));
      await settle();
      expect(t.vibration.callLog.last, 'playError');
      t.vibration.reset();

      // The first sequence's pause ends (~300ms) while the second one is
      // still pausing (until ~450ms): the loop must not resume yet.
      await settle(const Duration(milliseconds: 225));
      expect(t.vibration.patterns, isEmpty);
      expect(t.session.state.phase, SessionPhase.feedback);

      // The second sequence resumes the loop once its own pause is over.
      await settle(const Duration(milliseconds: 200));
      expect(t.vibration.patterns, isNotEmpty);
      expect(t.session.state.phase, SessionPhase.playing);

      await t.tearDown();
    });
  });

  // -------------------------------------------------------------------------
  // Shake detection is paused while stopped
  // -------------------------------------------------------------------------
  group('shake detector', () {
    test('stop() pauses and start() resumes shake detection', () async {
      final t = _Harness();
      t.orchestrator.start();
      await settle();
      expect(t.shake.isPaused, isFalse);

      await t.orchestrator.stop();
      expect(t.shake.isPaused, isTrue);

      t.orchestrator.start();
      expect(t.shake.isPaused, isFalse);

      await t.tearDown();
    });
  });

  // -------------------------------------------------------------------------
  // Normal handling resumes after start()
  // -------------------------------------------------------------------------
  group('after start()', () {
    test(
      'Home from the shake detector navigates and restarts the loop',
      () async {
        final t = _Harness()..moveAwayFromHome();
        t.orchestrator.start();
        await settle(const Duration(milliseconds: 20));
        await t.orchestrator.stop();
        t.orchestrator.start();
        await settle(const Duration(milliseconds: 20));
        t.vibration.reset();

        t.shake.addEvent(const Home());
        await settle(const Duration(milliseconds: 30));

        expect(t.orchestrator.state.isRunning, isTrue);
        expect(t.session.state.levelIndex, 0);
        expect(t.session.state.positionIndex, 0);
        expect(t.vibration.callLog, contains('cancel'));
        expect(t.vibration.patterns, isNotEmpty);

        await t.tearDown();
      },
    );

    test('swipes navigate again', () async {
      final t = _Harness();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      await t.orchestrator.stop();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));

      t.gestures.addEvent(const NavigateNext());
      await settle(const Duration(milliseconds: 20));
      expect(t.session.state.positionIndex, 1);

      t.gestures.addEvent(const NavigateUp());
      await settle(const Duration(milliseconds: 20));
      expect(t.session.state.levelIndex, 1);
      expect(t.session.state.positionIndex, 0);
      expect(t.orchestrator.state.isRunning, isTrue);

      await t.tearDown();
    });

    test('input is judged and feedback played again', () async {
      final t = _Harness();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));
      await t.orchestrator.stop();
      t.orchestrator.start();
      await settle(const Duration(milliseconds: 20));

      t.gestures.addEvent(const MorseInput(MorseSignal.dash));
      await settle();
      expect(t.session.state.phase, SessionPhase.listening);

      t.gestures.addEvent(_correctAnswer);
      await settle(_postFeedbackPause + const Duration(milliseconds: 30));

      expect(t.vibration.callLog, contains('playSuccess'));
      expect(t.session.state.phase, SessionPhase.playing);

      await t.tearDown();
    });
  });
}
