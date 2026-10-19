import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// Every Spanish letter's pattern, as listed in the `spanish-morse-data`
/// spec, in Spanish alphabetical order.
const _expectedPatterns = <String, List<MorseSignal>>{
  'A': [_d, _s],
  'B': [_s, _d, _d, _d],
  'C': [_s, _d, _s, _d],
  'D': [_s, _d, _d],
  'E': [_d],
  'F': [_d, _d, _s, _d],
  'G': [_s, _s, _d],
  'H': [_d, _d, _d, _d],
  'I': [_d, _d],
  'J': [_d, _s, _s, _s],
  'K': [_s, _d, _s],
  'L': [_d, _s, _d, _d],
  'M': [_s, _s],
  'N': [_s, _d],
  'Ñ': [_s, _s, _d, _s, _s],
  'O': [_s, _s, _s],
  'P': [_d, _s, _s, _d],
  'Q': [_s, _s, _d, _s],
  'R': [_d, _s, _d],
  'S': [_d, _d, _d],
  'T': [_s],
  'U': [_d, _d, _s],
  'V': [_d, _d, _d, _s],
  'W': [_d, _s, _s],
  'X': [_s, _d, _d, _s],
  'Y': [_s, _d, _s, _s],
  'Z': [_s, _s, _d, _d],
};

const _expectedWords = [
  'NO', 'YA', 'YO', 'VE', 'AY', //
  'VEN', 'SED', 'MAL', 'PAN', 'VOY', //
  'HOLA', 'AGUA', 'BAÑO', 'BIEN', 'ALTO', //
  'AYUDA', 'DOLOR', 'CALOR', 'SUEÑO', 'FELIZ', //
];

