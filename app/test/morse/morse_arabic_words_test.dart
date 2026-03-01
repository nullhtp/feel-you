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
    test('كل pattern is ك(dash dot dash) + CharGap + ل(dot dash dot dot)', () {
      expect(arabicAlphabet.wordPatterns!['كل'], [
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash), // ك
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot), // ل
      ]);
    });

    test(
      'نعم pattern is ن(dash dot) + CharGap + ع(dot dash dot dash) + CharGap + م(dash dash)',
      () {
        expect(arabicAlphabet.wordPatterns!['نعم'], [
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dot), // ن
          const CharGap(),
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dash), // ع
          const CharGap(),
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dash), // م
        ]);
      },
    );

    test(
      'ألم pattern is أ(dot dash) + CharGap + ل(dot dash dot dot) + CharGap + م(dash dash)',
      () {
        expect(arabicAlphabet.wordPatterns!['ألم'], [
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dash), // أ (alias for ا)
          const CharGap(),
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dot), // ل
          const CharGap(),
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dash), // م
        ]);
      },
    );
  });
}
