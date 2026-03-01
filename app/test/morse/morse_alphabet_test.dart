import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('englishAlphabet.characters', () {
    test('contains all 26 letters', () {
      expect(englishAlphabet.characters.length, 26);
    });

    test('has entries for every letter A-Z', () {
      for (var c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) {
        final letter = String.fromCharCode(c);
        expect(
          englishAlphabet.characters.containsKey(letter),
          isTrue,
          reason: 'Missing letter $letter',
        );
      }
    });

    test('every pattern is non-empty', () {
      for (final entry in englishAlphabet.characters.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key} has empty pattern',
        );
      }
    });

    test('A is dot-dash', () {
      expect(englishAlphabet.characters['A'], [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('E is single dot', () {
      expect(englishAlphabet.characters['E'], [MorseSignal.dot]);
    });

    test('T is single dash', () {
      expect(englishAlphabet.characters['T'], [MorseSignal.dash]);
    });

    test('S is three dots', () {
      expect(englishAlphabet.characters['S'], [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('O is three dashes', () {
      expect(englishAlphabet.characters['O'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });

    test('Q is dash-dash-dot-dash', () {
      expect(englishAlphabet.characters['Q'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('all patterns are unique', () {
      final patterns = englishAlphabet.characters.values.map(
        (p) => p.map((s) => s.name).join(),
      );
      expect(patterns.toSet().length, 26);
    });
  });

  group('englishAlphabet.characterOrder', () {
    test('contains 26 letters', () {
      expect(englishAlphabet.characterOrder.length, 26);
    });

    test('starts with A and ends with Z', () {
      expect(englishAlphabet.characterOrder.first, 'A');
      expect(englishAlphabet.characterOrder.last, 'Z');
    });

    test('is in alphabetical order', () {
      for (var i = 0; i < englishAlphabet.characterOrder.length - 1; i++) {
        expect(
          englishAlphabet.characterOrder[i].compareTo(
            englishAlphabet.characterOrder[i + 1],
          ),
          lessThan(0),
          reason:
              '${englishAlphabet.characterOrder[i]} should come before ${englishAlphabet.characterOrder[i + 1]}',
        );
      }
    });

    test('index 0 is A', () {
      expect(englishAlphabet.characterOrder[0], 'A');
    });
  });
}
