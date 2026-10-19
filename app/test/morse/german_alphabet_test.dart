import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// The umlauts' patterns, as listed in the `german-morse-data` spec, in
/// learning order.
const _extra = <String, List<MorseSignal>>{
  'Ä': [_d, _s, _d, _s],
  'Ö': [_s, _s, _s, _d],
  'Ü': [_d, _d, _s, _s],
};

const _expectedWords = [
  'JA', 'AU', 'DA', 'WO', 'DU', //
  'GUT', 'WEH', 'KLO', 'GEH', 'AUF', //
  'NEIN', 'HALT', 'KALT', 'WARM', 'MÜDE', //
  'HILFE', 'DANKE', 'BITTE', 'HALLO', 'ESSEN', //
];

void main() {
  group('germanAlphabet.characters', () {
    test('belongs to German', () {
      expect(germanAlphabet.language, MorseLanguage.german);
    });

    test('contains the 29 German letters: A-Z, Ä, Ö and Ü', () {
      expect(germanAlphabet.characters.length, 29);
      expect(germanAlphabet.characters.keys.toSet(), {
        ...englishAlphabet.characters.keys,
        ..._extra.keys,
      });
    });

    test('A-Z are the English patterns', () {
      for (final MapEntry(key: letter, value: pattern)
          in englishAlphabet.characters.entries) {
        expect(germanAlphabet.characters[letter], pattern, reason: letter);
      }
    });

    test('the umlauts have their standard patterns', () {
      for (final MapEntry(key: letter, value: pattern) in _extra.entries) {
        expect(germanAlphabet.characters[letter], pattern, reason: letter);
      }
    });

    test('Ö is dash-dash-dash-dot', () {
      expect(germanAlphabet.characters['Ö'], [_s, _s, _s, _d]);
    });

    test('ß is not taught', () {
      expect(germanAlphabet.characters.containsKey('ß'), isFalse);
      expect(germanAlphabet.characters.containsKey('ẞ'), isFalse);
    });

    test('no two letters or digits share a pattern', () {
      final all = {...germanAlphabet.characters, ...digitAlphabet.characters};
      final keys = all.values.map((p) => p.join(',')).toSet();
      expect(keys, hasLength(29 + 10));
    });

    test('cannot be modified', () {
      expect(
        () => germanAlphabet.characters['Ü'] = const [_d],
        throwsUnsupportedError,
      );
    });
  });

  group('germanAlphabet.characterOrder', () {
    test('is A-Z, then Ä, Ö, Ü', () {
      expect(germanAlphabet.characterOrder, [
        ...englishAlphabet.characterOrder,
        'Ä',
        'Ö',
        'Ü',
      ]);
    });

    test('contains 29 letters', () {
      expect(germanAlphabet.characterOrder.length, 29);
    });

    test('A-Z keep their places', () {
      expect(germanAlphabet.characterOrder[0], 'A');
      expect(germanAlphabet.characterOrder[25], 'Z');
    });

    test('the umlauts follow Z', () {
      expect(germanAlphabet.characterOrder.sublist(26), ['Ä', 'Ö', 'Ü']);
    });

    test('every letter in the order has a pattern', () {
      for (final letter in germanAlphabet.characterOrder) {
        expect(germanAlphabet.characters[letter], isNotNull, reason: letter);
      }
    });

    test('every letter is a single precomposed code unit', () {
      for (final letter in germanAlphabet.characterOrder) {
        expect(letter.length, 1, reason: letter);
      }
      expect(
        germanAlphabet.characterOrder.sublist(26).map((l) => l.codeUnitAt(0)),
        [0x00C4, 0x00D6, 0x00DC],
      );
    });
  });

  group('germanAlphabet.wordList', () {
    test('is the word list of the spec', () {
      expect(germanAlphabet.wordList, _expectedWords);
    });

    test('contains exactly 20 words', () {
      expect(germanAlphabet.wordList!.length, 20);
    });

    test('is grouped by length: five each of 2, 3, 4 and 5 letters', () {
      final words = germanAlphabet.wordList!;
      for (var i = 0; i < words.length; i++) {
        expect(words[i].length, 2 + i ~/ 5, reason: words[i]);
      }
    });

    test('has no duplicates', () {
      expect(germanAlphabet.wordList!.toSet(), hasLength(20));
    });

    test('words only use letters of the German letters level', () {
      final letters = germanAlphabet.characterOrder.toSet();
      for (final word in germanAlphabet.wordList!) {
        for (final letter in word.split('')) {
          expect(letters, contains(letter), reason: '$letter in $word');
        }
      }
    });

    test('words are uppercase', () {
      for (final word in germanAlphabet.wordList!) {
        expect(word, word.toUpperCase(), reason: word);
      }
    });
  });

  group('germanAlphabet.wordPatterns', () {
    test('every word in the list has a pattern entry', () {
      for (final word in germanAlphabet.wordList!) {
        expect(germanAlphabet.wordPatterns![word], isNotNull, reason: word);
      }
    });

    test('no extra entries beyond the word list', () {
      expect(germanAlphabet.wordPatterns!.length, 20);
    });

    test('patterns do not start or end with CharGap', () {
      for (final MapEntry(key: word, value: pattern)
          in germanAlphabet.wordPatterns!.entries) {
        expect(pattern.first, isNot(isA<CharGap>()), reason: word);
        expect(pattern.last, isNot(isA<CharGap>()), reason: word);
      }
    });

    test('CharGap count equals letter count minus 1', () {
      for (final MapEntry(key: word, value: pattern)
          in germanAlphabet.wordPatterns!.entries) {
        expect(
          pattern.whereType<CharGap>().length,
          word.length - 1,
          reason: word,
        );
      }
    });

    test('JA is J + CharGap + A', () {
      expect(germanAlphabet.wordPatterns!['JA'], const [
        Signal(_d),
        Signal(_s),
        Signal(_s),
        Signal(_s), // J
        CharGap(),
        Signal(_d),
        Signal(_s), // A
      ]);
    });

    test('MÜDE is M + Ü + D + E, separated by CharGap', () {
      expect(germanAlphabet.wordPatterns!['MÜDE'], const [
        Signal(_s),
        Signal(_s), // M
        CharGap(),
        Signal(_d),
        Signal(_d),
        Signal(_s),
        Signal(_s), // Ü
        CharGap(),
        Signal(_s),
        Signal(_d),
        Signal(_d), // D
        CharGap(),
        Signal(_d), // E
      ]);
    });
  });

  group('German levels', () {
    test('are german-letters and german-words', () {
      expect(germanAlphabet.levels.map((l) => l.name), [
        'german-letters',
        'german-words',
      ]);
    });

    test('the letters level teaches the 29 letters in order', () {
      final letters = germanAlphabet.levels[0];
      expect(letters.kind, LevelKind.characters);
      expect(letters.language, MorseLanguage.german);
      expect(letters.characters, germanAlphabet.characterOrder);
      expect(letters.patterns, germanAlphabet.characters);
    });

    test('the words level teaches the 20 words with their patterns', () {
      final words = germanAlphabet.levels[1];
      expect(words.kind, LevelKind.words);
      expect(words.language, MorseLanguage.german);
      expect(words.characters, germanAlphabet.wordList);
      expect(words.wordPatterns, germanAlphabet.wordPatterns);
    });
  });
}
