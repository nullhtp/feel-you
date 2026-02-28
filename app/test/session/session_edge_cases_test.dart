import 'package:feel_you/morse/levels.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionNotifier notifier;

  setUp(() {
    notifier = SessionNotifier();
  });

  group('vertical swipe at level boundary', () {
    test('nextLevel at last level (words) is a no-op', () {
      // Move to last level (words, index 2).
      notifier.nextLevel();
      notifier.nextLevel();
      expect(notifier.state.levelIndex, 2);
      expect(notifier.state.currentLevel.name, 'words');

      final stateBefore = notifier.state;
      notifier.nextLevel(); // Already at last level.
      expect(notifier.state, stateBefore);
      expect(notifier.state.levelIndex, 2);
    });

    test('previousLevel at first level (digits) is a no-op', () {
      // Already at first level (digits, index 0).
      expect(notifier.state.levelIndex, 0);
      expect(notifier.state.currentLevel.name, 'digits');

      final stateBefore = notifier.state;
      notifier.previousLevel(); // Already at first level.
      expect(notifier.state, stateBefore);
      expect(notifier.state.levelIndex, 0);
    });

    test('nextLevel at last level preserves position and phase', () {
      notifier.nextLevel(); // digits -> letters
      notifier.nextLevel(); // letters -> words
      // Move to position 5 and change phase.
      for (var i = 0; i < 5; i++) {
        notifier.nextPosition();
      }
      notifier.setPhase(SessionPhase.feedback);

      final stateBefore = notifier.state;
      notifier.nextLevel(); // No-op — already at last level (words).
      expect(notifier.state, stateBefore);
      expect(notifier.state.positionIndex, 5);
      expect(notifier.state.phase, SessionPhase.feedback);
    });

    test('previousLevel at first level preserves position and phase', () {
      // Move to position 3 and change phase.
      for (var i = 0; i < 3; i++) {
        notifier.nextPosition();
      }
      notifier.setPhase(SessionPhase.listening);

      final stateBefore = notifier.state;
      notifier.previousLevel(); // No-op — already at first level.
      expect(notifier.state, stateBefore);
      expect(notifier.state.positionIndex, 3);
      expect(notifier.state.phase, SessionPhase.listening);
    });
  });

  group('rapid level switching', () {
    test('multiple consecutive nextLevel calls clamp at last level', () {
      notifier.nextLevel(); // 0 -> 1 (digits -> letters)
      notifier.nextLevel(); // 1 -> 2 (letters -> words)
      notifier.nextLevel(); // 2 -> 2 (no-op)
      notifier.nextLevel(); // 2 -> 2 (no-op)
      expect(notifier.state.levelIndex, 2);
      expect(notifier.state.currentCharacter, 'IT');
    });

    test('multiple consecutive previousLevel calls clamp at first level', () {
      notifier.nextLevel(); // 0 -> 1
      notifier.previousLevel(); // 1 -> 0
      notifier.previousLevel(); // 0 -> 0 (no-op)
      notifier.previousLevel(); // 0 -> 0 (no-op)
      notifier.previousLevel(); // 0 -> 0 (no-op)
      expect(notifier.state.levelIndex, 0);
      expect(notifier.state.currentCharacter, '0');
    });

    test('rapid toggle between levels settles correctly', () {
      notifier.nextLevel(); // 0 -> 1
      expect(notifier.state.levelIndex, 1);
      expect(notifier.state.currentCharacter, 'A');

      notifier.previousLevel(); // 1 -> 0
      expect(notifier.state.levelIndex, 0);
      expect(notifier.state.currentCharacter, '0');

      notifier.nextLevel(); // 0 -> 1
      expect(notifier.state.levelIndex, 1);

      notifier.nextLevel(); // 1 -> 2
      expect(notifier.state.levelIndex, 2);

      notifier.nextLevel(); // no-op (at last level)
      expect(notifier.state.levelIndex, 2);

      notifier.previousLevel(); // 2 -> 1
      expect(notifier.state.levelIndex, 1);

      notifier.previousLevel(); // 1 -> 0
      expect(notifier.state.levelIndex, 0);

      notifier.previousLevel(); // no-op
      expect(notifier.state.levelIndex, 0);
    });

    test('rapid level switching always resets position to 0', () {
      // Navigate to position 5 in digits.
      for (var i = 0; i < 5; i++) {
        notifier.nextPosition();
      }
      expect(notifier.state.positionIndex, 5);

      notifier.nextLevel(); // digits -> letters, position resets to 0
      expect(notifier.state.positionIndex, 0);

      // Navigate to position 10 in letters.
      for (var i = 0; i < 10; i++) {
        notifier.nextPosition();
      }
      expect(notifier.state.positionIndex, 10);

      notifier.previousLevel(); // letters -> digits, position resets to 0
      expect(notifier.state.positionIndex, 0);
    });
  });

  group('home from deeply nested position', () {
    test('home from level 1 position 25 resets to level 0 position 0', () {
      // Navigate to letters level, position 25 (Z).
      notifier.nextLevel();
      for (var i = 0; i < 25; i++) {
        notifier.nextPosition();
      }
      expect(notifier.state.levelIndex, 1);
      expect(notifier.state.positionIndex, 25);
      expect(notifier.state.currentCharacter, 'Z');

      notifier.home();

      expect(notifier.state.levelIndex, 0);
      expect(notifier.state.positionIndex, 0);
      expect(notifier.state.currentCharacter, '0');
      expect(notifier.state.phase, SessionPhase.playing);
    });

    test('home from level 1 position 25 with feedback phase', () {
      notifier.nextLevel();
      for (var i = 0; i < 25; i++) {
        notifier.nextPosition();
      }
      notifier.setPhase(SessionPhase.feedback);
      expect(notifier.state.phase, SessionPhase.feedback);

      notifier.home();

      expect(notifier.state.levelIndex, 0);
      expect(notifier.state.positionIndex, 0);
      expect(notifier.state.currentCharacter, '0');
      expect(notifier.state.phase, SessionPhase.playing);
    });

    test('home from level 0 position 9 resets to level 0 position 0', () {
      // Navigate to digit 9.
      for (var i = 0; i < 9; i++) {
        notifier.nextPosition();
      }
      expect(notifier.state.currentCharacter, '9');

      notifier.home();

      expect(notifier.state.levelIndex, 0);
      expect(notifier.state.positionIndex, 0);
      expect(notifier.state.currentCharacter, '0');
    });

    test('home when already at home is idempotent', () {
      final homeBefore = notifier.state;
      notifier.home();
      expect(notifier.state, homeBefore);
    });
  });

  group('cross-cutting boundary interactions', () {
    test('nextPosition at digit 9 then nextLevel then nextPosition', () {
      // Navigate to last digit (9).
      for (var i = 0; i < 9; i++) {
        notifier.nextPosition();
      }
      expect(notifier.state.currentCharacter, '9');

      // nextPosition is a no-op at boundary.
      notifier.nextPosition();
      expect(notifier.state.currentCharacter, '9');

      // Switch to letters.
      notifier.nextLevel();
      expect(notifier.state.currentCharacter, 'A');
      expect(notifier.state.positionIndex, 0);

      // Can now navigate within letters.
      notifier.nextPosition();
      expect(notifier.state.currentCharacter, 'B');
    });

    test('all levels have valid character count', () {
      for (var i = 0; i < levels.length; i++) {
        expect(
          levels[i].characters.length,
          greaterThan(0),
          reason: 'Level $i (${levels[i].name}) has no characters',
        );
        expect(
          levels[i].patterns.length,
          levels[i].characters.length,
          reason:
              'Level $i (${levels[i].name}) pattern count != character count',
        );
      }
    });
  });
}
