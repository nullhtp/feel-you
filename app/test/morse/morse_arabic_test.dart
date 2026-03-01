import 'package:feel_you/morse/morse_arabic.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('morseArabicAlphabet', () {
    test('contains all 28 Arabic letters', () {
      expect(morseArabicAlphabet.length, 28);
    });

    test('every pattern is non-empty', () {
      for (final entry in morseArabicAlphabet.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key} has empty pattern',
        );
      }
    });

    test('ا (Alif) is dot-dash', () {
      expect(morseArabicAlphabet['ا'], [MorseSymbol.dot, MorseSymbol.dash]);
    });

    test('ت (Ta) is single dash', () {
      expect(morseArabicAlphabet['ت'], [MorseSymbol.dash]);
    });

    test('س (Sin) is three dots', () {
      expect(morseArabicAlphabet['س'], [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
    });

    test('ق (Qaf) is dash-dash-dot-dash', () {
      expect(morseArabicAlphabet['ق'], [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dot,
        MorseSymbol.dash,
      ]);
    });

    test('ش (Shin) is four dashes', () {
      expect(morseArabicAlphabet['ش'], [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dash,
      ]);
    });
  });

  group('morseArabicLetters', () {
    test('contains 28 letters', () {
      expect(morseArabicLetters.length, 28);
    });

    test('starts with ا (Alif) and ends with ي (Ya)', () {
      expect(morseArabicLetters.first, 'ا');
      expect(morseArabicLetters.last, 'ي');
    });

    test('index 0 is ا (Alif)', () {
      expect(morseArabicLetters[0], 'ا');
    });

    test('every letter in list has a pattern', () {
      for (final letter in morseArabicLetters) {
        expect(
          morseArabicAlphabet.containsKey(letter),
          isTrue,
          reason: 'Missing pattern for $letter',
        );
      }
    });
  });
}
