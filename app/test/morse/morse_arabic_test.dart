import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('arabicAlphabet.characters', () {
    test('contains all 28 Arabic letters', () {
      expect(arabicAlphabet.characters.length, 28);
    });

    test('every pattern is non-empty', () {
      for (final entry in arabicAlphabet.characters.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key} has empty pattern',
        );
      }
    });

    test('ا (Alif) is dot-dash', () {
      expect(arabicAlphabet.characters['ا'], [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('ت (Ta) is single dash', () {
      expect(arabicAlphabet.characters['ت'], [MorseSignal.dash]);
    });

    test('س (Sin) is three dots', () {
      expect(arabicAlphabet.characters['س'], [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('ق (Qaf) is dash-dash-dot-dash', () {
      expect(arabicAlphabet.characters['ق'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('ش (Shin) is four dashes', () {
      expect(arabicAlphabet.characters['ش'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });
  });

  group('arabicAlphabet.characterOrder', () {
    test('contains 28 letters', () {
      expect(arabicAlphabet.characterOrder.length, 28);
    });

    test('starts with ا (Alif) and ends with ي (Ya)', () {
      expect(arabicAlphabet.characterOrder.first, 'ا');
      expect(arabicAlphabet.characterOrder.last, 'ي');
    });

    test('index 0 is ا (Alif)', () {
      expect(arabicAlphabet.characterOrder[0], 'ا');
    });

    test('every letter in list has a pattern', () {
      for (final letter in arabicAlphabet.characterOrder) {
        expect(
          arabicAlphabet.characters.containsKey(letter),
          isTrue,
          reason: 'Missing pattern for $letter',
        );
      }
    });
  });
}
