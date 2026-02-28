import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_digits.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('morseDigits', () {
    test('contains all 10 digits', () {
      expect(morseDigits.length, 10);
    });

    test('has entries for every digit 0-9', () {
      for (var i = 0; i <= 9; i++) {
        final digit = '$i';
        expect(
          morseDigits.containsKey(digit),
          isTrue,
          reason: 'Missing digit $digit',
        );
      }
    });

    test('every pattern is non-empty', () {
      for (final entry in morseDigits.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key} has empty pattern',
        );
      }
    });

    test('every digit pattern has exactly 5 symbols', () {
      for (final entry in morseDigits.entries) {
        expect(
          entry.value.length,
          5,
          reason: '${entry.key} should have 5 symbols',
        );
      }
    });

    test('0 is five dashes', () {
      expect(morseDigits['0'], [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
      ]);
    });

    test('1 is dot then four dashes', () {
      expect(morseDigits['1'], [
        MorseSymbol.dot,
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
      ]);
    });

    test('5 is five dots', () {
      expect(morseDigits['5'], [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
    });

    test('9 is four dashes then dot', () {
      expect(morseDigits['9'], [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dot,
      ]);
    });

    test('all patterns are unique', () {
      final patterns = morseDigits.values.map(
        (p) => p.map((s) => s.name).join(),
      );
      expect(patterns.toSet().length, 10);
    });

    test('no digit pattern matches any letter pattern', () {
      final letterPatterns = morseAlphabet.values
          .map((p) => p.map((s) => s.name).join())
          .toSet();
      for (final entry in morseDigits.entries) {
        final digitPattern = entry.value.map((s) => s.name).join();
        expect(
          letterPatterns.contains(digitPattern),
          isFalse,
          reason: 'Digit ${entry.key} pattern collides with a letter pattern',
        );
      }
    });
  });

  group('morseDigitsList', () {
    test('contains 10 digits', () {
      expect(morseDigitsList.length, 10);
    });

    test('starts with 0 and ends with 9', () {
      expect(morseDigitsList.first, '0');
      expect(morseDigitsList.last, '9');
    });

    test('is in numerical order', () {
      for (var i = 0; i < morseDigitsList.length; i++) {
        expect(morseDigitsList[i], '$i');
      }
    });
  });
}
