import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// The accented letters' patterns, as listed in the `french-morse-data`
/// spec, in learning order.
const _accented = <String, List<MorseSignal>>{
  'À': [_d, _s, _s, _d, _s],
  'Ç': [_s, _d, _s, _d, _d],
  'É': [_d, _d, _s, _d, _d],
  'È': [_d, _s, _d, _d, _s],
};

const _expectedWords = [
  'ÇA', 'VA', 'LÀ', 'OK', 'HÉ', //
  'OUI', 'NON', 'EAU', 'MAL', 'BON', //
  'AIDE', 'FAIM', 'SOIF', 'BIEN', 'STOP', //
  'MERCI', 'FROID', 'CHAUD', 'SALUT', 'APRÈS', //
];

void main() {
  group('frenchAlphabet.characters', () {
    test('belongs to French', () {
      expect(frenchAlphabet.language, MorseLanguage.french);
    });

    test('contains the 30 French letters: A-Z, À, Ç, É and È', () {
      expect(frenchAlphabet.characters.length, 30);
      expect(frenchAlphabet.characters.keys.toSet(), {
        ...englishAlphabet.characters.keys,
        ..._accented.keys,
      });
    });

    test('A-Z are the English patterns', () {
      for (final MapEntry(key: letter, value: pattern)
          in englishAlphabet.characters.entries) {
        expect(frenchAlphabet.characters[letter], pattern, reason: letter);
      }
    });

    test('the accented letters have their standard patterns', () {
      for (final MapEntry(key: letter, value: pattern) in _accented.entries) {
        expect(frenchAlphabet.characters[letter], pattern, reason: letter);
      }
    });

    test('É is dot-dot-dash-dot-dot', () {
      expect(frenchAlphabet.characters['É'], [_d, _d, _s, _d, _d]);
    });

    test('no two letters or digits share a pattern', () {
      final all = {...frenchAlphabet.characters, ...digitAlphabet.characters};
      final keys = all.values.map((p) => p.join(',')).toSet();
      expect(keys, hasLength(30 + 10));
    });

    test('cannot be modified', () {
      expect(
        () => frenchAlphabet.characters['É'] = const [_d],
        throwsUnsupportedError,
      );
    });
  });

  group('frenchAlphabet.characterOrder', () {
    test('is A-Z, then À, Ç, É, È', () {
      expect(frenchAlphabet.characterOrder, [
        ...englishAlphabet.characterOrder,
        'À',
        'Ç',
        'É',
        'È',
      ]);
    });

    test('contains 30 letters', () {
      expect(frenchAlphabet.characterOrder.length, 30);
    });

    test('A-Z keep their places', () {
      expect(frenchAlphabet.characterOrder[0], 'A');
      expect(frenchAlphabet.characterOrder[25], 'Z');
    });

    test('the accented letters follow Z', () {
      expect(frenchAlphabet.characterOrder.sublist(26), ['À', 'Ç', 'É', 'È']);
    });

    test('every letter in the order has a pattern', () {
      for (final letter in frenchAlphabet.characterOrder) {
        expect(frenchAlphabet.characters[letter], isNotNull, reason: letter);
      }
    });

    test('every letter is a single precomposed code unit', () {
      for (final letter in frenchAlphabet.characterOrder) {
        expect(letter.length, 1, reason: letter);
      }
      expect(
        frenchAlphabet.characterOrder.sublist(26).map((l) => l.codeUnitAt(0)),
        [0x00C0, 0x00C7, 0x00C9, 0x00C8],
      );
    });
  });

  group('frenchAlphabet.wordList', () {
    test('is the word list of the spec', () {
      expect(frenchAlphabet.wordList, _expectedWords);
    });

    test('contains exactly 20 words', () {
      expect(frenchAlphabet.wordList!.length, 20);
    });

    test('is grouped by length: five each of 2, 3, 4 and 5 letters', () {
      final words = frenchAlphabet.wordList!;
      for (var i = 0; i < words.length; i++) {
        expect(words[i].length, 2 + i ~/ 5, reason: words[i]);
      }
    });

    test('has no duplicates', () {
      expect(frenchAlphabet.wordList!.toSet(), hasLength(20));
    });

    test('words only use letters of the French letters level', () {
      final letters = frenchAlphabet.characterOrder.toSet();
      for (final word in frenchAlphabet.wordList!) {
        for (final letter in word.split('')) {
          expect(letters, contains(letter), reason: '$letter in $word');
        }
      }
    });

    test('words are uppercase', () {
      for (final word in frenchAlphabet.wordList!) {
        expect(word, word.toUpperCase(), reason: word);
      }
    });

    test('every accented letter is used in a word', () {
      final used = frenchAlphabet.wordList!.expand((w) => w.split('')).toSet();
      expect(used, containsAll(_accented.keys));
    });
  });

  group('frenchAlphabet.wordPatterns', () {
    test('every word in the list has a pattern entry', () {
      for (final word in frenchAlphabet.wordList!) {
        expect(frenchAlphabet.wordPatterns![word], isNotNull, reason: word);
      }
    });

    test('no extra entries beyond the word list', () {
      expect(frenchAlphabet.wordPatterns!.length, 20);
    });

    test('patterns do not start or end with CharGap', () {
      for (final MapEntry(key: word, value: pattern)
          in frenchAlphabet.wordPatterns!.entries) {
        expect(pattern.first, isNot(isA<CharGap>()), reason: word);
        expect(pattern.last, isNot(isA<CharGap>()), reason: word);
      }
    });

    test('CharGap count equals letter count minus 1', () {
      for (final MapEntry(key: word, value: pattern)
          in frenchAlphabet.wordPatterns!.entries) {
        expect(
          pattern.whereType<CharGap>().length,
          word.length - 1,
          reason: word,
        );
      }
    });

    test('ÇA is Ç + CharGap + A', () {
      expect(frenchAlphabet.wordPatterns!['ÇA'], const [
        Signal(_s),
        Signal(_d),
        Signal(_s),
        Signal(_d),
        Signal(_d), // Ç
        CharGap(),
        Signal(_d),
        Signal(_s), // A
      ]);
    });

    test('OUI is O + U + I, separated by CharGap', () {
      expect(frenchAlphabet.wordPatterns!['OUI'], const [
        Signal(_s),
        Signal(_s),
        Signal(_s), // O
        CharGap(),
        Signal(_d),
        Signal(_d),
        Signal(_s), // U
        CharGap(),
        Signal(_d),
        Signal(_d), // I
      ]);
    });
  });

  group('French levels', () {
    test('are french-letters and french-words', () {
      expect(frenchAlphabet.levels.map((l) => l.name), [
        'french-letters',
        'french-words',
      ]);
    });

    test('the letters level teaches the 30 letters in order', () {
      final letters = frenchAlphabet.levels[0];
      expect(letters.kind, LevelKind.characters);
      expect(letters.language, MorseLanguage.french);
      expect(letters.characters, frenchAlphabet.characterOrder);
      expect(letters.patterns, frenchAlphabet.characters);
    });

    test('the words level teaches the 20 words with their patterns', () {
      final words = frenchAlphabet.levels[1];
      expect(words.kind, LevelKind.words);
      expect(words.language, MorseLanguage.french);
      expect(words.characters, frenchAlphabet.wordList);
      expect(words.wordPatterns, frenchAlphabet.wordPatterns);
      expect(words.patterns['APRÈS'], [
        for (final letter in 'APRÈS'.split(''))
          ...frenchAlphabet.characters[letter]!,
      ]);
    });
  });
}
