import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MorseAlphabet', () {
    test('universal alphabet has null language', () {
      final alphabet = MorseAlphabet(
        language: null,
        characters: const {
          '0': [MorseSignal.dash],
        },
        characterOrder: const ['0'],
        levels: const [],
      );
      expect(alphabet.language, isNull);
    });

    test('language-specific alphabet has language set', () {
      final alphabet = MorseAlphabet(
        language: MorseLanguage.english,
        characters: const {
          'A': [MorseSignal.dot, MorseSignal.dash],
        },
        characterOrder: const ['A'],
        levels: const [],
      );
      expect(alphabet.language, MorseLanguage.english);
    });

    test('characters map is accessible', () {
      final alphabet = MorseAlphabet(
        language: MorseLanguage.english,
        characters: const {
          'A': [MorseSignal.dot, MorseSignal.dash],
        },
        characterOrder: const ['A'],
        levels: const [],
      );
      expect(alphabet.characters['A'], [MorseSignal.dot, MorseSignal.dash]);
    });

    test('characterOrder defines learning sequence', () {
      final alphabet = MorseAlphabet(
        language: MorseLanguage.english,
        characters: const {
          'A': [MorseSignal.dot, MorseSignal.dash],
          'B': [
            MorseSignal.dash,
            MorseSignal.dot,
            MorseSignal.dot,
            MorseSignal.dot,
          ],
        },
        characterOrder: const ['A', 'B'],
        levels: const [],
      );
      expect(alphabet.characterOrder, ['A', 'B']);
    });

    test('alphabet with words has wordList and wordPatterns', () {
      final alphabet = MorseAlphabet(
        language: MorseLanguage.english,
        characters: const {
          'A': [MorseSignal.dot, MorseSignal.dash],
        },
        characterOrder: const ['A'],
        wordList: const ['AA'],
        wordPatterns: {
          'AA': [
            const Signal(MorseSignal.dot),
            const Signal(MorseSignal.dash),
            const CharGap(),
            const Signal(MorseSignal.dot),
            const Signal(MorseSignal.dash),
          ],
        },
        levels: const [],
      );
      expect(alphabet.wordList, hasLength(1));
      expect(alphabet.wordPatterns, hasLength(1));
    });

    test('alphabet without words has null wordList', () {
      final alphabet = MorseAlphabet(
        language: null,
        characters: const {
          '0': [MorseSignal.dash],
        },
        characterOrder: const ['0'],
        levels: const [],
      );
      expect(alphabet.wordList, isNull);
      expect(alphabet.wordPatterns, isNull);
    });

    test('levels field is accessible', () {
      final alphabet = MorseAlphabet(
        language: null,
        characters: const {
          '0': [MorseSignal.dash],
        },
        characterOrder: const ['0'],
        levels: [
          const Level(
            name: 'test',
            characters: ['0'],
            patterns: {
              '0': [MorseSignal.dash],
            },
          ),
        ],
      );
      expect(alphabet.levels, hasLength(1));
      expect(alphabet.levels.first.name, 'test');
    });
  });
}
