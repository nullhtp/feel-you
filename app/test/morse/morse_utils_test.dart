import 'package:feel_you/morse/morse.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeLetter', () {
    test('encodes uppercase letter', () {
      expect(encodeLetter('S', MorseLanguage.english), [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('encodes lowercase letter', () {
      expect(encodeLetter('s', MorseLanguage.english), [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('encodes digit character', () {
      expect(encodeLetter('5', MorseLanguage.english), [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('returns null for empty string', () {
      expect(encodeLetter('', MorseLanguage.english), isNull);
    });

    test('returns null for special character', () {
      expect(encodeLetter('!', MorseLanguage.english), isNull);
    });

    test('returns null for multi-character string', () {
      // Only single-character lookup — multi-char strings that start with
      // a valid letter will return that letter's pattern via toUpperCase(),
      // but only the first char matters for the map lookup.
      expect(encodeLetter('AB', MorseLanguage.english), isNull);
    });
  });

  group('decodePattern', () {
    test('decodes valid pattern to letter', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dash,
        ], MorseLanguage.english),
        'A',
      );
    });

    test('decodes digit pattern', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
        ], MorseLanguage.english),
        '5',
      );
    });

    test('returns null for empty list', () {
      expect(decodePattern([], MorseLanguage.english), isNull);
    });

    test('decodes single dot to E', () {
      expect(decodePattern([MorseSignal.dot], MorseLanguage.english), 'E');
    });

    test('decodes single dash to T', () {
      expect(decodePattern([MorseSignal.dash], MorseLanguage.english), 'T');
    });
  });

  group('isValidPattern', () {
    test('returns true for valid pattern (C)', () {
      expect(
        isValidPattern([
          MorseSignal.dash,
          MorseSignal.dot,
          MorseSignal.dash,
          MorseSignal.dot,
        ], MorseLanguage.english),
        isTrue,
      );
    });

    test('returns true for digit pattern (0 = five dashes)', () {
      expect(
        isValidPattern([
          MorseSignal.dash,
          MorseSignal.dash,
          MorseSignal.dash,
          MorseSignal.dash,
          MorseSignal.dash,
        ], MorseLanguage.english),
        isTrue,
      );
    });

    test('returns false for invalid pattern', () {
      // six dots is not a valid pattern for any character
      expect(
        isValidPattern([
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
        ], MorseLanguage.english),
        isFalse,
      );
    });

    test('returns false for empty pattern', () {
      expect(isValidPattern([], MorseLanguage.english), isFalse);
    });
  });

  group('round-trip encode/decode', () {
    test('encode then decode returns original letter for all A-Z', () {
      for (final letter in englishAlphabet.characterOrder) {
        final pattern = encodeLetter(letter, MorseLanguage.english);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        final decoded = decodePattern(pattern!, MorseLanguage.english);
        expect(decoded, letter, reason: 'Round-trip failed for $letter');
      }
    });

    test('encode then decode returns original digit for all 0-9', () {
      for (final digit in digitAlphabet.characterOrder) {
        final pattern = encodeLetter(digit, MorseLanguage.english);
        expect(pattern, isNotNull, reason: 'Failed to encode $digit');
        final decoded = decodePattern(pattern!, MorseLanguage.english);
        expect(decoded, digit, reason: 'Round-trip failed for $digit');
      }
    });
  });

  group('patternsEqual', () {
    test('returns true for identical patterns', () {
      expect(
        patternsEqual(
          [MorseSignal.dot, MorseSignal.dash],
          [MorseSignal.dot, MorseSignal.dash],
        ),
        isTrue,
      );
    });

    test('returns false for different patterns', () {
      expect(
        patternsEqual(
          [MorseSignal.dot, MorseSignal.dash],
          [MorseSignal.dash, MorseSignal.dot],
        ),
        isFalse,
      );
    });

    test('returns false for different lengths', () {
      expect(
        patternsEqual([MorseSignal.dot], [MorseSignal.dot, MorseSignal.dot]),
        isFalse,
      );
    });
  });

  group('composeWordPattern', () {
    test('two-letter word: IT', () {
      final pattern = composeWordPattern('IT', englishAlphabet.characters);
      expect(pattern, [
        const Signal(MorseSignal.dot), const Signal(MorseSignal.dot), // I
        const CharGap(),
        const Signal(MorseSignal.dash), // T
      ]);
    });

    test('three-letter word: THE', () {
      final pattern = composeWordPattern('THE', englishAlphabet.characters);
      expect(pattern, [
        const Signal(MorseSignal.dash), // T
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot), // H
        const CharGap(),
        const Signal(MorseSignal.dot), // E
      ]);
    });

    test('single-letter word produces no charGap', () {
      final pattern = composeWordPattern('A', englishAlphabet.characters);
      expect(pattern, [
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
      ]);
      expect(pattern.whereType<CharGap>().isEmpty, isTrue);
    });

    test('uses the provided alphabet map', () {
      final customAlphabet = <String, List<MorseSignal>>{
        'X': [MorseSignal.dot],
        'Y': [MorseSignal.dash],
      };
      final pattern = composeWordPattern('XY', customAlphabet);
      expect(pattern, [
        const Signal(MorseSignal.dot),
        const CharGap(),
        const Signal(MorseSignal.dash),
      ]);
    });

    test('throws ArgumentError for unknown character', () {
      expect(
        () => composeWordPattern('A1', englishAlphabet.characters),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for empty word', () {
      expect(
        () => composeWordPattern('', englishAlphabet.characters),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('buildWordPatterns', () {
    test('builds patterns for a word list', () {
      final result = buildWordPatterns([
        'IT',
        'IS',
      ], englishAlphabet.characters);
      expect(result.length, 2);
      expect(result.containsKey('IT'), isTrue);
      expect(result.containsKey('IS'), isTrue);
      expect(
        listEquals(
          result['IT'],
          composeWordPattern('IT', englishAlphabet.characters),
        ),
        isTrue,
      );
      expect(
        listEquals(
          result['IS'],
          composeWordPattern('IS', englishAlphabet.characters),
        ),
        isTrue,
      );
    });

    test('empty word list returns empty map', () {
      final result = buildWordPatterns([], englishAlphabet.characters);
      expect(result, isEmpty);
    });
  });
}
