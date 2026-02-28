import 'package:feel_you/morse/levels.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('levels registry', () {
    test('contains exactly 3 levels', () {
      expect(levels.length, 3);
    });

    test('digits is at index 0', () {
      expect(levels[0].name, 'digits');
    });

    test('letters is at index 1', () {
      expect(levels[1].name, 'letters');
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

  group('letters level', () {
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

  group('words level', () {
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

    test('position 0 in letters is character A', () {
      final level = levels[1];
      expect(level.characters[0], 'A');
    });

    test('position 25 in letters is character Z', () {
      final level = levels[1];
      expect(level.characters[25], 'Z');
    });
  });
}
