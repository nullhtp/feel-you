import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('digitAlphabet.characters', () {
    test('contains all 10 digits', () {
      expect(digitAlphabet.characters.length, 10);
    });

    test('has entries for every digit 0-9', () {
      for (var i = 0; i <= 9; i++) {
        final digit = '$i';
        expect(
          digitAlphabet.characters.containsKey(digit),
          isTrue,
          reason: 'Missing digit $digit',
        );
      }
    });

    test('every pattern is non-empty', () {
      for (final entry in digitAlphabet.characters.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key} has empty pattern',
        );
      }
    });

    test('every digit pattern has exactly 5 symbols', () {
      for (final entry in digitAlphabet.characters.entries) {
        expect(
          entry.value.length,
          5,
          reason: '${entry.key} should have 5 symbols',
        );
      }
    });

    test('0 is five dashes', () {
      expect(digitAlphabet.characters['0'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });

    test('1 is dot then four dashes', () {
      expect(digitAlphabet.characters['1'], [
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });

    test('5 is five dots', () {
      expect(digitAlphabet.characters['5'], [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('9 is four dashes then dot', () {
      expect(digitAlphabet.characters['9'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
      ]);
    });

    test('all patterns are unique', () {
      final patterns = digitAlphabet.characters.values.map(
        (p) => p.map((s) => s.name).join(),
      );
      expect(patterns.toSet().length, 10);
    });

    test('no digit pattern matches any letter pattern', () {
      final letterPatterns = englishAlphabet.characters.values
          .map((p) => p.map((s) => s.name).join())
          .toSet();
      for (final entry in digitAlphabet.characters.entries) {
        final digitPattern = entry.value.map((s) => s.name).join();
        expect(
          letterPatterns.contains(digitPattern),
          isFalse,
          reason: 'Digit ${entry.key} pattern collides with a letter pattern',
        );
      }
    });
  });

  group('digitAlphabet.characterOrder', () {
    test('contains 10 digits', () {
      expect(digitAlphabet.characterOrder.length, 10);
    });

    test('starts with 0 and ends with 9', () {
      expect(digitAlphabet.characterOrder.first, '0');
      expect(digitAlphabet.characterOrder.last, '9');
    });

    test('is in numerical order', () {
      for (var i = 0; i < digitAlphabet.characterOrder.length; i++) {
        expect(digitAlphabet.characterOrder[i], '$i');
      }
    });
  });
}
