import 'package:feel_you/morse/morse_arabic.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/morse/morse_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeLetter (Arabic)', () {
    test('encodes Arabic letter س (Sin)', () {
      expect(encodeLetter('س'), [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
    });

    test('encodes Arabic letter ا (Alif)', () {
      expect(encodeLetter('ا'), [MorseSymbol.dot, MorseSymbol.dash]);
    });

    test('encodes Arabic letter ق (Qaf)', () {
      expect(encodeLetter('ق'), [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.dot,
        MorseSymbol.dash,
      ]);
    });
  });

  group('decodePatternForLanguage', () {
    test('dot-dash decodes to A in English', () {
      expect(
        decodePatternForLanguage([
          MorseSymbol.dot,
          MorseSymbol.dash,
        ], MorseLanguage.english),
        'A',
      );
    });

    test('dot-dash decodes to ا in Arabic', () {
      expect(
        decodePatternForLanguage([
          MorseSymbol.dot,
          MorseSymbol.dash,
        ], MorseLanguage.arabic),
        'ا',
      );
    });

    test('three dots decodes to S in English', () {
      expect(
        decodePatternForLanguage([
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
        ], MorseLanguage.english),
        'S',
      );
    });

    test('three dots decodes to س in Arabic', () {
      expect(
        decodePatternForLanguage([
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
        ], MorseLanguage.arabic),
        'س',
      );
    });

    test('returns null for empty pattern', () {
      expect(decodePatternForLanguage([], MorseLanguage.english), isNull);
    });

    test('digit patterns work in both languages', () {
      final fiveDots = [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ];
      expect(decodePatternForLanguage(fiveDots, MorseLanguage.english), '5');
      expect(decodePatternForLanguage(fiveDots, MorseLanguage.arabic), '5');
    });
  });

  group('isValidPattern (Arabic)', () {
    test('Arabic-only pattern (4 dashes = ش Shin) is valid', () {
      expect(
        isValidPattern([
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
        ]),
        isTrue,
      );
    });
  });

  group('round-trip encode/decode for Arabic', () {
    test('encode then decode returns original for all Arabic letters', () {
      for (final letter in morseArabicLetters) {
        final pattern = encodeLetter(letter);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        final decoded = decodePatternForLanguage(
          pattern!,
          MorseLanguage.arabic,
        );
        expect(decoded, letter, reason: 'Round-trip failed for $letter');
      }
    });
  });
}
