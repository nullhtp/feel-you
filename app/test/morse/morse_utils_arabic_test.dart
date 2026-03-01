import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeLetter (Arabic)', () {
    test('encodes Arabic letter س (Sin)', () {
      expect(encodeLetter('س', MorseLanguage.arabic), [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('encodes Arabic letter ا (Alif)', () {
      expect(encodeLetter('ا', MorseLanguage.arabic), [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('encodes Arabic letter ق (Qaf)', () {
      expect(encodeLetter('ق', MorseLanguage.arabic), [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });
  });

  group('decodePattern (language-specific)', () {
    test('dot-dash decodes to A in English', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dash,
        ], MorseLanguage.english),
        'A',
      );
    });

    test('dot-dash decodes to ا in Arabic', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dash,
        ], MorseLanguage.arabic),
        'ا',
      );
    });

    test('three dots decodes to S in English', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
        ], MorseLanguage.english),
        'S',
      );
    });

    test('three dots decodes to س in Arabic', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
        ], MorseLanguage.arabic),
        'س',
      );
    });

    test('returns null for empty pattern', () {
      expect(decodePattern([], MorseLanguage.english), isNull);
    });

    test('digit patterns work in both languages', () {
      final fiveDots = [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ];
      expect(decodePattern(fiveDots, MorseLanguage.english), '5');
      expect(decodePattern(fiveDots, MorseLanguage.arabic), '5');
    });
  });

  group('isValidPattern (Arabic)', () {
    test('Arabic-only pattern (4 dashes = ش Shin) is valid', () {
      expect(
        isValidPattern([
          MorseSignal.dash,
          MorseSignal.dash,
          MorseSignal.dash,
          MorseSignal.dash,
        ], MorseLanguage.arabic),
        isTrue,
      );
    });
  });

  group('round-trip encode/decode for Arabic', () {
    test('encode then decode returns original for all Arabic letters', () {
      for (final letter in arabicAlphabet.characterOrder) {
        final pattern = encodeLetter(letter, MorseLanguage.arabic);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        final decoded = decodePattern(pattern!, MorseLanguage.arabic);
        expect(decoded, letter, reason: 'Round-trip failed for $letter');
      }
    });
  });
}
