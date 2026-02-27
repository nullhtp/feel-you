import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_utils.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late TestHarness h;

  setUp(() {
    h = createTestHarness();
  });

  tearDown(() async {
    await h.dispose();
  });

  // -------------------------------------------------------------------------
  // 3.2 Rapid navigation — three consecutive swipe-right gestures
  // -------------------------------------------------------------------------
  test('rapid navigation: three swipes right lands on D', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Three rapid swipe-rights.
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 110),
    );
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 120),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(h.currentLetter, 'D');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );

    // Should be playing D's pattern.
    final dPattern = encodeLetter('D')!;
    expect(h.vibration.hasPattern(dPattern), isTrue);
  });

  // -------------------------------------------------------------------------
  // 3.3 Rapid swipe right then left
  // -------------------------------------------------------------------------
  test('rapid swipe right then left returns to original letter', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(h.currentLetter, 'A');

    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    simulateSwipeLeft(
      h.classifier,
      baseTime: const Duration(milliseconds: 110),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(h.currentLetter, 'A');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // 3.4 Tap during playback interrupts
  // -------------------------------------------------------------------------
  test('tap during playback interrupts and transitions to listening', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Tap during playback.
    simulateDot(h.classifier, baseTime: const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    // Should have called cancel on the vibration service.
    expect(h.vibration.callTypes, contains(VibrationCallType.cancel));

    // Phase should be listening.
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.listening,
    );
  });

  // -------------------------------------------------------------------------
  // 3.5 Double tap during playback
  // -------------------------------------------------------------------------
  test(
    'double tap: first interrupts, second is accumulated as input',
    () async {
      h.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // First tap — interrupts playback.
      var time = const Duration(milliseconds: 100);
      simulateDot(h.classifier, baseTime: time);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(
        h.container.read(sessionNotifierProvider).phase,
        SessionPhase.listening,
      );

      final cancelCountAfterFirst = h.vibration.callTypes
          .where((t) => t == VibrationCallType.cancel)
          .length;

      // Second tap — should NOT trigger another cancel (already in listening),
      // but should be accumulated as input.
      time += const Duration(milliseconds: 20);
      simulateDash(h.classifier, baseTime: time);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final cancelCountAfterSecond = h.vibration.callTypes
          .where((t) => t == VibrationCallType.cancel)
          .length;

      // No additional cancel calls from the second tap.
      expect(cancelCountAfterSecond, cancelCountAfterFirst);

      // Still in listening phase.
      expect(
        h.container.read(sessionNotifierProvider).phase,
        SessionPhase.listening,
      );

      // Wait for InputComplete — the accumulated input (dot + dash = A) should
      // be evaluated.
      await waitForSilenceTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Since we entered dot+dash which IS correct for A, should get success.
      expect(h.vibration.callTypes, contains(VibrationCallType.playSuccess));
    },
  );

  // -------------------------------------------------------------------------
  // 3.6 Navigation during feedback
  // -------------------------------------------------------------------------
  test('swipe right during success feedback advances to next letter', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Enter correct answer for A.
    var time = const Duration(milliseconds: 100);
    simulateDot(h.classifier, baseTime: time);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    time += const Duration(milliseconds: 20);
    simulateDash(h.classifier, baseTime: time);

    await waitForSilenceTimeout();
    // Brief delay but not enough for full feedback to complete — we want to
    // swipe during feedback.
    await Future<void>.delayed(const Duration(milliseconds: 5));

    // Verify we're in feedback or it completed quickly. With fast configs
    // feedback is nearly instant, so just navigate regardless.
    time += const Duration(milliseconds: 100);
    simulateSwipeRight(h.classifier, baseTime: time);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Should have advanced to B.
    expect(h.currentLetter, 'B');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );

    // Should have cancelled (navigation always cancels).
    expect(h.vibration.callTypes, contains(VibrationCallType.cancel));
  });

  // -------------------------------------------------------------------------
  // 3.7 Navigate previous at letter A
  // -------------------------------------------------------------------------
  test('navigate previous at letter A stays on A', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(h.currentLetter, 'A');

    simulateSwipeLeft(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Should stay on A.
    expect(h.currentLetter, 'A');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );

    // Should still be playing A's pattern.
    final aPattern = encodeLetter('A')!;
    expect(h.vibration.hasPattern(aPattern), isTrue);
  });

  // -------------------------------------------------------------------------
  // 3.8 Navigate next at letter Z
  // -------------------------------------------------------------------------
  test('navigate next at letter Z stays on Z', () async {
    // Advance session to Z (index 25).
    final session = h.container.read(sessionNotifierProvider.notifier);
    for (var i = 0; i < morseLetters.length - 1; i++) {
      session.nextLetter();
    }
    expect(h.currentLetter, 'Z');

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Should stay on Z.
    expect(h.currentLetter, 'Z');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );

    // Should still be playing Z's pattern.
    final zPattern = encodeLetter('Z')!;
    expect(h.vibration.hasPattern(zPattern), isTrue);
  });
}
