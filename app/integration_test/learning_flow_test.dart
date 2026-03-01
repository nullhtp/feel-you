import 'package:feel_you/morse/morse.dart';
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
  // 2.2 App start plays digit 0 (initial state is now digits level)
  // -------------------------------------------------------------------------
  test('app start plays digit 0 pattern', () async {
    h.orchestrator.start();

    // Let the async loop run one iteration.
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // 0 = dash x5
    final zeroPattern = encodeLetter('0', MorseLanguage.english)!;
    expect(h.vibration.patterns, isNotEmpty);
    expect(h.vibration.patterns.first, zeroPattern);
  });

  // -------------------------------------------------------------------------
  // 2.3 Correct input for A (after switching to letters level)
  // -------------------------------------------------------------------------
  test('correct input for A triggers success and resumes loop', () async {
    // Switch to letters level first.
    final session = h.container.read(sessionNotifierProvider.notifier);
    session.nextLevel();

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Simulate dot (first symbol of A).
    var time = const Duration(milliseconds: 100);
    simulateDot(h.classifier, baseTime: time);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    // Session should be listening after first tap interrupt.
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.listening,
    );

    // Simulate dash (second symbol of A).
    time += const Duration(milliseconds: 20);
    simulateDash(h.classifier, baseTime: time);

    // Wait for silence timeout -> InputComplete.
    await waitForSilenceTimeout();
    // Let the feedback handler run.
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Should have received playSuccess.
    expect(h.vibration.callTypes, contains(VibrationCallType.playSuccess));

    // Orchestrator should have resumed playing.
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // 2.4 Wrong input triggers error + replay
  // -------------------------------------------------------------------------
  test(
    'wrong input triggers error feedback and correct pattern replay',
    () async {
      // Switch to letters level.
      final session = h.container.read(sessionNotifierProvider.notifier);
      session.nextLevel();

      h.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Interrupt with a tap.
      final time = const Duration(milliseconds: 100);
      simulateDot(h.classifier, baseTime: time);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      // Submit wrong answer: just a dash (A is dot-dash).
      simulateDash(
        h.classifier,
        baseTime: time + const Duration(milliseconds: 20),
      );
      // Oops, let's actually submit wrong — we need to wait for silence timeout
      // after entering a single wrong symbol.
      // Reset and do it properly: enter just a dash-dash (wrong for A).
      h.vibration.reset();
      // We're in listening phase, classifier still accumulating.
      // Just wait for silence timeout to submit the dot+dash we already entered.
      // Actually, since we entered dot then dash, that IS correct for A.
      // Let's use a fresh harness for a clean wrong-answer test.
      await h.dispose();

      h = createTestHarness();
      // Switch to letters level again.
      h.container.read(sessionNotifierProvider.notifier).nextLevel();

      h.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Interrupt.
      var t = const Duration(milliseconds: 100);
      simulateDot(h.classifier, baseTime: t);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(
        h.container.read(sessionNotifierProvider).phase,
        SessionPhase.listening,
      );

      // Enter wrong answer: just wait for silence timeout after the single dot.
      // A requires dot+dash, so a lone dot is wrong.
      await waitForSilenceTimeout();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Should have received playError.
      expect(h.vibration.callTypes, contains(VibrationCallType.playError));

      // After error, correct pattern should be replayed.
      final errorIndex = h.vibration.callTypes.indexOf(
        VibrationCallType.playError,
      );
      final callsAfterError = h.vibration.calls.sublist(errorIndex + 1);
      final replayPatterns = callsAfterError
          .where((c) => c.type == VibrationCallType.playMorsePattern)
          .toList();
      expect(replayPatterns, isNotEmpty);
      expect(
        replayPatterns.first.signals,
        encodeLetter('A', MorseLanguage.english),
      );

      // Should have resumed to playing.
      expect(
        h.container.read(sessionNotifierProvider).phase,
        SessionPhase.playing,
      );
    },
  );

  // -------------------------------------------------------------------------
  // 2.5 Navigate next
  // -------------------------------------------------------------------------
  test('navigate next advances to B and plays B pattern', () async {
    // Switch to letters level.
    final session = h.container.read(sessionNotifierProvider.notifier);
    session.nextLevel();

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Swipe right.
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(h.currentLetter, 'B');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );

    // Should be playing B's pattern.
    final bPattern = encodeLetter('B', MorseLanguage.english)!;
    expect(h.vibration.hasPattern(bPattern), isTrue);
  });

  // -------------------------------------------------------------------------
  // 2.6 Navigate previous
  // -------------------------------------------------------------------------
  test('navigate previous from B goes back to A', () async {
    // Switch to letters level.
    final session = h.container.read(sessionNotifierProvider.notifier);
    session.nextLevel();

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // First navigate to B.
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentLetter, 'B');

    // Then navigate back to A.
    simulateSwipeLeft(
      h.classifier,
      baseTime: const Duration(milliseconds: 200),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(h.currentLetter, 'A');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // 2.7 Reset
  // -------------------------------------------------------------------------
  test('reset from C returns to A', () async {
    // Switch to letters level.
    final session = h.container.read(sessionNotifierProvider.notifier);
    session.nextLevel();

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Navigate to C (two swipe rights).
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 200),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentLetter, 'C');

    // Long hold to reset.
    await simulateLongHold(
      h.classifier,
      baseTime: const Duration(milliseconds: 300),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(h.currentLetter, 'A');
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // 2.8 Multi-letter sequence
  // -------------------------------------------------------------------------
  test('learn A correctly then navigate to B and learn B', () async {
    // Switch to letters level.
    final session = h.container.read(sessionNotifierProvider.notifier);
    session.nextLevel();

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // --- Learn A (dot, dash) ---
    var time = const Duration(milliseconds: 100);

    // First tap interrupts playback -> listening.
    simulateDot(h.classifier, baseTime: time);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.listening,
    );

    // Enter dash.
    time += const Duration(milliseconds: 20);
    simulateDash(h.classifier, baseTime: time);

    // Wait for InputComplete.
    await waitForSilenceTimeout();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(h.vibration.callTypes, contains(VibrationCallType.playSuccess));

    // --- Navigate to B ---
    time += const Duration(milliseconds: 100);
    simulateSwipeRight(h.classifier, baseTime: time);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(h.currentLetter, 'B');

    // --- Learn B (dash, dot, dot, dot) ---
    h.vibration.reset();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Interrupt with first tap.
    time += const Duration(milliseconds: 100);
    simulateDash(h.classifier, baseTime: time);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    time += const Duration(milliseconds: 20);
    simulateDot(h.classifier, baseTime: time);
    time += const Duration(milliseconds: 20);
    simulateDot(h.classifier, baseTime: time);
    time += const Duration(milliseconds: 20);
    simulateDot(h.classifier, baseTime: time);

    await waitForSilenceTimeout();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(h.vibration.callTypes, contains(VibrationCallType.playSuccess));
    expect(h.currentLetter, 'B');
  });
}
