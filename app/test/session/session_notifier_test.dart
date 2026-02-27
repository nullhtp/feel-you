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
    group('initial state', () {
      test('starts at letter A with playing phase', () {
        expect(notifier.state, const SessionState());
        expect(notifier.state.currentLetter, 'A');
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

    group('nextLetter', () {
      test('advances from A to B', () {
        notifier.nextLetter();
        expect(notifier.state.currentLetter, 'B');
        expect(notifier.state.letterIndex, 1);
      });

      test('advances from middle of alphabet', () {
        // Navigate to M (index 12)
        for (var i = 0; i < 12; i++) {
          notifier.nextLetter();
        }
        expect(notifier.state.currentLetter, 'M');

        notifier.nextLetter();
        expect(notifier.state.currentLetter, 'N');
      });

      test('clamps at Z (boundary)', () {
        // Navigate to Z (index 25)
        for (var i = 0; i < 25; i++) {
          notifier.nextLetter();
        }
        expect(notifier.state.currentLetter, 'Z');

        final stateBeforeExtraNext = notifier.state;
        notifier.nextLetter();
        expect(notifier.state, stateBeforeExtraNext);
        expect(notifier.state.currentLetter, 'Z');
      });

      test('resets phase to playing', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..nextLetter();
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

    group('previousLetter', () {
      test('goes back from B to A', () {
        notifier.nextLetter(); // A -> B
        expect(notifier.state.currentLetter, 'B');

        notifier.previousLetter();
        expect(notifier.state.currentLetter, 'A');
        expect(notifier.state.letterIndex, 0);
      });

      test('clamps at A (boundary)', () {
        final stateBeforeExtraPrev = notifier.state;
        notifier.previousLetter();
        expect(notifier.state, stateBeforeExtraPrev);
        expect(notifier.state.currentLetter, 'A');
      });

      test('resets phase to playing', () {
        notifier
          ..nextLetter() // Move to B so previousLetter has effect
          ..setPhase(SessionPhase.listening)
          ..previousLetter();
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

    group('reset', () {
      test('resets from middle of alphabet', () {
        // Navigate to M (index 12)
        for (var i = 0; i < 12; i++) {
          notifier.nextLetter();
        }
        notifier.setPhase(SessionPhase.feedback);
        expect(notifier.state.currentLetter, 'M');
        expect(notifier.state.phase, SessionPhase.feedback);

        notifier.reset();
        expect(notifier.state.currentLetter, 'A');
        expect(notifier.state.letterIndex, 0);
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('reset when already at A', () {
        notifier.reset();
        expect(notifier.state.currentLetter, 'A');
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('resets phase to playing from non-playing phase', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..reset();
        expect(notifier.state.phase, SessionPhase.playing);
      });
    });

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

      test('does not change letter index', () {
        notifier
          ..nextLetter() // A -> B
          ..setPhase(SessionPhase.feedback);
        expect(notifier.state.letterIndex, 1);
        expect(notifier.state.currentLetter, 'B');
      });
    });

    group('navigation resets phase to playing', () {
      test('nextLetter resets from listening', () {
        notifier
          ..setPhase(SessionPhase.listening)
          ..nextLetter();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('nextLetter resets from feedback', () {
        notifier
          ..setPhase(SessionPhase.feedback)
          ..nextLetter();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('previousLetter resets from listening', () {
        notifier
          ..nextLetter() // Move to B
          ..setPhase(SessionPhase.listening)
          ..previousLetter();
        expect(notifier.state.phase, SessionPhase.playing);
      });

      test('previousLetter resets from feedback', () {
        notifier
          ..nextLetter() // Move to B
          ..setPhase(SessionPhase.feedback)
          ..previousLetter();
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

    group('boundary no-ops preserve state', () {
      test('nextLetter at Z does not change state', () {
        // Navigate to Z
        for (var i = 0; i < 25; i++) {
          notifier.nextLetter();
        }
        notifier.setPhase(SessionPhase.feedback);
        final stateAtZ = notifier.state;

        notifier.nextLetter();
        expect(notifier.state, stateAtZ);
      });

      test('previousLetter at A does not change state', () {
        notifier.setPhase(SessionPhase.listening);
        final stateAtA = notifier.state;

        notifier.previousLetter();
        expect(notifier.state, stateAtA);
      });
    });
  });
}
