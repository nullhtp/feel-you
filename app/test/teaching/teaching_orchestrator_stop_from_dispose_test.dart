import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_time.dart';
import '../test_doubles/mock_vibration_service.dart';

// TeachingOrchestrator.stopFromDispose silences the loop at once but leaves
// the state change for after the frame (issue #23).
//
// The tests run in fake time: `test` is the one from fake_time.dart. The
// loop's pauses and a test's waits then always end in the same order.

/// Pause between pattern repetitions, short next to a test's waits.
const _repeatPause = Duration(milliseconds: 10);

/// Long enough for the loop to have repeated several times.
const _severalRepeatCycles = Duration(milliseconds: 100);

/// Waits [duration] of fake time: the stream events, microtasks and loop
/// iterations due by then have run, and none due later.
Future<void> _settle([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

class _Harness {
  _Harness() {
    orchestrator = TeachingOrchestrator(
      gestureClassifier: gestures,
      vibrationService: vibration,
      sessionNotifier: session,
      shakeDetector: shake,
      config: const TeachingTimingConfig(repeatPause: _repeatPause),
    );
    // Fires once immediately with the initial state.
    orchestrator.addListener(states.add);
  }

  final gestures = FakeGestureClassifier();
  final vibration = MockVibrationService();
  final session = SessionNotifier(MorseLanguage.english);
  final shake = FakeShakeDetector();
  late final TeachingOrchestrator orchestrator;

  /// Every state the orchestrator notified its listeners of.
  final states = <TeachingOrchestratorState>[];

  bool get isRunning => states.last.isRunning;

  Future<void> tearDown() async {
    await orchestrator.stop();
    await _settle(const Duration(milliseconds: 20));
    orchestrator.dispose();
    gestures.dispose();
    shake.dispose();
  }
}

void main() {
  test('silences the loop at once and publishes the state later', () async {
    final h = _Harness();
    h.orchestrator.start();
    await _settle();
    h.vibration.reset();
    final notified = h.states.length;
    final clears = h.gestures.clearInputCallCount;

    h.orchestrator.stopFromDispose();

    // Nothing is notified synchronously...
    expect(h.states, hasLength(notified));
    // ...but the phone goes quiet and input is shut off right away.
    expect(h.vibration.callLog, ['cancel']);
    expect(h.shake.isPaused, isTrue);
    expect(h.gestures.clearInputCallCount, clears + 1);

    await _settle();
    expect(h.states, hasLength(notified + 1));
    expect(h.states.last.isRunning, isFalse);
    expect(h.states.last.isInterrupted, isTrue);

    // The loop does not come back.
    await _settle(_severalRepeatCycles);
    expect(h.vibration.callLog, ['cancel']);

    await h.tearDown();
  });

  test('ignores a gesture that was already on its way', () async {
    final h = _Harness();
    h.orchestrator.start();
    await _settle();
    h.vibration.reset();
    final position = h.session.state.positionIndex;

    // Delivered after stopFromDispose, before the state is published.
    h.gestures.addEvent(const NavigateNext());
    h.orchestrator.stopFromDispose();
    await _settle(_severalRepeatCycles);

    expect(h.session.state.positionIndex, position);
    expect(h.vibration.patterns, isEmpty);
    expect(h.isRunning, isFalse);

    await h.tearDown();
  });

  test('a start before the state is published restarts the loop', () async {
    final h = _Harness();
    h.orchestrator.start();
    await _settle();
    h.vibration.reset();

    h.orchestrator
      ..stopFromDispose()
      ..start();
    await _settle();

    expect(h.isRunning, isTrue);
    expect(h.shake.isPaused, isFalse);
    expect(h.vibration.patterns, hasLength(1));

    await h.tearDown();
  });

  test('does nothing while the loop is stopped', () async {
    final h = _Harness();
    final notified = h.states.length;

    h.orchestrator.stopFromDispose();
    await _settle();

    expect(h.states, hasLength(notified));
    expect(h.vibration.calls, isEmpty);

    await h.tearDown();
  });
}
