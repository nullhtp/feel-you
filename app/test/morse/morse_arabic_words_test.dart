import 'package:feel_you/morse/morse_arabic.dart';
import 'package:feel_you/morse/morse_arabic_words.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('morseArabicWordsList', () {
    test('contains exactly 20 words', () {
      expect(morseArabicWordsList.length, 20);
    });

    test('first 5 words are 2-letter words', () {
      for (var i = 0; i < 5; i++) {
        expect(
          morseArabicWordsList[i].length,
          2,
          reason: '${morseArabicWordsList[i]} should be 2 letters',
        );
      }
    });

    test('words 6-10 are 3-letter words', () {
      for (var i = 5; i < 10; i++) {
        expect(
          morseArabicWordsList[i].length,
          3,
          reason: '${morseArabicWordsList[i]} should be 3 letters',
        );
      }
    });

    test('words 11-15 are 4-letter words', () {
      for (var i = 10; i < 15; i++) {
        expect(
          morseArabicWordsList[i].length,
          4,
          reason: '${morseArabicWordsList[i]} should be 4 letters',
        );
      }
    });

    test('words 16-20 are 5-letter words', () {
      for (var i = 15; i < 20; i++) {
        expect(
          morseArabicWordsList[i].length,
          5,
          reason: '${morseArabicWordsList[i]} should be 5 letters',
        );
      }
    });
  });

  group('morseArabicWords map', () {
    test('every word in list has a pattern entry', () {
      for (final word in morseArabicWordsList) {
        expect(
          morseArabicWords.containsKey(word),
          isTrue,
          reason: 'Missing pattern for $word',
        );
      }
    });

    test('no extra entries beyond the word list', () {
      expect(morseArabicWords.length, morseArabicWordsList.length);
    });

    test('patterns do not start with charGap', () {
      for (final entry in morseArabicWords.entries) {
        expect(
          entry.value.first,
          isNot(MorseSymbol.charGap),
          reason: '${entry.key} pattern starts with charGap',
        );
      }
    });

    test('patterns do not end with charGap', () {
      for (final entry in morseArabicWords.entries) {
        expect(
          entry.value.last,
          isNot(MorseSymbol.charGap),
          reason: '${entry.key} pattern ends with charGap',
        );
      }
    });

    test('charGap count equals letter count minus 1', () {
      for (final entry in morseArabicWords.entries) {
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

  group('Arabic word pattern correctness', () {
    test('في pattern is ف(dot dot dash dot) + charGap + ي(dot dot)', () {
      expect(morseArabicWords['في'], [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dash,
        MorseSymbol.dot,
        MorseSymbol.charGap,
        MorseSymbol.dot,
        MorseSymbol.dot,
      ]);
    });

    test('من pattern is م(dash dash) + charGap + ن(dash dot)', () {
      expect(morseArabicWords['من'], [
        MorseSymbol.dash,
        MorseSymbol.dash,
        MorseSymbol.charGap,
        MorseSymbol.dash,
        MorseSymbol.dot,
      ]);
    });

    test('each word pattern matches composed letter patterns', () {
      // Build a combined alphabet that includes أ and ى mapped to alif pattern.
      final alphabet = Map<String, List<MorseSymbol>>.from(morseArabicAlphabet);
      // أ (hamza on alif) uses same pattern as ا
      alphabet['أ'] = morseArabicAlphabet['ا']!;
      // ى (alif maqsura) uses same pattern as ا
      alphabet['ى'] = morseArabicAlphabet['ا']!;

      for (final entry in morseArabicWords.entries) {
        final word = entry.key;
        final pattern = entry.value;

        // Build expected pattern by composing letter patterns with charGaps.
        final expected = <MorseSymbol>[];
        for (var i = 0; i < word.length; i++) {
          final letterPattern = alphabet[word[i]];
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
