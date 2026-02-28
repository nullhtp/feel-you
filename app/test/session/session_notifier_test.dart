import 'package:feel_you/morse/levels.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionNotifier notifier;

  setUp(() {
    notifier = SessionNotifier();
  });

  group('SessionNotifier', () {
    // -----------------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------------
    group('initial state', () {
      test('starts at digit 0 with playing phase', () {
        expect(notifier.state, const SessionState());
        expect(notifier.state.currentCharacter, '0');
        expect(notifier.state.levelIndex, 0);
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('initial level is digits', () {
        expect(notifier.state.currentLevel.name, 'digits');
      });
    });

    // -----------------------------------------------------------------------
    // nextPosition
    // -----------------------------------------------------------------------
    group('nextPosition', () {
      test('advances from 0 to 1', () {
        notifier.nextPosition();
        expect(notifier.state.currentCharacter, '1');
        expect(notifier.state.positionIndex, 1);
      });

      test('advances from middle of digits', () {
        // Navigate to 5 (index 5)
        for (var i = 0; i < 5; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, '5');

        notifier.nextPosition();
        expect(notifier.state.currentCharacter, '6');
      });

      test('clamps at last digit (9) — boundary', () {
        // Navigate to 9 (index 9)
        for (var i = 0; i < 9; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, '9');

        final stateBeforeExtraNext = notifier.state;
        notifier.nextPosition();
        expect(notifier.state, stateBeforeExtraNext);
        expect(notifier.state.currentCharacter, '9');
      });

      test('clamps at last letter (Z) in letters level', () {
        notifier.nextLevel(); // switch to letters
        // Navigate to Z (index 25)
        for (var i = 0; i < 25; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, 'Z');

        final stateBeforeExtraNext = notifier.state;
        notifier.nextPosition();
        expect(notifier.state, stateBeforeExtraNext);
        expect(notifier.state.currentCharacter, 'Z');
      });

      test('resets phase to playing', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..nextPosition();
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

    // -----------------------------------------------------------------------
    // previousPosition
    // -----------------------------------------------------------------------
    group('previousPosition', () {
      test('goes back from 1 to 0', () {
        notifier.nextPosition(); // 0 -> 1
        expect(notifier.state.currentCharacter, '1');

        notifier.previousPosition();
        expect(notifier.state.currentCharacter, '0');
        expect(notifier.state.positionIndex, 0);
      });

      test('clamps at first position (boundary)', () {
        final stateBeforeExtraPrev = notifier.state;
        notifier.previousPosition();
        expect(notifier.state, stateBeforeExtraPrev);
        expect(notifier.state.currentCharacter, '0');
      });

      test('resets phase to playing', () {
        notifier
          ..nextPosition() // Move to 1 so previousPosition has effect
          ..setPhase(SessionPhase.listening)
          ..previousPosition();
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

    // -----------------------------------------------------------------------
    // reset
    // -----------------------------------------------------------------------
    group('reset', () {
      test('resets position to 0 within current level', () {
        // Navigate to position 5
        for (var i = 0; i < 5; i++) {
          notifier.nextPosition();
        }
        notifier.setPhase(SessionPhase.feedback);
        expect(notifier.state.currentCharacter, '5');
        expect(notifier.state.phase, SessionPhase.feedback);

        notifier.reset();
        expect(notifier.state.currentCharacter, '0');
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('does NOT change levelIndex', () {
        notifier.nextLevel(); // switch to letters
        expect(notifier.state.levelIndex, 1);

        // Navigate within letters
        for (var i = 0; i < 5; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, 'F');

        notifier.reset();
        expect(notifier.state.levelIndex, 1);
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.currentCharacter, 'A');
      });

      test('reset when already at position 0', () {
        notifier.reset();
        expect(notifier.state.currentCharacter, '0');
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('resets phase to playing from non-playing phase', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..reset();
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

    // -----------------------------------------------------------------------
    // nextLevel
    // -----------------------------------------------------------------------
    group('nextLevel', () {
      test('advances from digits to letters', () {
        notifier.nextLevel();
        expect(notifier.state.levelIndex, 1);
        expect(notifier.state.currentLevel.name, 'letters');
        expect(notifier.state.currentCharacter, 'A');
      });

      test('resets positionIndex to 0', () {
        // Move to position 5 in digits
        for (var i = 0; i < 5; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.positionIndex, 5);

        notifier.nextLevel();
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.levelIndex, 1);
      });

      test('sets phase to playing', () {
        notifier.setPhase(SessionPhase.feedback);
        notifier.nextLevel();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('clamps at last level — no-op', () {
        notifier.nextLevel(); // digits -> letters
        expect(notifier.state.levelIndex, 1);

        final stateBeforeExtra = notifier.state;
        notifier.nextLevel(); // already at last level
        expect(notifier.state, stateBeforeExtra);
      });
    });

    // -----------------------------------------------------------------------
    // previousLevel
    // -----------------------------------------------------------------------
    group('previousLevel', () {
      test('goes back from letters to digits', () {
        notifier.nextLevel(); // digits -> letters
        expect(notifier.state.levelIndex, 1);

        notifier.previousLevel();
        expect(notifier.state.levelIndex, 0);
        expect(notifier.state.currentLevel.name, 'digits');
        expect(notifier.state.currentCharacter, '0');
      });

      test('resets positionIndex to 0', () {
        notifier.nextLevel(); // digits -> letters
        for (var i = 0; i < 10; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.positionIndex, 10);

        notifier.previousLevel();
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.levelIndex, 0);
      });

      test('sets phase to playing', () {
        notifier.nextLevel();
        notifier.setPhase(SessionPhase.feedback);
        notifier.previousLevel();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('clamps at first level — no-op', () {
        final stateBeforeExtra = notifier.state;
        notifier.previousLevel(); // already at first level
        expect(notifier.state, stateBeforeExtra);
      });
    });

    // -----------------------------------------------------------------------
    // home
    // -----------------------------------------------------------------------
    group('home', () {
      test('resets to levelIndex=0 positionIndex=0 playing', () {
        // Navigate to letters, position 10
        notifier.nextLevel();
        for (var i = 0; i < 10; i++) {
          notifier.nextPosition();
        }
        notifier.setPhase(SessionPhase.feedback);

        notifier.home();
        expect(notifier.state.levelIndex, 0);
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.currentCharacter, '0');
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('no-op effect when already at home', () {
        notifier.home();
        expect(notifier.state, const SessionState());
      });
    });

    // -----------------------------------------------------------------------
    // setPhase
    // -----------------------------------------------------------------------
    group('setPhase', () {
      test('sets to listening', () {
        notifier.setPhase(SessionPhase.listening);
        expect(notifier.state.phase, SessionPhase.listening);
      });

      test('sets to feedback', () {
        notifier.setPhase(SessionPhase.feedback);
        expect(notifier.state.phase, SessionPhase.feedback);
      });

      test('sets to playing', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..setPhase(SessionPhase.playing);
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('does not change positionIndex or levelIndex', () {
        notifier
          ..nextPosition() // 0 -> 1
          ..setPhase(SessionPhase.feedback);
        expect(notifier.state.positionIndex, 1);
        expect(notifier.state.levelIndex, 0);
        expect(notifier.state.currentCharacter, '1');
      });
    });

    // -----------------------------------------------------------------------
    // Navigation resets phase to playing
    // -----------------------------------------------------------------------
    group('navigation resets phase to playing', () {
      test('nextPosition resets from listening', () {
        notifier
          ..setPhase(SessionPhase.listening)
          ..nextPosition();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('nextPosition resets from feedback', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..nextPosition();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('previousPosition resets from listening', () {
        notifier
          ..nextPosition() // Move to 1
          ..setPhase(SessionPhase.listening)
          ..previousPosition();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('previousPosition resets from feedback', () {
        notifier
          ..nextPosition() // Move to 1
          ..setPhase(SessionPhase.feedback)
          ..previousPosition();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('reset resets from listening', () {
        notifier
          ..setPhase(SessionPhase.listening)
          ..reset();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('reset resets from feedback', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..reset();
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

    // -----------------------------------------------------------------------
    // Boundary no-ops preserve state
    // -----------------------------------------------------------------------
    group('boundary no-ops preserve state', () {
      test('nextPosition at last digit does not change state', () {
        // Navigate to 9
        for (var i = 0; i < 9; i++) {
          notifier.nextPosition();
        }
        notifier.setPhase(SessionPhase.feedback);
        final stateAt9 = notifier.state;

        notifier.nextPosition();
        expect(notifier.state, stateAt9);
      });

      test('previousPosition at first position does not change state', () {
        notifier.setPhase(SessionPhase.listening);
        final stateAt0 = notifier.state;

        notifier.previousPosition();
        expect(notifier.state, stateAt0);
      });

      test('nextLevel at last level does not change state', () {
        notifier.nextLevel(); // digits -> letters
        notifier.setPhase(SessionPhase.feedback);
        final stateAtLastLevel = notifier.state;

        notifier.nextLevel();
        expect(notifier.state, stateAtLastLevel);
      });

      test('previousLevel at first level does not change state', () {
        notifier.setPhase(SessionPhase.listening);
        final stateAtFirstLevel = notifier.state;

        notifier.previousLevel();
        expect(notifier.state, stateAtFirstLevel);
      });
    });

    // -----------------------------------------------------------------------
    // Position navigation within different levels
    // -----------------------------------------------------------------------
    group('position navigation within different levels', () {
      test('digits level has 10 characters (0-9)', () {
        expect(levels[0].characters.length, 10);
        // Navigate through all 10 digits
        for (var i = 0; i < 9; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, '9');
        expect(notifier.state.positionIndex, 9);
      });

      test('letters level has 26 characters (A-Z)', () {
        expect(levels[1].characters.length, 26);
        notifier.nextLevel(); // switch to letters
        // Navigate through all 26 letters
        for (var i = 0; i < 25; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, 'Z');
        expect(notifier.state.positionIndex, 25);
      });

      test('level switching resets position to 0', () {
        // Move to position 5 in digits
        for (var i = 0; i < 5; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.positionIndex, 5);

        // Switch to letters — position resets
        notifier.nextLevel();
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.currentCharacter, 'A');

        // Move to position 10 in letters
        for (var i = 0; i < 10; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.positionIndex, 10);

        // Switch back to digits — position resets
        notifier.previousLevel();
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.currentCharacter, '0');
      });
    });
  });
}