void main() {
  group('spanishAlphabet.characters', () {
    test('belongs to Spanish', () {
      expect(spanishAlphabet.language, MorseLanguage.spanish);
    });

    test('contains the 27 Spanish letters: A-Z and Ñ', () {
      expect(spanishAlphabet.characters.length, 27);
      expect(
        spanishAlphabet.characters.keys.toSet(),
        _expectedPatterns.keys.toSet(),
      );
    });

    test('every letter has its standard pattern', () {
      for (final MapEntry(key: letter, value: pattern)
          in _expectedPatterns.entries) {
        expect(spanishAlphabet.characters[letter], pattern, reason: letter);
      }
    });

    test('A-Z are the English patterns', () {
      for (final MapEntry(key: letter, value: pattern)
          in englishAlphabet.characters.entries) {
        expect(spanishAlphabet.characters[letter], pattern, reason: letter);
      }
    });

    test('Ñ is dash-dash-dot-dash-dash', () {
      expect(spanishAlphabet.characters['Ñ'], [_s, _s, _d, _s, _s]);
    });

    test('no two letters or digits share a pattern', () {
      final all = {...spanishAlphabet.characters, ...digitAlphabet.characters};
      final keys = all.values.map((p) => p.join(',')).toSet();
      expect(keys, hasLength(27 + 10));
    });

    test('cannot be modified', () {
      expect(
        () => spanishAlphabet.characters['Ñ'] = const [_d],
        throwsUnsupportedError,
      );
    });
  });

  group('spanishAlphabet.characterOrder', () {
    test('is the Spanish alphabet, with Ñ between N and O', () {
      expect(spanishAlphabet.characterOrder, _expectedPatterns.keys.toList());
    });

    test('contains 27 letters', () {
      expect(spanishAlphabet.characterOrder.length, 27);
    });

    test('Ñ is the fifteenth letter', () {
      expect(spanishAlphabet.characterOrder.sublist(13, 16), ['N', 'Ñ', 'O']);
    });

    test('starts with A and ends with Z', () {
      expect(spanishAlphabet.characterOrder.first, 'A');
      expect(spanishAlphabet.characterOrder.last, 'Z');
    });

    test('every letter in the order has a pattern', () {
      for (final letter in spanishAlphabet.characterOrder) {
        expect(spanishAlphabet.characters[letter], isNotNull, reason: letter);
      }
    });

    test('every letter is a single code unit', () {
      // Word patterns are composed per code unit, so Ñ must be the
      // precomposed U+00D1, not N followed by a combining tilde.
      for (final letter in spanishAlphabet.characterOrder) {
        expect(letter.length, 1, reason: letter);
      }
      expect(spanishAlphabet.characterOrder[14].codeUnitAt(0), 0x00D1);
    });
  });

  group('spanishAlphabet.wordList', () {
    test('is the word list of the spec', () {
      expect(spanishAlphabet.wordList, _expectedWords);
    });

    test('contains exactly 20 words', () {
      expect(spanishAlphabet.wordList!.length, 20);
    });

    test('is grouped by length: five each of 2, 3, 4 and 5 letters', () {
      final words = spanishAlphabet.wordList!;
      for (var i = 0; i < words.length; i++) {
        expect(words[i].length, 2 + i ~/ 5, reason: words[i]);
      }
    });

    test('has no duplicates', () {
      expect(spanishAlphabet.wordList!.toSet(), hasLength(20));
    });

    test('words only use letters of the Spanish letters level', () {
      final letters = spanishAlphabet.characterOrder.toSet();
      for (final word in spanishAlphabet.wordList!) {
        for (final letter in word.split('')) {
          expect(letters, contains(letter), reason: '$letter in $word');
        }
      }
    });

    test('words are uppercase', () {
      for (final word in spanishAlphabet.wordList!) {
        expect(word, word.toUpperCase(), reason: word);
      }
    });

    test('Ñ is used in words', () {
      expect(spanishAlphabet.wordList, containsAll(['BAÑO', 'SUEÑO']));
    });
  });

  group('spanishAlphabet.wordPatterns', () {
    test('every word in the list has a pattern entry', () {
      for (final word in spanishAlphabet.wordList!) {
        expect(spanishAlphabet.wordPatterns![word], isNotNull, reason: word);
      }
    });

    test('no extra entries beyond the word list', () {
      expect(spanishAlphabet.wordPatterns!.length, 20);
    });

    test('patterns do not start or end with CharGap', () {
      for (final MapEntry(key: word, value: pattern)
          in spanishAlphabet.wordPatterns!.entries) {
        expect(pattern.first, isNot(isA<CharGap>()), reason: word);
        expect(pattern.last, isNot(isA<CharGap>()), reason: word);
      }
    });

    test('CharGap count equals letter count minus 1', () {
      for (final MapEntry(key: word, value: pattern)
          in spanishAlphabet.wordPatterns!.entries) {
        expect(
          pattern.whereType<CharGap>().length,
          word.length - 1,
          reason: word,
        );
      }
    });

    test('NO is N + CharGap + O', () {
      expect(spanishAlphabet.wordPatterns!['NO'], const [
        Signal(_s),
        Signal(_d), // N
        CharGap(),
        Signal(_s),
        Signal(_s),
        Signal(_s), // O
      ]);
    });

    test('BAÑO is B + A + Ñ + O, separated by CharGap', () {
      expect(spanishAlphabet.wordPatterns!['BAÑO'], const [
        Signal(_s),
        Signal(_d),
        Signal(_d),
        Signal(_d), // B
        CharGap(),
        Signal(_d),
        Signal(_s), // A
        CharGap(),
        Signal(_s),
        Signal(_s),
        Signal(_d),
        Signal(_s),
        Signal(_s), // Ñ
        CharGap(),
        Signal(_s),
        Signal(_s),
        Signal(_s), // O
      ]);
    });
  });

  group('Spanish levels', () {
    test('are spanish-letters and spanish-words', () {
      expect(spanishAlphabet.levels.map((l) => l.name), [
        'spanish-letters',
        'spanish-words',
      ]);
    });

    test('the letters level teaches the 27 letters in order', () {
      final letters = spanishAlphabet.levels[0];
      expect(letters.kind, LevelKind.characters);
      expect(letters.language, MorseLanguage.spanish);
      expect(letters.characters, spanishAlphabet.characterOrder);
      expect(letters.patterns, spanishAlphabet.characters);
    });

    test('the words level teaches the 20 words with their patterns', () {
      final words = spanishAlphabet.levels[1];
      expect(words.kind, LevelKind.words);
      expect(words.language, MorseLanguage.spanish);
      expect(words.characters, spanishAlphabet.wordList);
      expect(words.wordPatterns, spanishAlphabet.wordPatterns);
      expect(words.patterns['BAÑO'], [
        ..._expectedPatterns['B']!,
        ..._expectedPatterns['A']!,
        ..._expectedPatterns['Ñ']!,
        ..._expectedPatterns['O']!,
      ]);
    });
  });
}
