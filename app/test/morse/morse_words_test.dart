import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/morse/morse_words.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('morseWordsList', () {
    test('contains exactly 20 words', () {
      expect(morseWordsList.length, 20);
    });

    test('first 5 words are 2-letter words', () {
      for (var i = 0; i < 5; i++) {
        expect(
          morseWordsList[i].length,
          2,
          reason: '${morseWordsList[i]} should be 2 letters',
        );
      }
    });

    test('words 6-10 are 3-letter words', () {
      for (var i = 5; i < 10; i++) {
        expect(
          morseWordsList[i].length,
          3,
          reason: '${morseWordsList[i]} should be 3 letters',
        );
      }
    });

    test('words 11-15 are 4-letter words', () {
      for (var i = 10; i < 15; i++) {
        expect(
          morseWordsList[i].length,
          4,
          reason: '${morseWordsList[i]} should be 4 letters',
        );
      }
    });

    test('words 16-20 are 5-letter words', () {
      for (var i = 15; i < 20; i++) {
        expect(
          morseWordsList[i].length,
          5,
          reason: '${morseWordsList[i]} should be 5 letters',
        );
      }
    });

    test('all words are uppercase', () {
      for (final word in morseWordsList) {
        expect(word, word.toUpperCase(), reason: '$word should be uppercase');
      }
    });

    test('exact word list content', () {
      expect(morseWordsList, [
        'IT',
        'IS',
        'TO',
        'IN',
        'AT',
        'THE',
        'AND',
        'FOR',
        'ARE',
        'BUT',
        'THAT',
        'WITH',
        'HAVE',
        'THIS',
        'FROM',
        'THEIR',
        'ABOUT',
        'WHICH',
        'WOULD',
        'THERE',
      ]);
    });
  });

  group('morseWords map', () {
    test('every word in list has a pattern entry', () {
      for (final word in morseWordsList) {
        expect(
          morseWords.containsKey(word),
          isTrue,
          reason: 'Missing pattern for $word',
        );
      }
    });

    test('no extra entries beyond the word list', () {
      expect(morseWords.length, morseWordsList.length);
    });

    test('patterns do not start with charGap', () {
      for (final entry in morseWords.entries) {
        expect(
          entry.value.first,
          isNot(MorseSymbol.charGap),
          reason: '${entry.key} pattern starts with charGap',
        );
      }
    });

    test('patterns do not end with charGap', () {
      for (final entry in morseWords.entries) {
        expect(
          entry.value.last,
          isNot(MorseSymbol.charGap),
          reason: '${entry.key} pattern ends with charGap',
        );
      }
    });

    test('charGap count equals letter count minus 1', () {
      for (final entry in morseWords.entries) {
        final charGapCount = entry.value
            .where((s) => s == MorseSymbol.charGap)
            .length;
        expect(
          charGapCount,
          entry.key.length - 1,
          reason:
              '${entry.key} has $charGapCount charGaps, '
              'expected ${entry.key.length - 1}',
        );
      }
    });
  });

  group('word pattern correctness', () {
    test('IT pattern is I(dot dot) + charGap + T(dash)', () {
      expect(morseWords['IT'], [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.charGap,
        MorseSymbol.dash,
      ]);
    });

    test('THE pattern is T(dash) + charGap + H(dot x4) + charGap + E(dot)', () {
      expect(morseWords['THE'], [
        MorseSymbol.dash,
        MorseSymbol.charGap,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.charGap,
        MorseSymbol.dot,
      ]);
    });

    test('each word pattern matches composed letter patterns', () {
      for (final entry in morseWords.entries) {
        final word = entry.key;
        final pattern = entry.value;

        // Build expected pattern by composing letter patterns with charGaps
        final expected = <MorseSymbol>[];
        for (var i = 0; i < word.length; i++) {
          final letterPattern = morseAlphabet[word[i]];
          expect(
            letterPattern,
            isNotNull,
            reason: 'Unknown letter ${word[i]} in $word',
          );
          expected.addAll(letterPattern!);
          if (i < word.length - 1) {
            expected.add(MorseSymbol.charGap);
          }
        }
        expect(
          pattern,
          expected,
          reason: '$word pattern does not match composed letter patterns',
        );
      }
    });
  });
}
