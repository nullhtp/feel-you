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
  // App starts on digit 0
  // -------------------------------------------------------------------------
  test('app starts on digit 0', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(h.currentCharacter, '0');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 0);
    expect(h.container.read(sessionNotifierProvider).positionIndex, 0);

    // Should be playing digit 0's pattern (5 dashes).
    final zeroPattern = encodeLetter('0', MorseLanguage.english)!;
    expect(h.vibration.hasPattern(zeroPattern), isTrue);
  });

  // -------------------------------------------------------------------------
  // Swipe up switches to letters level, first character is A
  // -------------------------------------------------------------------------
  test('swipe up switches to letters level with first character A', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    simulateSwipeUp(h.classifier, baseTime: const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(h.currentCharacter, 'A');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 1);
    expect(h.container.read(sessionNotifierProvider).positionIndex, 0);
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );

    // Should be playing A's pattern.
    final aPattern = encodeLetter('A', MorseLanguage.english)!;
    expect(h.vibration.hasPattern(aPattern), isTrue);
  });

  // -------------------------------------------------------------------------
  // Swipe down from letters switches back to digits level, first char is 0
  // -------------------------------------------------------------------------
  test(
    'swipe down switches back to digits level with first character 0',
    () async {
      // First switch to letters.
      final session = h.container.read(sessionNotifierProvider.notifier);
      session.nextLevel();
      expect(h.currentCharacter, 'A');

      h.orchestrator.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      simulateSwipeDown(
        h.classifier,
        baseTime: const Duration(milliseconds: 100),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(h.currentCharacter, '0');
      expect(h.container.read(sessionNotifierProvider).levelIndex, 0);
      expect(h.container.read(sessionNotifierProvider).positionIndex, 0);
      expect(
        h.container.read(sessionNotifierProvider).phase,
        SessionPhase.playing,
      );

      // Should be playing digit 0's pattern.
      final zeroPattern = encodeLetter('0', MorseLanguage.english)!;
      expect(h.vibration.hasPattern(zeroPattern), isTrue);
    },
  );

  // -------------------------------------------------------------------------
  // Navigate within digits with swipe right/left
  // -------------------------------------------------------------------------
  test('navigate within digits with swipe right and left', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Swipe right: 0 -> 1.
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentCharacter, '1');

    // Swipe right again: 1 -> 2.
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 200),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentCharacter, '2');

    // Swipe left: 2 -> 1.
    simulateSwipeLeft(
      h.classifier,
      baseTime: const Duration(milliseconds: 300),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentCharacter, '1');

    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // Long tap resets to first character within current level
  // -------------------------------------------------------------------------
  test('long tap resets to first character within current level', () async {
    // Navigate to digit 5.
    final session = h.container.read(sessionNotifierProvider.notifier);
    for (var i = 0; i < 5; i++) {
      session.nextPosition();
    }
    expect(h.currentCharacter, '5');

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Long hold to reset.
    await simulateLongHold(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Should reset to 0 (first digit), staying in digits level.
    expect(h.currentCharacter, '0');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 0);
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // Long tap resets within letters level (stays on letters)
  // -------------------------------------------------------------------------
  test('long tap in letters level resets to A, not to digits', () async {
    // Switch to letters and navigate to E.
    final session = h.container.read(sessionNotifierProvider.notifier);
    session.nextLevel();
    for (var i = 0; i < 4; i++) {
      session.nextPosition();
    }
    expect(h.currentCharacter, 'E');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 1);

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await simulateLongHold(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Should reset to A within letters level.
    expect(h.currentCharacter, 'A');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 1);
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // Home (simulated via shake) resets to digit 0
  // -------------------------------------------------------------------------
  test('home resets to digit 0 from letters level', () async {
    // Switch to letters level and navigate to position 10.
    final session = h.container.read(sessionNotifierProvider.notifier);
    session.nextLevel();
    for (var i = 0; i < 10; i++) {
      session.nextPosition();
    }
    expect(h.currentCharacter, 'K');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 1);

    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Simulate home by directly calling home on the session notifier
    // (the orchestrator handles Home events from shake detector the same way).
    session.home();

    // Restart the loop to simulate what the orchestrator does on Home.
    await h.orchestrator.stop();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(h.currentCharacter, '0');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 0);
    expect(h.container.read(sessionNotifierProvider).positionIndex, 0);
    expect(
      h.container.read(sessionNotifierProvider).phase,
      SessionPhase.playing,
    );
  });

  // -------------------------------------------------------------------------
  // Full round-trip: digits -> letters -> digits
  // -------------------------------------------------------------------------
  test('full round-trip: digits to letters and back', () async {
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Start on digit 0.
    expect(h.currentCharacter, '0');

    // Navigate right in digits: 0 -> 1.
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentCharacter, '1');

    // Swipe up to letters.
    simulateSwipeUp(h.classifier, baseTime: const Duration(milliseconds: 200));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentCharacter, 'A');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 1);

    // Navigate right in letters: A -> B.
    simulateSwipeRight(
      h.classifier,
      baseTime: const Duration(milliseconds: 300),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentCharacter, 'B');

    // Swipe down back to digits.
    simulateSwipeDown(
      h.classifier,
      baseTime: const Duration(milliseconds: 400),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(h.currentCharacter, '0');
    expect(h.container.read(sessionNotifierProvider).levelIndex, 0);
  });
}
