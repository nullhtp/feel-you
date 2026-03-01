import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('englishAlphabet.wordList', () {
    test('contains exactly 20 words', () {
      expect(englishAlphabet.wordList!.length, 20);
    });

    test('first 5 words are 2-letter words', () {
      for (var i = 0; i < 5; i++) {
        expect(
          englishAlphabet.wordList![i].length,
          2,
          reason: '${englishAlphabet.wordList![i]} should be 2 letters',
        );
      }
    });

    test('words 6-10 are 3-letter words', () {
      for (var i = 5; i < 10; i++) {
        expect(
          englishAlphabet.wordList![i].length,
          3,
          reason: '${englishAlphabet.wordList![i]} should be 3 letters',
        );
      }
    });

    test('words 11-15 are 4-letter words', () {
      for (var i = 10; i < 15; i++) {
        expect(
          englishAlphabet.wordList![i].length,
          4,
          reason: '${englishAlphabet.wordList![i]} should be 4 letters',
        );
      }
    });

    test('words 16-20 are 5-letter words', () {
      for (var i = 15; i < 20; i++) {
        expect(
          englishAlphabet.wordList![i].length,
          5,
          reason: '${englishAlphabet.wordList![i]} should be 5 letters',
        );
      }
    });

    test('all words are uppercase', () {
      for (final word in englishAlphabet.wordList!) {
        expect(word, word.toUpperCase(), reason: '$word should be uppercase');
      }
    });

    test('exact word list content', () {
      expect(englishAlphabet.wordList, [
        'HI',
        'OK',
        'NO',
        'GO',
        'UP',
        'YES',
        'EAT',
        'HOT',
        'SIT',
        'BAD',
        'HELP',
        'COLD',
        'PAIN',
        'GOOD',
        'STOP',
        'WATER',
        'HAPPY',
        'TIRED',
        'SORRY',
        'THANK',
      ]);
    });
  });

  group('englishAlphabet.wordPatterns map', () {
    test('every word in list has a pattern entry', () {
      for (final word in englishAlphabet.wordList!) {
        expect(
          englishAlphabet.wordPatterns!.containsKey(word),
          isTrue,
          reason: 'Missing pattern for $word',
        );
      }
    });

    test('no extra entries beyond the word list', () {
      expect(
        englishAlphabet.wordPatterns!.length,
        englishAlphabet.wordList!.length,
      );
    });

    test('patterns do not start with CharGap', () {
      for (final entry in englishAlphabet.wordPatterns!.entries) {
        expect(
          entry.value.first,
          isNot(isA<CharGap>()),
          reason: '${entry.key} pattern starts with CharGap',
        );
      }
    });

    test('patterns do not end with CharGap', () {
      for (final entry in englishAlphabet.wordPatterns!.entries) {
        expect(
          entry.value.last,
          isNot(isA<CharGap>()),
          reason: '${entry.key} pattern ends with CharGap',
        );
      }
    });

    test('CharGap count equals letter count minus 1', () {
      for (final entry in englishAlphabet.wordPatterns!.entries) {
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

  group('word pattern correctness', () {
    test('HI pattern is H(dot x4) + CharGap + I(dot dot)', () {
      expect(englishAlphabet.wordPatterns!['HI'], [
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot), // H
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot), // I
      ]);
    });

    test(
      'YES pattern is Y(dash dot dash dash) + CharGap + E(dot) + CharGap + S(dot x3)',
      () {
        expect(englishAlphabet.wordPatterns!['YES'], [
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dash), // Y
          const CharGap(),
          const Signal(MorseSignal.dot), // E
          const CharGap(),
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dot),
          const Signal(MorseSignal.dot), // S
        ]);
      },
    );

    test('WATER pattern is W + A + T + E + R', () {
      expect(englishAlphabet.wordPatterns!['WATER'], [
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dash), // W
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash), // A
        const CharGap(),
        const Signal(MorseSignal.dash), // T
        const CharGap(),
        const Signal(MorseSignal.dot), // E
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot), // R
      ]);
    });
  });
}
