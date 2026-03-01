import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_digits.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/morse/morse_utils.dart';
import 'package:flutter/foundation.dart';
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

    test('encodes digit character', () {
      expect(encodeLetter('5'), [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
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

    test('decodes digit pattern', () {
      expect(
        decodePattern([
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
        ]),
        '5',
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

    test('returns true for digit pattern (0 = five dashes)', () {
      expect(
        isValidPattern([
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
          MorseSymbol.dash,
        ]),
        isTrue,
      );
    });

    test('returns false for invalid pattern', () {
      // six dots is not a valid pattern for any character
      expect(
        isValidPattern([
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
          MorseSymbol.dot,
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

    test('encode then decode returns original digit for all 0-9', () {
      for (final digit in morseDigitsList) {
        final pattern = encodeLetter(digit);
        expect(pattern, isNotNull, reason: 'Failed to encode $digit');
        final decoded = decodePattern(pattern!);
        expect(decoded, digit, reason: 'Round-trip failed for $digit');
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

  group('composeWordPattern', () {
    test('two-letter word: IT', () {
      final pattern = composeWordPattern('IT', morseAlphabet);
      expect(pattern, [
        MorseSymbol.dot, MorseSymbol.dot, // I
        MorseSymbol.charGap,
        MorseSymbol.dash, // T
      ]);
    });

    test('three-letter word: THE', () {
      final pattern = composeWordPattern('THE', morseAlphabet);
      expect(pattern, [
        MorseSymbol.dash, // T
        MorseSymbol.charGap,
        MorseSymbol.dot, MorseSymbol.dot, MorseSymbol.dot, MorseSymbol.dot, // H
        MorseSymbol.charGap,
        MorseSymbol.dot, // E
      ]);
    });

    test('single-letter word produces no charGap', () {
      final pattern = composeWordPattern('A', morseAlphabet);
      expect(pattern, [MorseSymbol.dot, MorseSymbol.dash]);
      expect(pattern.contains(MorseSymbol.charGap), isFalse);
    });

    test('uses the provided alphabet map', () {
      final customAlphabet = <String, List<MorseSymbol>>{
        'X': [MorseSymbol.dot],
        'Y': [MorseSymbol.dash],
      };
      final pattern = composeWordPattern('XY', customAlphabet);
      expect(pattern, [MorseSymbol.dot, MorseSymbol.charGap, MorseSymbol.dash]);
    });

    test('throws ArgumentError for unknown character', () {
      expect(
        () => composeWordPattern('A1', morseAlphabet),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for empty word', () {
      expect(
        () => composeWordPattern('', morseAlphabet),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('buildWordPatterns', () {
    test('builds patterns for a word list', () {
      final result = buildWordPatterns(['IT', 'IS'], morseAlphabet);
      expect(result.length, 2);
      expect(result.containsKey('IT'), isTrue);
      expect(result.containsKey('IS'), isTrue);
      expect(
        listEquals(result['IT'], composeWordPattern('IT', morseAlphabet)),
        isTrue,
      );
      expect(
        listEquals(result['IS'], composeWordPattern('IS', morseAlphabet)),
        isTrue,
      );
    });

    test('empty word list returns empty map', () {
      final result = buildWordPatterns([], morseAlphabet);
      expect(result, isEmpty);
    });
  });
}
