import 'package:feel_you/morse/levels.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionState', () {
    group('initial state', () {
      test('defaults to digit 0 (levelIndex 0, positionIndex 0)', () {
        const state = SessionState();
        expect(state.levelIndex, 0);
        expect(state.positionIndex, 0);
        expect(state.currentCharacter, '0');
      });

      test('defaults to playing phase', () {
        const state = SessionState();
        expect(state.phase, SessionPhase.playing);
      });
    });

    group('currentCharacter', () {
      test('returns correct character for digits level index 0', () {
        const state = SessionState();
        expect(state.currentCharacter, '0');
      });

      test('returns correct character for digits level position 5', () {
        const state = SessionState(positionIndex: 5);
        expect(state.currentCharacter, '5');
      });

      test('returns correct character for letters level position 0', () {
        const state = SessionState(levelIndex: 1);
        expect(state.currentCharacter, 'A');
      });

      test('returns correct character for letters level position 12', () {
        const state = SessionState(levelIndex: 1, positionIndex: 12);
        expect(state.currentCharacter, 'M');
      });

      test('returns correct character for letters level position 25', () {
        const state = SessionState(levelIndex: 1, positionIndex: 25);
        expect(state.currentCharacter, 'Z');
      });
    });

    group('currentLevel', () {
      test('returns digits level for levelIndex 0', () {
        const state = SessionState();
        expect(state.currentLevel, levels[0]);
        expect(state.currentLevel.name, 'digits');
      });

      test('returns letters level for levelIndex 1', () {
        const state = SessionState(levelIndex: 1);
        expect(state.currentLevel, levels[1]);
        expect(state.currentLevel.name, 'letters');
      });
    });

    group('copyWith', () {
      test('copies with new positionIndex', () {
        const original = SessionState();
        final copied = original.copyWith(positionIndex: 5);
        expect(copied.positionIndex, 5);
        expect(copied.phase, SessionPhase.playing);
      });

      test('copies with new phase', () {
        const original = SessionState();
        final copied = original.copyWith(phase: SessionPhase.listening);
        expect(copied.positionIndex, 0);
        expect(copied.phase, SessionPhase.listening);
      });

      test('copies with both fields', () {
        const original = SessionState();
        final copied = original.copyWith(
          positionIndex: 5,
          phase: SessionPhase.feedback,
        );
        expect(copied.positionIndex, 5);
        expect(copied.phase, SessionPhase.feedback);
      });

      test('copies with new levelIndex', () {
        const original = SessionState();
        final copied = original.copyWith(levelIndex: 1);
        expect(copied.levelIndex, 1);
        expect(copied.positionIndex, 0);
      });

      test('returns equal state when no fields specified', () {
        const original = SessionState(
          levelIndex: 1,
          positionIndex: 3,
          phase: SessionPhase.listening,
        );
        final copied = original.copyWith();
        expect(copied, original);
      });
    });

    group('equality', () {
      test('equal when same levelIndex, positionIndex, and phase', () {
        const a = SessionState(
          levelIndex: 1,
          positionIndex: 5,
          phase: SessionPhase.feedback,
        );
        const b = SessionState(
          levelIndex: 1,
          positionIndex: 5,
          phase: SessionPhase.feedback,
        );
        expect(a, b);
      });

      test('not equal when different positionIndex', () {
        const a = SessionState();
        const b = SessionState(positionIndex: 1);
        expect(a, isNot(b));
      });

      test('not equal when different levelIndex', () {
        const a = SessionState();
        const b = SessionState(levelIndex: 1);
        expect(a, isNot(b));
      });

      test('not equal when different phase', () {
        const a = SessionState();
        const b = SessionState(phase: SessionPhase.listening);
        expect(a, isNot(b));
      });

      test('hashCode is consistent with equality', () {
        const a = SessionState(
          levelIndex: 1,
          positionIndex: 5,
          phase: SessionPhase.feedback,
        );
        const b = SessionState(
          levelIndex: 1,
          positionIndex: 5,
          phase: SessionPhase.feedback,
        );
        expect(a.hashCode, b.hashCode);
      });
    });

    group('toString', () {
      test('includes level, character, and phase', () {
        const state = SessionState(
          levelIndex: 1,
          positionIndex: 2,
          phase: SessionPhase.listening,
        );
        expect(
          state.toString(),
          'SessionState(level: letters, '
          'character: C, phase: SessionPhase.listening)',
        );
      });
    });
  });
}
