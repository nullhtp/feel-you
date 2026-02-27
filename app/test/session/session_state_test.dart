import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionState', () {
    group('initial state', () {
      test('defaults to letter A (index 0)', () {
        const state = SessionState();
        expect(state.letterIndex, 0);
        expect(state.currentLetter, 'A');
      });

      test('defaults to playing phase', () {
        const state = SessionState();
        expect(state.phase, SessionPhase.playing);
      });
    });

    group('currentLetter', () {
      test('returns correct letter for index 0', () {
        const state = SessionState();
        expect(state.currentLetter, 'A');
      });

      test('returns correct letter for index 12 (M)', () {
        const state = SessionState(letterIndex: 12);
        expect(state.currentLetter, 'M');
      });

      test('returns correct letter for index 25 (Z)', () {
        const state = SessionState(letterIndex: 25);
        expect(state.currentLetter, 'Z');
      });
    });

    group('copyWith', () {
      test('copies with new letterIndex', () {
        const original = SessionState();
        final copied = original.copyWith(letterIndex: 5);
        expect(copied.letterIndex, 5);
        expect(copied.phase, SessionPhase.playing);
      });

      test('copies with new phase', () {
        const original = SessionState();
        final copied = original.copyWith(phase: SessionPhase.listening);
        expect(copied.letterIndex, 0);
        expect(copied.phase, SessionPhase.listening);
      });

      test('copies with both fields', () {
        const original = SessionState();
        final copied = original.copyWith(
          letterIndex: 10,
          phase: SessionPhase.feedback,
        );
        expect(copied.letterIndex, 10);
        expect(copied.phase, SessionPhase.feedback);
      });

      test('returns equal state when no fields specified', () {
        const original = SessionState(
          letterIndex: 3,
          phase: SessionPhase.listening,
        );
        final copied = original.copyWith();
        expect(copied, original);
      });
    });

    group('equality', () {
      test('equal when same letterIndex and phase', () {
        const a = SessionState(letterIndex: 5, phase: SessionPhase.feedback);
        const b = SessionState(letterIndex: 5, phase: SessionPhase.feedback);
        expect(a, b);
      });

      test('not equal when different letterIndex', () {
        const a = SessionState();
        const b = SessionState(letterIndex: 1);
        expect(a, isNot(b));
      });

      test('not equal when different phase', () {
        const a = SessionState();
        const b = SessionState(phase: SessionPhase.listening);
        expect(a, isNot(b));
      });

      test('hashCode is consistent with equality', () {
        const a = SessionState(letterIndex: 5, phase: SessionPhase.feedback);
        const b = SessionState(letterIndex: 5, phase: SessionPhase.feedback);
        expect(a.hashCode, b.hashCode);
      });
    });

    group('toString', () {
      test('includes letter and phase', () {
        const state = SessionState(
          letterIndex: 2,
          phase: SessionPhase.listening,
        );
        expect(
          state.toString(),
          'SessionState(letter: C, phase: SessionPhase.listening)',
        );
      });
    });
  });
}
