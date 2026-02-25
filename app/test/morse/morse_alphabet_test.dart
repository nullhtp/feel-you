import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('morseAlphabet', () {
    test('contains all 26 letters', () {
      expect(morseAlphabet.length, 26);
    });

    test('has entries for every letter A-Z', () {
      for (var c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) {
        final letter = String.fromCharCode(c);
        expect(
          morseAlphabet.containsKey(letter),
          isTrue,
          reason: 'Missing letter $letter',
        );
      }
    });

    test('every pattern is non-empty', () {
      for (final entry in morseAlphabet.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key} has empty pattern',
        );
      }
    });

    test('A is dot-dash', () {
      expect(morseAlphabet['A'], [MorseSymbol.dot, MorseSymbol.dash]);
    });

    test('E is single dot', () {
      expect(morseAlphabet['E'], [MorseSymbol.dot]);
    });

    test('T is single dash', () {
      expect(morseAlphabet['T'], [MorseSymbol.dash]);
    });

    test('S is three dots', () {
      expect(morseAlphabet['S'], [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
    });

    test('O is three dashes', () {
      expect(morseAlphabet['O'], [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
      ]);
    });

    test('Q is dash-dash-dot-dash', () {
      expect(morseAlphabet['Q'], [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dot,
        MorseSymbol.dash,
      ]);
    });

    test('all patterns are unique', () {
      final patterns = morseAlphabet.values.map(
        (p) => p.map((s) => s.name).join(),
      );
      expect(patterns.toSet().length, 26);
    });
  });

  group('morseLetters', () {
    test('contains 26 letters', () {
      expect(morseLetters.length, 26);
    });

    test('starts with A and ends with Z', () {
      expect(morseLetters.first, 'A');
      expect(morseLetters.last, 'Z');
    });

    test('is in alphabetical order', () {
      for (var i = 0; i < morseLetters.length - 1; i++) {
        expect(
          morseLetters[i].compareTo(morseLetters[i + 1]),
          lessThan(0),
          reason:
              '${morseLetters[i]} should come before ${morseLetters[i + 1]}',
        );
      }
    });

    test('index 0 is A', () {
      expect(morseLetters[0], 'A');
    });
  });
}
