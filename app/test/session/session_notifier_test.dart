import 'dart:math';

import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/quiz_item_picker.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionNotifier notifier;

  setUp(() {
    notifier = SessionNotifier(MorseLanguage.english);
  });

  group('SessionNotifier', () {
    // -----------------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------------
    group('initial state', () {
      test('starts at digit 0 with playing phase', () {
        expect(
          notifier.state,
          const SessionState(language: MorseLanguage.english),
        );
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

      test('enters the quiz after the last digit (9)', () {
        // Navigate to 9 (index 9)
        for (var i = 0; i < 9; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, '9');
        expect(notifier.state.isInQuiz, isFalse);

        notifier.nextPosition();
        expect(notifier.state.isInQuiz, isTrue);
        expect(notifier.state.positionIndex, 9);
        expect(
          notifier.state.currentLevel.characters,
          contains(notifier.state.currentCharacter),
        );
      });

      test('enters the quiz after the last letter (Z)', () {
        notifier.nextLevel(); // switch to letters
        // Navigate to Z (index 25)
        for (var i = 0; i < 25; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, 'Z');

        notifier.nextPosition();
        expect(notifier.state.isInQuiz, isTrue);
        expect(notifier.state.positionIndex, 25);
        expect(notifier.state.currentLevel.name, 'letters');
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
        notifier.nextLevel(); // letters -> words
        expect(notifier.state.levelIndex, 2);

        final stateBeforeExtra = notifier.state;
        notifier.nextLevel(); // already at last level (words)
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
        expect(
          notifier.state,
          const SessionState(language: MorseLanguage.english),
        );
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
      test('nextPosition at last digit is not a no-op: it enters the quiz', () {
        // Navigate to 9
        for (var i = 0; i < 9; i++) {
          notifier.nextPosition();
        }
        notifier
          ..setPhase(SessionPhase.feedback)
          ..nextPosition();

        expect(notifier.state.isInQuiz, isTrue);
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('previousPosition at first position does not change state', () {
        notifier.setPhase(SessionPhase.listening);
        final stateAt0 = notifier.state;

        notifier.previousPosition();
        expect(notifier.state, stateAt0);
      });

      test('nextLevel at last level does not change state', () {
        notifier.nextLevel(); // digits -> letters
        notifier.nextLevel(); // letters -> words
        notifier.setPhase(SessionPhase.feedback);
        final stateAtLastLevel = notifier.state;

        notifier.nextLevel(); // already at last level (words)
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
        final englishLevels = morseRegistry.levelsForLanguage(
          MorseLanguage.english,
        );
        expect(englishLevels[0].characters.length, 10);
        // Navigate through all 10 digits
        for (var i = 0; i < 9; i++) {
          notifier.nextPosition();
        }
        expect(notifier.state.currentCharacter, '9');
        expect(notifier.state.positionIndex, 9);
      });

      test('letters level has 26 characters (A-Z)', () {
        final englishLevels = morseRegistry.levelsForLanguage(
          MorseLanguage.english,
        );
        expect(englishLevels[1].characters.length, 26);
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

    // -----------------------------------------------------------------------
    // selectLanguage
    // -----------------------------------------------------------------------
    group('selectLanguage', () {
      test('selectLanguage switches to Arabic', () {
        notifier.selectLanguage(MorseLanguage.arabic);
        expect(notifier.state.language, MorseLanguage.arabic);
        expect(notifier.state.levelIndex, 0);
        expect(notifier.state.positionIndex, 0);
        expect(notifier.state.phase, SessionPhase.playing);
        expect(notifier.state.currentCharacter, '0');
      });

      test('Arabic level 1 is arabic-letters', () {
        notifier.selectLanguage(MorseLanguage.arabic);
        notifier.nextLevel();
        expect(notifier.state.currentLevel.name, 'arabic-letters');
        expect(notifier.state.currentCharacter, 'ا');
      });

      test('home preserves language', () {
        notifier.selectLanguage(MorseLanguage.arabic);
        notifier.nextLevel();
        notifier.home();
        expect(notifier.state.language, MorseLanguage.arabic);
        expect(notifier.state.levelIndex, 0);
      });
    });
  });

  // -------------------------------------------------------------------------
  // The quiz after the last item of every level
  // -------------------------------------------------------------------------
  group('quiz', () {
    late SessionNotifier quiz;

    /// Moves [quiz] to the last item of the current level and past it.
    void enterQuiz() {
      final last = quiz.state.currentLevel.characters.length - 1;
      while (quiz.state.positionIndex < last) {
        quiz.nextPosition();
      }
      quiz.nextPosition();
      expect(quiz.state.isInQuiz, isTrue);
    }

    setUp(() {
      quiz = SessionNotifier(
        MorseLanguage.english,
        quizItemPicker: QuizItemPicker(random: Random(3)),
      );
      addTearDown(quiz.dispose);
    });

    test('entering keeps the position on the last item and plays', () {
      quiz.nextLevel(); // letters
      for (var i = 0; i < 25; i++) {
        quiz.nextPosition();
      }
      quiz
        ..setPhase(SessionPhase.listening)
        ..nextPosition();

      expect(quiz.state.isInQuiz, isTrue);
      expect(quiz.state.positionIndex, 25);
      expect(quiz.state.phase, SessionPhase.playing);
      expect(quiz.state.currentLevel.characters, contains(quiz.state.quizItem));
    });

    test('every level of every language has a quiz', () {
      for (final language in MorseLanguage.values) {
        quiz.selectLanguage(language);
        for (var level = 0; level < quiz.state.levels.length; level++) {
          enterQuiz();
          expect(quiz.state.levelIndex, level);
          quiz.nextLevel();
        }
      }
    });

    test('next in the quiz draws a new item and stays in the quiz', () {
      enterQuiz();
      for (var i = 0; i < 50; i++) {
        final before = quiz.state.quizItem;
        quiz.nextPosition();
        expect(quiz.state.isInQuiz, isTrue);
        expect(quiz.state.quizItem, isNot(before));
        expect(quiz.state.positionIndex, 9);
      }
    });

    test('draws from the items the picker is given as learned', () {
      final learned = SessionNotifier(
        MorseLanguage.english,
        quizItemPicker: QuizItemPicker(
          learnedItemsOf: (language, level) => {'3', '7'},
          random: Random(3),
        ),
      );
      addTearDown(learned.dispose);
      for (var i = 0; i < 9; i++) {
        learned.nextPosition();
      }

      final drawn = <String>{};
      for (var i = 0; i < 20; i++) {
        learned.nextPosition();
        drawn.add(learned.state.currentCharacter);
      }
      expect(drawn, {'3', '7'});
    });

    test('previous leaves the quiz to the last item', () {
      enterQuiz();
      quiz
        ..setPhase(SessionPhase.feedback)
        ..previousPosition();

      expect(quiz.state.isInQuiz, isFalse);
      expect(quiz.state.currentCharacter, '9');
      expect(quiz.state.phase, SessionPhase.playing);
    });

    test('reset leaves the quiz to the first item of the level', () {
      quiz.nextLevel();
      enterQuiz();
      quiz.reset();

      expect(quiz.state.isInQuiz, isFalse);
      expect(quiz.state.currentCharacter, 'A');
    });

    test('level up from the quiz goes to the next level, outside the quiz', () {
      enterQuiz();
      quiz.nextLevel();

      expect(quiz.state.isInQuiz, isFalse);
      expect(quiz.state.levelIndex, 1);
      expect(quiz.state.currentCharacter, 'A');
    });

    test('level down from the quiz goes to the previous level', () {
      quiz.nextLevel();
      enterQuiz();
      quiz.previousLevel();

      expect(quiz.state.isInQuiz, isFalse);
      expect(quiz.state.levelIndex, 0);
      expect(quiz.state.currentCharacter, '0');
    });

    test('level up in the quiz of the last level keeps the quiz item', () {
      quiz
        ..nextLevel()
        ..nextLevel();
      enterQuiz();
      final before = quiz.state;

      quiz.nextLevel();

      expect(quiz.state, before);
    });

    test('level down in the quiz of the first level keeps the quiz item', () {
      enterQuiz();
      final before = quiz.state;

      quiz.previousLevel();

      expect(quiz.state, before);
    });

    test('home leaves the quiz to digit 0', () {
      quiz
        ..nextLevel()
        ..nextLevel();
      enterQuiz();
      quiz.home();

      expect(quiz.state.isInQuiz, isFalse);
      expect(quiz.state.levelIndex, 0);
      expect(quiz.state.currentCharacter, '0');
    });

    test('selecting a language leaves the quiz', () {
      enterQuiz();
      quiz.selectLanguage(MorseLanguage.russian);

      expect(quiz.state.isInQuiz, isFalse);
      expect(quiz.state.currentCharacter, '0');
    });

    test('nextQuizItem draws another item and plays it', () {
      enterQuiz();
      final before = quiz.state.quizItem;
      quiz
        ..setPhase(SessionPhase.feedback)
        ..nextQuizItem();

      expect(quiz.state.isInQuiz, isTrue);
      expect(quiz.state.quizItem, isNot(before));
      expect(quiz.state.phase, SessionPhase.playing);
    });

    test('nextQuizItem is a no-op outside the quiz', () {
      quiz.setPhase(SessionPhase.feedback);
      final before = quiz.state;

      quiz.nextQuizItem();

      expect(quiz.state, before);
    });
  });
}
