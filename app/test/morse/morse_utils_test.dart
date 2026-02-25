import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/morse/morse_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeLetter', () {
    test('encodes uppercase letter', () {
      expect(encodeLetter('S'), [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
    });

    test('encodes lowercase letter', () {
      expect(encodeLetter('s'), [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
    });

    test('returns null for non-letter character', () {
      expect(encodeLetter('5'), isNull);
    });

    test('returns null for empty string', () {
      expect(encodeLetter(''), isNull);
    });

    test('returns null for special character', () {
      expect(encodeLetter('!'), isNull);
    });

    test('returns null for multi-character string', () {
      // Only single-character lookup — multi-char strings that start with
      // a valid letter will return that letter's pattern via toUpperCase(),
      // but only the first char matters for the map lookup.
      expect(encodeLetter('AB'), isNull);
    });
  });

  group('decodePattern', () {
    test('decodes valid pattern to letter', () {
      expect(decodePattern([MorseSymbol.dot, MorseSymbol.dash]), 'A');
    });

    test('returns null for invalid pattern', () {
      expect(
        decodePattern([
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
        ]),
        isNull,
      );
    });

    test('returns null for empty list', () {
      expect(decodePattern([]), isNull);
    });

    test('decodes single dot to E', () {
      expect(decodePattern([MorseSymbol.dot]), 'E');
    });

    test('decodes single dash to T', () {
      expect(decodePattern([MorseSymbol.dash]), 'T');
    });
  });

  group('isValidPattern', () {
    test('returns true for valid pattern (C)', () {
      expect(
        isValidPattern([
          MorseSymbol.dash,
          MorseSymbol.dot,
          MorseSymbol.dash,
          MorseSymbol.dot,
        ]),
        isTrue,
      );
    });

    test('returns false for invalid pattern', () {
      expect(
        isValidPattern([
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
        ]),
        isFalse,
      );
    });

    test('returns false for empty pattern', () {
      expect(isValidPattern([]), isFalse);
    });
  });

  group('round-trip encode/decode', () {
    test('encode then decode returns original letter for all A-Z', () {
      for (final letter in morseLetters) {
        final pattern = encodeLetter(letter);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        final decoded = decodePattern(pattern!);
        expect(decoded, letter, reason: 'Round-trip failed for $letter');
      }
    });
  });

  group('patternsEqual', () {
    test('returns true for identical patterns', () {
      expect(
        patternsEqual(
          [MorseSymbol.dot, MorseSymbol.dash],
          [MorseSymbol.dot, MorseSymbol.dash],
        ),
        isTrue,
      );
    });

    test('returns false for different patterns', () {
      expect(
        patternsEqual(
          [MorseSymbol.dot, MorseSymbol.dash],
          [MorseSymbol.dash, MorseSymbol.dot],
        ),
        isFalse,
      );
    });

    test('returns false for different lengths', () {
      expect(
        patternsEqual([MorseSymbol.dot], [MorseSymbol.dot, MorseSymbol.dot]),
        isFalse,
      );
    });
  });
}
