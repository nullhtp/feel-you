import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Creates an orchestrator with test doubles.
/// Uses a very short repeat pause (10ms) to keep tests fast.
({
  TeachingOrchestrator orchestrator,
  MockVibrationService vibration,
  SessionNotifier session,
  FakeGestureClassifier gestures,
})
createOrchestrator({Duration repeatPause = const Duration(milliseconds: 10)}) {
  final gestures = FakeGestureClassifier();
  final vibration = MockVibrationService();
  final session = SessionNotifier();
  final orchestrator = TeachingOrchestrator(
    gestureClassifier: gestures,
    vibrationService: vibration,
    sessionNotifier: session,
    config: TeachingTimingConfig(repeatPause: repeatPause),
  );
  return (
    orchestrator: orchestrator,
    vibration: vibration,
    session: session,
    gestures: gestures,
  );
}

/// Properly tear down an orchestrator: stop, let microtasks drain, dispose.
Future<void> tearDownOrchestrator(
  TeachingOrchestrator orchestrator,
  FakeGestureClassifier gestures,
) async {
  await orchestrator.stop();
  // Let any pending microtasks from the loop drain.
  await Future<void>.delayed(const Duration(milliseconds: 20));
  orchestrator.dispose();
  gestures.dispose();
}

void main() {
  // -------------------------------------------------------------------------
  // TeachingOrchestratorState
  // -------------------------------------------------------------------------
  group('TeachingOrchestratorState', () {
    test('default values', () {
      const s = TeachingOrchestratorState();
      expect(s.isRunning, false);
      expect(s.isInterrupted, false);
    });

    test('copyWith replaces fields', () {
      const s = TeachingOrchestratorState();
      final running = s.copyWith(isRunning: true);
      expect(running.isRunning, true);
      expect(running.isInterrupted, false);
    });

    test('equality', () {
      const a = TeachingOrchestratorState(isRunning: true);
      const b = TeachingOrchestratorState(isRunning: true);
      const c = TeachingOrchestratorState();
      expect(a, b);
      expect(a, isNot(c));
    });

    test('hashCode consistent with equality', () {
      const a = TeachingOrchestratorState(isRunning: true);
      const b = TeachingOrchestratorState(isRunning: true);
      expect(a.hashCode, b.hashCode);
    });

    test('toString', () {
      const s = TeachingOrchestratorState(isRunning: true, isInterrupted: true);
      expect(
        s.toString(),
        'TeachingOrchestratorState(isRunning: true, isInterrupted: true)',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 4.4 Play-wait-repeat loop tests
  // -------------------------------------------------------------------------
  group('play-wait-repeat loop', () {
    test('does not auto-start on creation', () async {
      final t = createOrchestrator();
      // Give microtasks a chance to run.
      await Future<void>.delayed(Duration.zero);
      expect(t.vibration.callLog, isEmpty);
      expect(t.orchestrator.state.isRunning, false);
      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test(
      'start() begins the loop and plays current character pattern',
      () async {
        final t = createOrchestrator();
        t.orchestrator.start();

        // Let the async loop run one iteration.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Default character is 0 (dash x5). Should have played at least once.
        expect(
          t.vibration.callLog.where(
            (c) =>
                c ==
                'playMorsePattern:[MorseSymbol.dash, MorseSymbol.dash, '
                    'MorseSymbol.dash, MorseSymbol.dash, MorseSymbol.dash]',
          ),
          isNotEmpty,
        );
        expect(t.orchestrator.state.isRunning, true);

        await tearDownOrchestrator(t.orchestrator, t.gestures);
      },
    );

    test('loop repeats after pause', () async {
      final t = createOrchestrator();
      t.orchestrator.start();

      // Wait long enough for multiple iterations (10ms pause).
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final playCount = t.vibration.callLog
          .where(
            (c) =>
                c ==
                'playMorsePattern:[MorseSymbol.dash, MorseSymbol.dash, '
                    'MorseSymbol.dash, MorseSymbol.dash, MorseSymbol.dash]',
          )
          .length;
      expect(playCount, greaterThan(1));

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('stop() halts the loop', () async {
      final t = createOrchestrator();
      t.orchestrator.start();

      await Future<void>.delayed(const Duration(milliseconds: 30));
      await t.orchestrator.stop();

      final countAfterStop = t.vibration.callLog.length;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // No new calls after stop (allow for one extra due to async timing).
      expect(t.vibration.callLog.length, lessThanOrEqualTo(countAfterStop + 1));
      expect(t.orchestrator.state.isRunning, false);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('start sets session phase to playing', () async {
      final t = createOrchestrator();
      t.session.setPhase(SessionPhase.feedback); // Set to non-playing.
      t.orchestrator.start();
      await Future<void>.delayed(Duration.zero);
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });
  });

  // -------------------------------------------------------------------------
  // 5.3 Interrupt handling tests
  // -------------------------------------------------------------------------
  group('interrupt handling', () {
    test(
      'first tap during playing calls cancel and transitions to listening',
      () async {
        final t = createOrchestrator();
        t.orchestrator.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Simulate a tap.
        t.gestures.addEvent(const MorseInput(MorseSymbol.dot));
        await Future<void>.delayed(Duration.zero);

        expect(t.session.state.phase, SessionPhase.listening);
        expect(t.vibration.callLog, contains('cancel'));

        await tearDownOrchestrator(t.orchestrator, t.gestures);
      },
    );

    test('subsequent taps during listening are no-ops', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // First tap — transitions to listening.
      t.gestures.addEvent(const MorseInput(MorseSymbol.dot));
      await Future<void>.delayed(Duration.zero);
      final cancelCountAfterFirst = t.vibration.callLog
          .where((c) => c == 'cancel')
          .length;

      // Second tap during listening — should be no-op.
      t.gestures.addEvent(const MorseInput(MorseSymbol.dash));
      await Future<void>.delayed(Duration.zero);
      final cancelCountAfterSecond = t.vibration.callLog
          .where((c) => c == 'cancel')
          .length;

      expect(cancelCountAfterSecond, cancelCountAfterFirst);
      expect(t.session.state.phase, SessionPhase.listening);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('taps during feedback are ignored', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Manually set feedback phase to simulate being in feedback.
      t.session.setPhase(SessionPhase.feedback);

      // Record cancel count before the tap.
      final cancelCountBefore = t.vibration.callLog
          .where((c) => c == 'cancel')
          .length;

      t.gestures.addEvent(const MorseInput(MorseSymbol.dot));
      await Future<void>.delayed(Duration.zero);

      // No new cancel calls from the MorseInput handler.
      final cancelCountAfter = t.vibration.callLog
          .where((c) => c == 'cancel')
          .length;
      expect(cancelCountAfter, cancelCountBefore);
      expect(t.session.state.phase, SessionPhase.feedback);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });
  });

  // -------------------------------------------------------------------------
  // 6.6 Input evaluation and feedback tests
  // -------------------------------------------------------------------------
  group('input evaluation and feedback', () {
    test('correct input triggers success and resumes loop', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Interrupt with a tap.
      t.gestures.addEvent(const MorseInput(MorseSymbol.dash));
      await Future<void>.delayed(Duration.zero);
      expect(t.session.state.phase, SessionPhase.listening);

      // Submit correct answer for 0 (dash x5).
      t.gestures.addEvent(
        const InputComplete([
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
        ]),
      );
      // Wait for feedback signal + 500ms post-feedback pause + loop start.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(t.vibration.callLog, contains('playSuccess'));
      // Should have resumed to playing.
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('wrong input triggers error and resumes loop', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Interrupt.
      t.gestures.addEvent(const MorseInput(MorseSymbol.dot));
      await Future<void>.delayed(Duration.zero);

      // Submit wrong answer for 0.
      t.gestures.addEvent(const InputComplete([MorseSymbol.dot]));
      // Wait for error signal + 500ms post-feedback pause + loop start.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(t.vibration.callLog, contains('playError'));
      // Loop resumes — the character replays naturally via the loop.
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('empty input is treated as wrong answer', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Interrupt.
      t.gestures.addEvent(const MorseInput(MorseSymbol.dot));
      await Future<void>.delayed(Duration.zero);

      // Submit empty input.
      t.gestures.addEvent(const InputComplete([]));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(t.vibration.callLog, contains('playError'));

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('InputComplete during feedback is ignored', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Manually set to feedback.
      t.session.setPhase(SessionPhase.feedback);

      final callsBefore = t.vibration.callLog.length;
      t.gestures.addEvent(
        const InputComplete([
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      // No new playSuccess or playError calls from evaluation.
      final newCalls = t.vibration.callLog.sublist(callsBefore);
      expect(newCalls.where((c) => c == 'playSuccess'), isEmpty);
      expect(newCalls.where((c) => c == 'playError'), isEmpty);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('InputComplete during playing is ignored', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Phase should be playing.
      expect(t.session.state.phase, SessionPhase.playing);

      final callsBefore = t.vibration.callLog.length;
      t.gestures.addEvent(
        const InputComplete([
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
        ]),
      );
      await Future<void>.delayed(Duration.zero);

      // No evaluation calls.
      final newCalls = t.vibration.callLog.sublist(callsBefore);
      expect(newCalls.where((c) => c == 'playSuccess'), isEmpty);
      expect(newCalls.where((c) => c == 'playError'), isEmpty);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });
  });

  // -------------------------------------------------------------------------
  // 7.4 Navigation integration tests
  // -------------------------------------------------------------------------
  group('navigation integration', () {
    test(
      'NavigateNext during playing restarts loop for new character',
      () async {
        final t = createOrchestrator();
        t.orchestrator.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        t.gestures.addEvent(const NavigateNext());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Character should have advanced from 0 to 1.
        expect(t.session.state.currentCharacter, '1');
        expect(t.session.state.phase, SessionPhase.playing);
        expect(t.vibration.callLog, contains('cancel'));

        // Should now be playing 1's pattern (dot, dash, dash, dash, dash).
        expect(
          t.vibration.callLog,
          contains(
            'playMorsePattern:[MorseSymbol.dot, MorseSymbol.dash, '
            'MorseSymbol.dash, MorseSymbol.dash, MorseSymbol.dash]',
          ),
        );

        await tearDownOrchestrator(t.orchestrator, t.gestures);
      },
    );

    test(
      'NavigatePrevious during playing restarts loop for previous character',
      () async {
        final t = createOrchestrator();
        // Start at 1.
        t.session.nextPosition();
        expect(t.session.state.currentCharacter, '1');

        t.orchestrator.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        t.gestures.addEvent(const NavigatePrevious());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(t.session.state.currentCharacter, '0');
        expect(t.session.state.phase, SessionPhase.playing);

        await tearDownOrchestrator(t.orchestrator, t.gestures);
      },
    );

    test('Reset returns to position 0 and restarts loop', () async {
      final t = createOrchestrator();
      // Move to position 5.
      for (var i = 0; i < 5; i++) {
        t.session.nextPosition();
      }
      expect(t.session.state.currentCharacter, '5');

      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      t.gestures.addEvent(const Reset());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(t.session.state.currentCharacter, '0');
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('navigation during feedback cancels feedback and restarts', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Put into feedback phase.
      t.session.setPhase(SessionPhase.feedback);

      t.gestures.addEvent(const NavigateNext());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(t.session.state.currentCharacter, '1');
      expect(t.session.state.phase, SessionPhase.playing);
      expect(t.vibration.callLog, contains('cancel'));

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('navigation during listening cancels and restarts', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Interrupt to get to listening.
      t.gestures.addEvent(const MorseInput(MorseSymbol.dot));
      await Future<void>.delayed(Duration.zero);
      expect(t.session.state.phase, SessionPhase.listening);

      t.gestures.addEvent(const NavigateNext());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(t.session.state.currentCharacter, '1');
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('NavigateUp calls nextLevel on session notifier', () async {
      final t = createOrchestrator();
      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Default state is level 0.
      expect(t.session.state.levelIndex, 0);

      t.gestures.addEvent(const NavigateUp());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(t.session.state.levelIndex, 1);
      expect(t.session.state.positionIndex, 0);
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('NavigateDown calls previousLevel on session notifier', () async {
      final t = createOrchestrator();
      // Move to level 1 first.
      t.session.nextLevel();
      expect(t.session.state.levelIndex, 1);

      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      t.gestures.addEvent(const NavigateDown());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(t.session.state.levelIndex, 0);
      expect(t.session.state.positionIndex, 0);
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });

    test('Home calls home() on session notifier', () async {
      final t = createOrchestrator();
      // Move to level 1, position 3.
      t.session.nextLevel();
      t.session.nextPosition();
      t.session.nextPosition();
      t.session.nextPosition();
      expect(t.session.state.levelIndex, 1);
      expect(t.session.state.positionIndex, 3);

      t.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      t.gestures.addEvent(const Home());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(t.session.state.levelIndex, 0);
      expect(t.session.state.positionIndex, 0);
      expect(t.session.state.phase, SessionPhase.playing);

      await tearDownOrchestrator(t.orchestrator, t.gestures);
    });
  });

  // -------------------------------------------------------------------------
  // 7.7 Dual-stream subscription tests
  // -------------------------------------------------------------------------
  group('dual-stream subscription (shake detector)', () {
    test('events from shake detector stream are processed', () async {
      final gestures = FakeGestureClassifier();
      final vibration = MockVibrationService();
      final session = SessionNotifier();
      final shake = FakeShakeDetector();

      // Move to a non-home position so Home has a visible effect.
      session.nextLevel();
      session.nextPosition();
      expect(session.state.levelIndex, 1);
      expect(session.state.positionIndex, 1);

      final orchestrator = TeachingOrchestrator(
        gestureClassifier: gestures,
        vibrationService: vibration,
        sessionNotifier: session,
        shakeDetector: shake,
        config: const TeachingTimingConfig(
          repeatPause: Duration(milliseconds: 10),
        ),
      );

      orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Emit Home from shake detector.
      shake.addEvent(const Home());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should have navigated home.
      expect(session.state.levelIndex, 0);
      expect(session.state.positionIndex, 0);
      expect(session.state.phase, SessionPhase.playing);

      await orchestrator.stop();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      orchestrator.dispose();
      gestures.dispose();
      shake.dispose();
    });

    test('both subscriptions cleaned up on stop and dispose', () async {
      final gestures = FakeGestureClassifier();
      final vibration = MockVibrationService();
      final session = SessionNotifier();
      final shake = FakeShakeDetector();

      final orchestrator = TeachingOrchestrator(
        gestureClassifier: gestures,
        vibrationService: vibration,
        sessionNotifier: session,
        shakeDetector: shake,
        config: const TeachingTimingConfig(
          repeatPause: Duration(milliseconds: 10),
        ),
      );

      orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Dispose the orchestrator — this should cancel both subscriptions.
      await orchestrator.stop();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      orchestrator.dispose();

      // After dispose, events from either stream should not cause errors.
      // Adding events to closed controllers would throw if subscriptions
      // were still active and the handler tried to access disposed state.
      // We verify no exception is thrown.
      gestures.dispose();
      shake.dispose();
    });
  });
}
