import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('morseRegistry levels', () {
    test('contains exactly 5 levels', () {
      expect(morseRegistry.all.expand((a) => a.levels).length, 5);
    });

    test('digits is at index 0 with null language', () {
      final allLevels = morseRegistry.levelsForLanguage(MorseLanguage.english);
      expect(allLevels[0].name, 'digits');
      expect(allLevels[0].language, isNull);
    });

    test('English letters is at index 1', () {
      final allLevels = morseRegistry.levelsForLanguage(MorseLanguage.english);
      expect(allLevels[1].name, 'letters');
      expect(allLevels[1].language, MorseLanguage.english);
    });

    test('English words is at index 2', () {
      final allLevels = morseRegistry.levelsForLanguage(MorseLanguage.english);
      expect(allLevels[2].name, 'words');
      expect(allLevels[2].language, MorseLanguage.english);
    });

    test('Arabic letters is at index 1 in Arabic levels', () {
      final arabicLevels = morseRegistry.levelsForLanguage(
        MorseLanguage.arabic,
      );
      expect(arabicLevels[1].name, 'arabic-letters');
      expect(arabicLevels[1].language, MorseLanguage.arabic);
    });

    test('Arabic words is at index 2 in Arabic levels', () {
      final arabicLevels = morseRegistry.levelsForLanguage(
        MorseLanguage.arabic,
      );
      expect(arabicLevels[2].name, 'arabic-words');
      expect(arabicLevels[2].language, MorseLanguage.arabic);
    });
  });

  group('levelsForLanguage', () {
    test('English returns 3 levels: digits, letters, words', () {
      final english = morseRegistry.levelsForLanguage(MorseLanguage.english);
      expect(english.length, 3);
      expect(english[0].name, 'digits');
      expect(english[1].name, 'letters');
      expect(english[2].name, 'words');
    });

    test('Arabic returns 3 levels: digits, arabic-letters, arabic-words', () {
      final arabic = morseRegistry.levelsForLanguage(MorseLanguage.arabic);
      expect(arabic.length, 3);
      expect(arabic[0].name, 'digits');
      expect(arabic[1].name, 'arabic-letters');
      expect(arabic[2].name, 'arabic-words');
    });

    test('both languages include the shared digits level', () {
      final english = morseRegistry.levelsForLanguage(MorseLanguage.english);
      final arabic = morseRegistry.levelsForLanguage(MorseLanguage.arabic);
      expect(english[0].name, arabic[0].name);
    });
  });

  group('digits level', () {
    late Level digitsLevel;

    setUp(() {
      digitsLevel = morseRegistry.levelsForLanguage(MorseLanguage.english)[0];
    });

    test('has 10 characters', () {
      expect(digitsLevel.characters.length, 10);
    });

    test('characters start with 0 and end with 9', () {
      expect(digitsLevel.characters.first, '0');
      expect(digitsLevel.characters.last, '9');
    });

    test('has patterns for all characters', () {
      for (final char in digitsLevel.characters) {
        expect(
          digitsLevel.patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for digit 3', () {
      expect(digitsLevel.patterns['3'], [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });
  });

  group('English letters level', () {
    late Level lettersLevel;

    setUp(() {
      lettersLevel = morseRegistry.levelsForLanguage(MorseLanguage.english)[1];
    });

    test('has 26 characters', () {
      expect(lettersLevel.characters.length, 26);
    });

    test('characters start with A and end with Z', () {
      expect(lettersLevel.characters.first, 'A');
      expect(lettersLevel.characters.last, 'Z');
    });

    test('has patterns for all characters', () {
      for (final char in lettersLevel.characters) {
        expect(
          lettersLevel.patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for A', () {
      expect(lettersLevel.patterns['A'], [MorseSignal.dot, MorseSignal.dash]);
    });
  });

  group('English words level', () {
    late Level wordsLevel;

    setUp(() {
      wordsLevel = morseRegistry.levelsForLanguage(MorseLanguage.english)[2];
    });

    test('is at index 2', () {
      expect(wordsLevel.name, 'words');
    });

    test('has 20 characters', () {
      expect(wordsLevel.characters.length, 20);
    });

    test('characters start with IT and end with THERE', () {
      expect(wordsLevel.characters.first, 'IT');
      expect(wordsLevel.characters.last, 'THERE');
    });

    test('word patterns exist for all characters via alphabet', () {
      for (final word in wordsLevel.characters) {
        expect(
          englishAlphabet.wordPatterns!.containsKey(word),
          isTrue,
          reason: 'Missing word pattern for $word',
        );
      }
    });

    test('level patterns cover all words', () {
      for (final word in wordsLevel.characters) {
        expect(
          wordsLevel.patterns.containsKey(word),
          isTrue,
          reason: 'Missing pattern for word $word',
        );
      }
    });

    test('all constituent letters exist in alphabet', () {
      for (final word in wordsLevel.characters) {
        for (final char in word.split('')) {
          expect(
            englishAlphabet.characters.containsKey(char),
            isTrue,
            reason: 'Missing letter pattern for $char in word $word',
          );
        }
      }
    });
  });

  group('Arabic letters level', () {
    late Level arabicLettersLevel;

    setUp(() {
      arabicLettersLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.arabic,
      )[1];
    });

    test('has 28 characters', () {
      expect(arabicLettersLevel.characters.length, 28);
    });

    test('characters start with ا and end with ي', () {
      expect(arabicLettersLevel.characters.first, 'ا');
      expect(arabicLettersLevel.characters.last, 'ي');
    });

    test('has patterns for all characters', () {
      for (final char in arabicLettersLevel.characters) {
        expect(
          arabicLettersLevel.patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for ا (Alif)', () {
      expect(arabicLettersLevel.patterns['ا'], [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });
  });

  group('Arabic words level', () {
    late Level arabicWordsLevel;

    setUp(() {
      arabicWordsLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.arabic,
      )[2];
    });

    test('has 20 characters', () {
      expect(arabicWordsLevel.characters.length, 20);
    });

    test('word patterns exist for all characters via alphabet', () {
      for (final word in arabicWordsLevel.characters) {
        expect(
          arabicAlphabet.wordPatterns!.containsKey(word),
          isTrue,
          reason: 'Missing word pattern for $word',
        );
      }
    });

    test('word patterns in alphabet cover variant characters', () {
      // Arabic words may contain variant forms (e.g. ى, أ) that are not
      // in the base 28-letter alphabet but are handled by the word builder
      // via aliases. Verify that wordPatterns exist for all words.
      for (final word in arabicWordsLevel.characters) {
        expect(
          arabicAlphabet.wordPatterns!.containsKey(word),
          isTrue,
          reason: 'Missing word pattern for $word',
        );
        expect(
          arabicAlphabet.wordPatterns![word],
          isNotEmpty,
          reason: 'Empty word pattern for $word',
        );
      }
    });
  });

  group('Level position resolution', () {
    test('position 0 in digits is character 0', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.english)[0];
      expect(level.characters[0], '0');
      expect(level.patterns[level.characters[0]], isNotNull);
    });

    test('position 5 in digits is character 5', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.english)[0];
      expect(level.characters[5], '5');
    });

    test('position 0 in English letters is character A', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.english)[1];
      expect(level.characters[0], 'A');
    });

    test('position 25 in English letters is character Z', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.english)[1];
      expect(level.characters[25], 'Z');
    });

    test('position 0 in Arabic letters is character ا', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.arabic)[1];
      expect(level.characters[0], 'ا');
    });
  });
}
