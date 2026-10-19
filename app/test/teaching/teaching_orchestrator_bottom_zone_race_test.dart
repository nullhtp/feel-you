import 'dart:async';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_time.dart';
import '../test_doubles/fixed_levels_session.dart';
import '../test_doubles/mock_vibration_service.dart';

// The tests run in fake time: `test` is the one from fake_time.dart. The
// loop's pauses and a test's waits then always end in the same order.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pause between pattern repetitions, short next to a test's waits.
const _repeatPause = Duration(milliseconds: 10);

/// Silence between the letters of a spelled word, short next to a test's
/// waits.
const _spellingLetterGap = Duration(milliseconds: 10);

/// Long enough for the loop to have started and played once.
const _loopStarted = Duration(milliseconds: 20);

/// Long enough for the loop to have repeated several times.
const _severalRepeatCycles = Duration(milliseconds: 100);

/// Waits [duration] of fake time: the stream events and loop iterations due
/// by then have run, and none due later.
Future<void> settle([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

/// A [MockVibrationService] that can hold the next [playTapFeedback] call
/// open until the test calls [release], so the test can act while the
/// orchestrator is awaiting it.
///
/// Only the call that follows [holdNextTapFeedback] is held; later calls
/// complete at once.
class _HeldVibration extends MockVibrationService {
  Completer<void>? _nextTapFeedback;
  Completer<void>? _held;

  /// Holds the next [playTapFeedback] call open until [release] is called.
  void holdNextTapFeedback() => _nextTapFeedback = Completer<void>();

  /// Whether a held call has started and is waiting for [release].
  bool get isHolding => _held != null && !_held!.isCompleted;

  /// Lets the held call complete and drops any hold not yet taken.
  void release() {
    _nextTapFeedback = null;
    if (isHolding) _held!.complete();
  }

  @override
  Future<void> playTapFeedback() async {
    await super.playTapFeedback();
    final hold = _nextTapFeedback;
    _nextTapFeedback = null;
    if (hold == null) return;
    _held = hold;
    await hold.future;
  }
}

/// An orchestrator wired to test doubles, including a shake detector.
class _Harness {
  _Harness(this.session) {
    orchestrator = TeachingOrchestrator(
      gestureClassifier: gestures,
      vibrationService: vibration,
      sessionNotifier: session,
      shakeDetector: shake,
      config: const TeachingTimingConfig(
        repeatPause: _repeatPause,
        spellingLetterGap: _spellingLetterGap,
      ),
    );
  }

  /// A harness on the English words level, at the second word.
  ///
  /// The levels are ordered words (0), letters (1), digits (2), so [Home]
  /// lands on another word of the same words level: the case in which a
  /// stale char gap would corrupt the next answer.
  factory _Harness.words() => _Harness(
    FixedLevelsSessionNotifier(
      FixedLevelsSessionState(
        levels: reorderedEnglishLevels(),
        language: MorseLanguage.english,
        positionIndex: 1,
      ),
    ),
  );

  /// A harness on the digits level (a characters level), at digit `3`.
  factory _Harness.digits() => _Harness(
    SessionNotifier(MorseLanguage.english)
      ..nextPosition()
      ..nextPosition()
      ..nextPosition(),
  );

  final SessionNotifier session;
  final gestures = FakeGestureClassifier();
  final vibration = _HeldVibration();
  final shake = FakeShakeDetector();
  late final TeachingOrchestrator orchestrator;

  SessionPhase get phase => session.state.phase;

  /// How many word token patterns were played since the vibration calls
  /// were last reset.
  int get tokenPlaybacks => vibration.calls
      .where((c) => c.type == VibrationCallType.playMorseTokenPattern)
      .length;

  /// Starts the loop and lets it play the first pattern.
  Future<void> start() async {
    orchestrator.start();
    await settle(_loopStarted);
    expect(phase, SessionPhase.playing);
  }

  /// Taps once, interrupting playback, so the session is listening.
  Future<void> startListening() async {
    gestures.addEvent(const MorseInput(MorseSignal.dot));
    await settle();
    expect(phase, SessionPhase.listening);
  }

  /// Sends a bottom-zone action and waits until it is stuck in the held
  /// vibration call.
  Future<void> bottomZoneActionUntilHeld() async {
    gestures.addEvent(const BottomZoneAction());
    await settle();
    expect(vibration.isHolding, isTrue);
  }

  Future<void> tearDown() async {
    vibration.release();
    await orchestrator.stop();
    await settle(_loopStarted);
    orchestrator.dispose();
    gestures.dispose();
    shake.dispose();
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Words level, bottom-zone action during listening
  // -------------------------------------------------------------------------
  group('words level, bottom-zone action during listening', () {
    test('Home during playTapFeedback(): no char gap is inserted', () async {
      final t = _Harness.words();
      await t.start();
      await t.startListening();

      t.vibration.holdNextTapFeedback();
      await t.bottomZoneActionUntilHeld();

      t.shake.addEvent(const Home());
      await settle();
      expect(t.session.state.positionIndex, 0);
      expect(t.phase, SessionPhase.playing);

      t.vibration
        ..reset()
        ..release();
      await settle(_severalRepeatCycles);

      expect(t.gestures.insertCharGapCallCount, 0);
      expect(t.phase, SessionPhase.playing);
      expect(t.tokenPlaybacks, greaterThan(1));

      await t.tearDown();
    });

    test('without navigation: inserts a char gap', () async {
      final t = _Harness.words();
      await t.start();
      await t.startListening();

      t.vibration.holdNextTapFeedback();
      await t.bottomZoneActionUntilHeld();
      expect(t.gestures.insertCharGapCallCount, 0);

      t.vibration.release();
      await settle();

      expect(t.gestures.insertCharGapCallCount, 1);
      expect(t.phase, SessionPhase.listening);

      await t.tearDown();
    });
  });

  // -------------------------------------------------------------------------
  // Character level, bottom-zone action during listening
  // -------------------------------------------------------------------------
  group('character level, bottom-zone action during listening', () {
    test('Home during playTapFeedback(): the input is not submitted', () async {
      final t = _Harness.digits();
      await t.start();
      await t.startListening();

      t.vibration.holdNextTapFeedback();
      await t.bottomZoneActionUntilHeld();

      t.shake.addEvent(const Home());
      await settle();
      expect(t.session.state.currentCharacter, '0');
      expect(t.phase, SessionPhase.playing);

      t.vibration
        ..reset()
        ..release();
      await settle(_severalRepeatCycles);

      expect(t.gestures.submitInputCallCount, 0);
      expect(t.phase, SessionPhase.playing);
      expect(t.vibration.patterns.length, greaterThan(1));

      await t.tearDown();
    });

    test('without navigation: submits the input', () async {
      final t = _Harness.digits();
      await t.start();
      await t.startListening();

      t.vibration.holdNextTapFeedback();
      await t.bottomZoneActionUntilHeld();
      expect(t.gestures.submitInputCallCount, 0);

      t.vibration.release();
      await settle();

      expect(t.gestures.submitInputCallCount, 1);
      expect(t.gestures.insertCharGapCallCount, 0);

      await t.tearDown();
    });
  });
}
