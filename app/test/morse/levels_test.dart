import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('morseRegistry levels', () {
    test('contains the digits level plus two levels per language', () {
      expect(
        morseRegistry.all.expand((a) => a.levels).length,
        1 + 2 * MorseLanguage.values.length,
      );
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

    test(
      'Russian returns 3 levels: digits, russian-letters, russian-words',
      () {
        final russian = morseRegistry.levelsForLanguage(MorseLanguage.russian);
        expect(russian.length, 3);
        expect(russian[0].name, 'digits');
        expect(russian[1].name, 'russian-letters');
        expect(russian[2].name, 'russian-words');
      },
    );

    test(
      'Spanish returns 3 levels: digits, spanish-letters, spanish-words',
      () {
        final spanish = morseRegistry.levelsForLanguage(MorseLanguage.spanish);
        expect(spanish.length, 3);
        expect(spanish[0].name, 'digits');
        expect(spanish[1].name, 'spanish-letters');
        expect(spanish[2].name, 'spanish-words');
      },
    );

    test('French returns 3 levels: digits, french-letters, french-words', () {
      final french = morseRegistry.levelsForLanguage(MorseLanguage.french);
      expect(french.length, 3);
      expect(french[0].name, 'digits');
      expect(french[1].name, 'french-letters');
      expect(french[2].name, 'french-words');
    });

    test('German returns 3 levels: digits, german-letters, german-words', () {
      final german = morseRegistry.levelsForLanguage(MorseLanguage.german);
      expect(german.length, 3);
      expect(german[0].name, 'digits');
      expect(german[1].name, 'german-letters');
      expect(german[2].name, 'german-words');
    });

    test('Russian levels list is unmodifiable', () {
      final russian = morseRegistry.levelsForLanguage(MorseLanguage.russian);
      expect(() => russian.add(russian[0]), throwsUnsupportedError);
    });

    test('all languages include the shared digits level', () {
      final english = morseRegistry.levelsForLanguage(MorseLanguage.english);
      final arabic = morseRegistry.levelsForLanguage(MorseLanguage.arabic);
      final russian = morseRegistry.levelsForLanguage(MorseLanguage.russian);
      expect(english[0].name, arabic[0].name);
      expect(english[0].name, russian[0].name);
      for (final language in MorseLanguage.values) {
        expect(
          morseRegistry.levelsForLanguage(language)[0],
          same(english[0]),
          reason: '$language',
        );
      }
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

    test('characters start with HI and end with THANK', () {
      expect(wordsLevel.characters.first, 'HI');
      expect(wordsLevel.characters.last, 'THANK');
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

  group('Russian letters level', () {
    late Level russianLettersLevel;

    setUp(() {
      russianLettersLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.russian,
      )[1];
    });

    test('has 32 characters (Ё excluded)', () {
      expect(russianLettersLevel.characters.length, 32);
    });

    test('characters start with А and end with Я', () {
      expect(russianLettersLevel.characters.first, 'А');
      expect(russianLettersLevel.characters.last, 'Я');
    });

    test('has patterns for all characters', () {
      for (final char in russianLettersLevel.characters) {
        expect(
          russianLettersLevel.patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for А', () {
      expect(russianLettersLevel.patterns['А'], [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });
  });

  group('Russian words level', () {
    late Level russianWordsLevel;

    setUp(() {
      russianWordsLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.russian,
      )[2];
    });

    test('has 20 characters', () {
      expect(russianWordsLevel.characters.length, 20);
    });

    test('word patterns exist for all characters via alphabet', () {
      for (final word in russianWordsLevel.characters) {
        expect(
          russianAlphabet.wordPatterns!.containsKey(word),
          isTrue,
          reason: 'Missing word pattern for $word',
        );
      }
    });

    test('word patterns in alphabet are non-empty', () {
      for (final word in russianWordsLevel.characters) {
        expect(
          russianAlphabet.wordPatterns![word],
          isNotEmpty,
          reason: 'Empty word pattern for $word',
        );
      }
    });
  });

  group('Spanish letters level', () {
    late Level spanishLettersLevel;

    setUp(() {
      spanishLettersLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.spanish,
      )[1];
    });

    test('has 27 characters (A-Z and Ñ)', () {
      expect(spanishLettersLevel.characters.length, 27);
      expect(spanishLettersLevel.patterns.length, 27);
    });

    test('characters start with A and end with Z', () {
      expect(spanishLettersLevel.characters.first, 'A');
      expect(spanishLettersLevel.characters.last, 'Z');
    });

    test('has patterns for all characters', () {
      for (final char in spanishLettersLevel.characters) {
        expect(
          spanishLettersLevel.patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });
  });

  group('Spanish words level', () {
    late Level spanishWordsLevel;

    setUp(() {
      spanishWordsLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.spanish,
      )[2];
    });

    test('has 20 characters', () {
      expect(spanishWordsLevel.characters.length, 20);
    });

    test('word patterns exist and are non-empty for all words', () {
      for (final word in spanishWordsLevel.characters) {
        expect(
          spanishWordsLevel.wordPatterns![word],
          isNotEmpty,
          reason: 'Missing word pattern for $word',
        );
      }
    });
  });

  group('French letters level', () {
    late Level frenchLettersLevel;

    setUp(() {
      frenchLettersLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.french,
      )[1];
    });

    test('has 30 characters (A-Z, À, Ç, É, È)', () {
      expect(frenchLettersLevel.characters.length, 30);
      expect(frenchLettersLevel.patterns.length, 30);
    });

    test('characters start with A and end with È', () {
      expect(frenchLettersLevel.characters.first, 'A');
      expect(frenchLettersLevel.characters.last, 'È');
    });
  });

  group('French words level', () {
    test('has 20 characters with word patterns', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.french)[2];
      expect(level.characters.length, 20);
      for (final word in level.characters) {
        expect(level.wordPatterns![word], isNotEmpty, reason: word);
      }
    });
  });

  group('German letters level', () {
    late Level germanLettersLevel;

    setUp(() {
      germanLettersLevel = morseRegistry.levelsForLanguage(
        MorseLanguage.german,
      )[1];
    });

    test('has 29 characters (A-Z, Ä, Ö, Ü)', () {
      expect(germanLettersLevel.characters.length, 29);
      expect(germanLettersLevel.patterns.length, 29);
    });

    test('characters start with A and end with Ü', () {
      expect(germanLettersLevel.characters.first, 'A');
      expect(germanLettersLevel.characters.last, 'Ü');
    });
  });

  group('German words level', () {
    test('has 20 characters with word patterns', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.german)[2];
      expect(level.characters.length, 20);
      for (final word in level.characters) {
        expect(level.wordPatterns![word], isNotEmpty, reason: word);
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

    test('position 0 in Russian letters is character А', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.russian)[1];
      expect(level.characters[0], 'А');
      expect(level.patterns[level.characters[0]], [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('position 28 in French letters is character É', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.french)[1];
      expect(level.characters[28], 'É');
      expect(level.patterns[level.characters[28]], [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('position 27 in German letters is character Ö', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.german)[1];
      expect(level.characters[27], 'Ö');
      expect(level.patterns[level.characters[27]], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
      ]);
    });

    test('position 14 in Spanish letters is character Ñ', () {
      final level = morseRegistry.levelsForLanguage(MorseLanguage.spanish)[1];
      expect(level.characters[14], 'Ñ');
      expect(level.patterns[level.characters[14]], [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dash,
      ]);
    });
  });

  group('level kind', () {
    const wordLevelNames = {
      'words',
      'arabic-words',
      'russian-words',
      'spanish-words',
      'french-words',
      'german-words',
    };
    final allLevels = morseRegistry.all.expand((a) => a.levels).toList();

    test('word levels have kind words, all others characters', () {
      for (final level in allLevels) {
        expect(
          level.kind,
          wordLevelNames.contains(level.name)
              ? LevelKind.words
              : LevelKind.characters,
          reason: 'Unexpected kind for ${level.name}',
        );
      }
    });

    test('each language has exactly one words level', () {
      for (final language in MorseLanguage.values) {
        final levels = morseRegistry.levelsForLanguage(language);
        expect(
          levels.where((l) => l.kind == LevelKind.words),
          hasLength(1),
          reason: 'Expected one words level for $language',
        );
      }
    });

    test('no two items of a characters level share a pattern', () {
      for (final level in allLevels) {
        if (level.kind != LevelKind.characters) continue;
        final patterns = {
          for (final item in level.characters) level.patterns[item]!.join(','),
        };
        expect(
          patterns,
          hasLength(level.characters.length),
          reason: level.name,
        );
      }
    });

    test('character levels have no word patterns', () {
      for (final level in allLevels) {
        if (level.kind == LevelKind.characters) {
          expect(level.wordPatterns, isNull, reason: level.name);
        }
      }
    });

    test('words levels carry their alphabet word patterns for every word', () {
      for (final alphabet in morseRegistry.all) {
        for (final level in alphabet.levels) {
          if (level.kind != LevelKind.words) continue;
          expect(level.wordPatterns, alphabet.wordPatterns, reason: level.name);
          for (final word in level.characters) {
            expect(
              level.wordPatterns![word],
              isNotEmpty,
              reason: 'Missing word pattern for $word in ${level.name}',
            );
          }
        }
      }
    });

    test('defaults to characters', () {
      const level = Level(name: 'test', characters: [], patterns: {});
      expect(level.kind, LevelKind.characters);
      expect(level.wordPatterns, isNull);
    });

    test('levels differing only by kind are not equal', () {
      const characters = Level(
        name: 'test',
        characters: [],
        patterns: {},
        wordPatterns: {},
      );
      const words = Level(
        name: 'test',
        characters: [],
        patterns: {},
        kind: LevelKind.words,
        wordPatterns: {},
      );
      expect(characters, isNot(words));
    });

    test('a words level without word patterns fails the assertion', () {
      Level wordsLevel(Map<String, List<MorseToken>>? wordPatterns) => Level(
        name: 'test',
        characters: const [],
        patterns: const {},
        kind: LevelKind.words,
        wordPatterns: wordPatterns,
      );

      expect(() => wordsLevel(null), throwsA(isA<AssertionError>()));
      expect(wordsLevel(const {}).kind, LevelKind.words);
    });
  });
}
