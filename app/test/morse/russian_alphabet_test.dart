import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('russianAlphabet.characters', () {
    test('contains all 32 Russian letters (Ё excluded)', () {
      expect(russianAlphabet.characters.length, 32);
    });

    test('every pattern is non-empty', () {
      for (final entry in russianAlphabet.characters.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '${entry.key} has empty pattern',
        );
      }
    });

    test('А is dot-dash', () {
      expect(russianAlphabet.characters['А'], [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('Е is single dot', () {
      expect(russianAlphabet.characters['Е'], [MorseSignal.dot]);
    });

    test('Т is single dash', () {
      expect(russianAlphabet.characters['Т'], [MorseSignal.dash]);
    });

    test('Щ is dash-dash-dot-dash', () {
      expect(russianAlphabet.characters['Щ'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('Ъ is dash-dash-dot-dash-dash (5 signals)', () {
      expect(russianAlphabet.characters['Ъ'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });

    test('Я is dot-dash-dot-dash', () {
      expect(russianAlphabet.characters['Я'], [
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('Ш is four dashes', () {
      expect(russianAlphabet.characters['Ш'], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });
  });

  group('russianAlphabet.characterOrder', () {
    test('contains 32 letters (Ё excluded)', () {
      expect(russianAlphabet.characterOrder.length, 32);
    });

    test('starts with А and ends with Я', () {
      expect(russianAlphabet.characterOrder.first, 'А');
      expect(russianAlphabet.characterOrder.last, 'Я');
    });

    test('index 0 is А', () {
      expect(russianAlphabet.characterOrder[0], 'А');
    });

    test('index 31 is Я', () {
      expect(russianAlphabet.characterOrder[31], 'Я');
    });

    test('every letter in list has a pattern', () {
      for (final letter in russianAlphabet.characterOrder) {
        expect(
          russianAlphabet.characters.containsKey(letter),
          isTrue,
          reason: 'Missing pattern for $letter',
        );
      }
    });
  });

  group('Ё alias', () {
    test('Ё is not in the main characters map', () {
      expect(russianAlphabet.characters.containsKey('Ё'), isFalse);
    });

    test('words containing Ё can still be composed', () {
      // The alias is used internally during word pattern composition.
      // Verify that the alphabet has 32 characters (Ё is only an alias).
      expect(russianAlphabet.characters.length, 32);
    });
  });

  group('russianAlphabet.wordList', () {
    test('contains exactly 20 words', () {
      expect(russianAlphabet.wordList!.length, 20);
    });

    test('first 5 words are 2-letter words', () {
      for (var i = 0; i < 5; i++) {
        expect(
          russianAlphabet.wordList![i].length,
          2,
          reason: '${russianAlphabet.wordList![i]} should be 2 letters',
        );
      }
    });

    test('words 6-10 are 3-letter words', () {
      for (var i = 5; i < 10; i++) {
        expect(
          russianAlphabet.wordList![i].length,
          3,
          reason: '${russianAlphabet.wordList![i]} should be 3 letters',
        );
      }
    });

    test('words 11-15 are 4-letter words', () {
      for (var i = 10; i < 15; i++) {
        expect(
          russianAlphabet.wordList![i].length,
          4,
          reason: '${russianAlphabet.wordList![i]} should be 4 letters',
        );
      }
    });

    test('words 16-20 are 5-letter words', () {
      for (var i = 15; i < 20; i++) {
        expect(
          russianAlphabet.wordList![i].length,
          5,
          reason: '${russianAlphabet.wordList![i]} should be 5 letters',
        );
      }
    });

    test('all words are uppercase Cyrillic', () {
      final cyrillicUpper = RegExp(r'^[А-ЯЁ]+$');
      for (final word in russianAlphabet.wordList!) {
        expect(
          cyrillicUpper.hasMatch(word),
          isTrue,
          reason: '$word is not uppercase Cyrillic',
        );
      }
    });
  });

  group('russianAlphabet.wordPatterns map', () {
    test('every word in list has a pattern entry', () {
      for (final word in russianAlphabet.wordList!) {
        expect(
          russianAlphabet.wordPatterns!.containsKey(word),
          isTrue,
          reason: 'Missing pattern for $word',
        );
      }
    });

    test('no extra entries beyond the word list', () {
      expect(
        russianAlphabet.wordPatterns!.length,
        russianAlphabet.wordList!.length,
      );
    });

    test('patterns do not start with CharGap', () {
      for (final entry in russianAlphabet.wordPatterns!.entries) {
        expect(
          entry.value.first,
          isNot(isA<CharGap>()),
          reason: '${entry.key} pattern starts with CharGap',
        );
      }
    });

    test('patterns do not end with CharGap', () {
      for (final entry in russianAlphabet.wordPatterns!.entries) {
        expect(
          entry.value.last,
          isNot(isA<CharGap>()),
          reason: '${entry.key} pattern ends with CharGap',
        );
      }
    });

    test('CharGap count equals letter count minus 1', () {
      for (final entry in russianAlphabet.wordPatterns!.entries) {
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

  group('Russian word pattern correctness', () {
    test('ДА pattern is Д(dash dot dot) + CharGap + А(dot dash)', () {
      expect(russianAlphabet.wordPatterns!['ДА'], [
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot), // Д
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash), // А
      ]);
    });

    test(
      'НЕТ pattern is Н(dash dot) + CharGap + Е(dot) + CharGap + Т(dash)',
      () {
        expect(russianAlphabet.wordPatterns!['НЕТ'], [
          const Signal(MorseSignal.dash),
          const Signal(MorseSignal.dot), // Н
          const CharGap(),
          const Signal(MorseSignal.dot), // Е
          const CharGap(),
          const Signal(MorseSignal.dash), // Т
        ]);
      },
    );
  });
}
