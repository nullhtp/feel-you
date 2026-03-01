import 'package:feel_you/morse/levels.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('levels registry', () {
    test('contains exactly 5 levels', () {
      expect(levels.length, 5);
    });

    test('digits is at index 0 with null language', () {
      expect(levels[0].name, 'digits');
      expect(levels[0].language, isNull);
    });

    test('English letters is at index 1', () {
      expect(levels[1].name, 'letters');
      expect(levels[1].language, MorseLanguage.english);
    });

    test('English words is at index 2', () {
      expect(levels[2].name, 'words');
      expect(levels[2].language, MorseLanguage.english);
    });

    test('Arabic letters is at index 3', () {
      expect(levels[3].name, 'arabic-letters');
      expect(levels[3].language, MorseLanguage.arabic);
    });

    test('Arabic words is at index 4', () {
      expect(levels[4].name, 'arabic-words');
      expect(levels[4].language, MorseLanguage.arabic);
    });
  });

  group('levelsForLanguage', () {
    test('English returns 3 levels: digits, letters, words', () {
      final english = levelsForLanguage(MorseLanguage.english);
      expect(english.length, 3);
      expect(english[0].name, 'digits');
      expect(english[1].name, 'letters');
      expect(english[2].name, 'words');
    });

    test('Arabic returns 3 levels: digits, arabic-letters, arabic-words', () {
      final arabic = levelsForLanguage(MorseLanguage.arabic);
      expect(arabic.length, 3);
      expect(arabic[0].name, 'digits');
      expect(arabic[1].name, 'arabic-letters');
      expect(arabic[2].name, 'arabic-words');
    });

    test('both languages include the shared digits level', () {
      final english = levelsForLanguage(MorseLanguage.english);
      final arabic = levelsForLanguage(MorseLanguage.arabic);
      expect(english[0], arabic[0]);
    });
  });

  group('digits level', () {
    test('has 10 characters', () {
      expect(levels[0].characters.length, 10);
    });

    test('characters start with 0 and end with 9', () {
      expect(levels[0].characters.first, '0');
      expect(levels[0].characters.last, '9');
    });

    test('has patterns for all characters', () {
      for (final char in levels[0].characters) {
        expect(
          levels[0].patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for digit 3', () {
      expect(levels[0].patterns['3'], [
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dash,
        MorseSymbol.dash,
      ]);
    });
  });

  group('English letters level', () {
    test('has 26 characters', () {
      expect(levels[1].characters.length, 26);
    });

    test('characters start with A and end with Z', () {
      expect(levels[1].characters.first, 'A');
      expect(levels[1].characters.last, 'Z');
    });

    test('has patterns for all characters', () {
      for (final char in levels[1].characters) {
        expect(
          levels[1].patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for A', () {
      expect(levels[1].patterns['A'], [MorseSymbol.dot, MorseSymbol.dash]);
    });
  });

  group('English words level', () {
    test('is at index 2', () {
      expect(levels[2].name, 'words');
    });

    test('has 20 characters', () {
      expect(levels[2].characters.length, 20);
    });

    test('characters start with IT and end with THERE', () {
      expect(levels[2].characters.first, 'IT');
      expect(levels[2].characters.last, 'THERE');
    });

    test('has patterns for all characters', () {
      for (final char in levels[2].characters) {
        expect(
          levels[2].patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for THE', () {
      expect(levels[2].patterns['THE'], [
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
  });

  group('Arabic letters level', () {
    test('has 28 characters', () {
      expect(levels[3].characters.length, 28);
    });

    test('characters start with ا and end with ي', () {
      expect(levels[3].characters.first, 'ا');
      expect(levels[3].characters.last, 'ي');
    });

    test('has patterns for all characters', () {
      for (final char in levels[3].characters) {
        expect(
          levels[3].patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });

    test('pattern lookup for ا (Alif)', () {
      expect(levels[3].patterns['ا'], [MorseSymbol.dot, MorseSymbol.dash]);
    });
  });

  group('Arabic words level', () {
    test('has 20 characters', () {
      expect(levels[4].characters.length, 20);
    });

    test('has patterns for all characters', () {
      for (final char in levels[4].characters) {
        expect(
          levels[4].patterns.containsKey(char),
          isTrue,
          reason: 'Missing pattern for $char',
        );
      }
    });
  });

  group('Level position resolution', () {
    test('position 0 in digits is character 0', () {
      final level = levels[0];
      expect(level.characters[0], '0');
      expect(level.patterns[level.characters[0]], isNotNull);
    });

    test('position 5 in digits is character 5', () {
      final level = levels[0];
      expect(level.characters[5], '5');
    });

    test('position 0 in English letters is character A', () {
      final level = levels[1];
      expect(level.characters[0], 'A');
    });

    test('position 25 in English letters is character Z', () {
      final level = levels[1];
      expect(level.characters[25], 'Z');
    });

    test('position 0 in Arabic letters is character ا', () {
      final level = levels[3];
      expect(level.characters[0], 'ا');
    });
  });
}
