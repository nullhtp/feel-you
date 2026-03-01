import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('arabicAlphabet.wordList', () {
    test('contains exactly 20 words', () {
      expect(arabicAlphabet.wordList!.length, 20);
    });

    test('first 5 words are 2-letter words', () {
      for (var i = 0; i < 5; i++) {
        expect(
          arabicAlphabet.wordList![i].length,
          2,
          reason: '${arabicAlphabet.wordList![i]} should be 2 letters',
        );
      }
    });

    test('words 6-10 are 3-letter words', () {
      for (var i = 5; i < 10; i++) {
        expect(
          arabicAlphabet.wordList![i].length,
          3,
          reason: '${arabicAlphabet.wordList![i]} should be 3 letters',
        );
      }
    });

    test('words 11-15 are 4-letter words', () {
      for (var i = 10; i < 15; i++) {
        expect(
          arabicAlphabet.wordList![i].length,
          4,
          reason: '${arabicAlphabet.wordList![i]} should be 4 letters',
        );
      }
    });

    test('words 16-20 are 5-letter words', () {
      for (var i = 15; i < 20; i++) {
        expect(
          arabicAlphabet.wordList![i].length,
          5,
          reason: '${arabicAlphabet.wordList![i]} should be 5 letters',
        );
      }
    });
  });

  group('arabicAlphabet.wordPatterns map', () {
    test('every word in list has a pattern entry', () {
      for (final word in arabicAlphabet.wordList!) {
        expect(
          arabicAlphabet.wordPatterns!.containsKey(word),
          isTrue,
          reason: 'Missing pattern for $word',
        );
      }
    });

    test('no extra entries beyond the word list', () {
      expect(
        arabicAlphabet.wordPatterns!.length,
        arabicAlphabet.wordList!.length,
      );
    });

    test('patterns do not start with CharGap', () {
      for (final entry in arabicAlphabet.wordPatterns!.entries) {
        expect(
          entry.value.first,
          isNot(isA<CharGap>()),
          reason: '${entry.key} pattern starts with CharGap',
        );
      }
    });

    test('patterns do not end with CharGap', () {
      for (final entry in arabicAlphabet.wordPatterns!.entries) {
        expect(
          entry.value.last,
          isNot(isA<CharGap>()),
          reason: '${entry.key} pattern ends with CharGap',
        );
      }
    });

    test('CharGap count equals letter count minus 1', () {
      for (final entry in arabicAlphabet.wordPatterns!.entries) {
        final charGapCount = entry.value.whereType<CharGap>().length;
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
    test('في pattern is ف(dot dot dash dot) + CharGap + ي(dot dot)', () {
      expect(arabicAlphabet.wordPatterns!['في'], [
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot),
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
      ]);
    });

    test('من pattern is م(dash dash) + CharGap + ن(dash dot)', () {
      expect(arabicAlphabet.wordPatterns!['من'], [
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dash),
        const CharGap(),
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot),
      ]);
    });

    test('هذا pattern is ه + ذ + ا', () {
      expect(arabicAlphabet.wordPatterns!['هذا'], [
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot), // ه: ··−··
        const CharGap(),
        const Signal(MorseSignal.dash), const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot), const Signal(MorseSignal.dot), // ذ: −−··
        const CharGap(),
        const Signal(MorseSignal.dot), const Signal(MorseSignal.dash), // ا: ·−
      ]);
    });
  });
}
