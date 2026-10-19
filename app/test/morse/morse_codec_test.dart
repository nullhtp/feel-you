import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _s = TactileToken.shortPulse;
const _l = TactileToken.longPulse;
const _gap = TactileToken.characterGap;

/// The Morse tokens of a level item: a word's token pattern, or a
/// character's signals.
List<MorseToken> _levelPattern(Level level, String item) =>
    level.kind == LevelKind.words
    ? level.wordPatterns![item]!
    : [for (final signal in level.patterns[item]!) Signal(signal)];

/// The tactile tokens a Morse pattern stands for.
List<TactileToken> _tactile(List<MorseToken> tokens) => [
  for (final token in tokens)
    switch (token) {
      Signal(signal: MorseSignal.dot) => _s,
      Signal(signal: MorseSignal.dash) => _l,
      CharGap() => _gap,
    },
];

/// The overlay notation of a Morse pattern, written out independently of
/// the codec.
String _notation(List<MorseToken> tokens) => tokens
    .map(
      (token) => switch (token) {
        Signal(signal: MorseSignal.dot) => '·',
        Signal(signal: MorseSignal.dash) => '—',
        CharGap() => '/',
      },
    )
    .join(' ');

/// The vibration pattern builder as it was before the tactile codec
/// (`buildMorseVibrationPattern` at 94cc0b3), kept as the reference the
/// codec and the engine together must reproduce byte for byte.
List<int> _patternBeforeCodec(
  List<MorseToken> tokens,
  MorseTimingConfig config,
) {
  if (tokens.isEmpty) return const [];
  final pattern = <int>[0];
  for (var i = 0; i < tokens.length; i++) {
    switch (tokens[i]) {
      case Signal(signal: final s):
        pattern.add(
          s == MorseSignal.dot ? config.dotDuration : config.dashDuration,
        );
        if (i < tokens.length - 1 && tokens[i + 1] is! CharGap) {
          pattern.add(config.interSymbolGap);
        }
      case CharGap():
        pattern.add(config.interCharGap);
    }
  }
  return pattern;
}

void main() {
  final english = MorseCodec(MorseLanguage.english);
  final arabic = MorseCodec(MorseLanguage.arabic);
  final russian = MorseCodec(MorseLanguage.russian);

  group('MorseCodec.encode', () {
    test('encodes an English letter as pulses', () {
      expect(english.encode('A'), [_s, _l]);
      expect(english.encode('Q'), [_l, _l, _s, _l]);
    });

    test('ignores case', () {
      expect(english.encode('a'), english.encode('A'));
      expect(english.encode('hi'), english.encode('HI'));
      expect(russian.encode('я'), russian.encode('Я'));
    });

    test('encodes the digits in every language', () {
      for (final codec in [english, arabic, russian]) {
        expect(codec.encode('5'), [_s, _s, _s, _s, _s]);
        expect(codec.encode('0'), [_l, _l, _l, _l, _l]);
      }
    });

    test('separates the characters of a word with one character gap', () {
      expect(english.encode('IT'), [_s, _s, _gap, _l]);
      expect(english.encode('THE'), [_l, _gap, _s, _s, _s, _s, _gap, _s]);
      expect(english.encode('A1'), [_s, _l, _gap, _s, _l, _l, _l, _l]);
    });

    test('encodes Arabic and Russian letters with their own alphabets', () {
      expect(arabic.encode('ا'), [_s, _l]); // Alif, like Latin A
      expect(arabic.encode('ع'), [_s, _l, _s, _l]); // Ain
      expect(russian.encode('А'), [_s, _l]);
      expect(russian.encode('Р'), [_s, _l, _s]);
    });

    test("encodes the Arabic aliases with Alif's pattern", () {
      expect(arabic.encode('أ'), [_s, _l]);
      expect(arabic.encode('ى'), [_s, _l]);
      // أ ل م: alias, then Lam (·−··) and Mim (−−).
      expect(arabic.encode('ألم'), [
        _s,
        _l,
        _gap,
        _s,
        _l,
        _s,
        _s,
        _gap,
        _l,
        _l,
      ]);
    });

    test("encodes the Russian alias Ё with Е's pattern, in either case", () {
      expect(russian.encode('Ё'), [_s]);
      expect(russian.encode('ё'), [_s]);
      expect(russian.encode('ЁЖ'), [_s, _gap, _s, _s, _s, _l]);
    });

    test('encodes the question mark in every language', () {
      for (final codec in [english, arabic, russian]) {
        expect(codec.encode('?'), [_s, _s, _l, _l, _s, _s]);
      }
    });

    test("does not encode another language's letter", () {
      expect(() => english.encode('ا'), throwsArgumentError);
      expect(() => english.encode('Ж'), throwsArgumentError);
      expect(() => russian.encode('Q'), throwsArgumentError);
      // An alias belongs to its language only.
      expect(() => english.encode('Ё'), throwsArgumentError);
    });

    test('throws an ArgumentError naming the character it cannot encode', () {
      expect(
        () => english.encode('A!'),
        throwsA(
          isA<ArgumentError>().having((e) => e.invalidValue, 'value', '!'),
        ),
      );
    });

    test('does not encode a space', () {
      expect(() => english.encode('HI OK'), throwsArgumentError);
      expect(() => english.encode(' '), throwsArgumentError);
    });

    test('returns no tokens for an empty text', () {
      expect(english.encode(''), isEmpty);
    });

    test('looks characters up in the given registry', () {
      final digitsOnly = MorseCodec(
        MorseLanguage.english,
        registry: MorseAlphabetRegistry([digitAlphabet]),
      );
      expect(digitsOnly.encode('7'), [_l, _l, _s, _s, _s]);
      expect(() => digitsOnly.encode('A'), throwsArgumentError);
    });

    test('knows its language', () {
      expect(arabic.language, MorseLanguage.arabic);
    });
  });

  group('MorseCodec.describe', () {
    test('writes dots, dashes and character gaps as the overlay does', () {
      expect(english.describe('A'), '· —');
      expect(english.describe('5'), '· · · · ·');
      expect(english.describe('IT'), '· · / —');
      expect(english.describe('?'), '· · — — · ·');
    });

    test("describes aliases with their letter's pattern", () {
      expect(arabic.describe('ألم'), '· — / · — · · / — —');
      expect(russian.describe('Ё'), '·');
    });

    test('describes an empty text as an empty string', () {
      expect(english.describe(''), '');
    });

    test('throws for what it cannot encode', () {
      expect(() => english.describe('A!'), throwsArgumentError);
    });
  });

  group('formatMorseTokens', () {
    test('writes Morse input in the overlay notation', () {
      expect(
        formatMorseTokens(const [
          Signal(MorseSignal.dot),
          CharGap(),
          Signal(MorseSignal.dash),
        ]),
        '· / —',
      );
      expect(formatMorseTokens(const []), '');
    });
  });

  group('every lesson item encodes to its level pattern', () {
    const defaultTiming = MorseTimingConfig();
    // Distinct durations, so a duration in the wrong place is caught.
    const distinctTiming = MorseTimingConfig(
      dotDuration: 101,
      dashDuration: 303,
      interSymbolGap: 107,
      interCharGap: 311,
    );

    test('in every level of every language, tokens, milliseconds and '
        'description match the level pattern', () {
      final checked = <LevelKind, int>{};
      for (final language in MorseLanguage.values) {
        final codec = MorseCodec(language);
        for (final level in morseRegistry.levelsForLanguage(language)) {
          for (final item in level.characters) {
            final reason = '${language.name} ${level.name} "$item"';
            final expected = _levelPattern(level, item);
            final tokens = codec.encode(item);

            expect(tokens, _tactile(expected), reason: reason);
            for (final timing in [defaultTiming, distinctTiming]) {
              expect(
                buildVibrationPattern(tokens, timing),
                _patternBeforeCodec(expected, timing),
                reason: reason,
              );
            }
            expect(codec.describe(item), _notation(expected), reason: reason);
            checked.update(level.kind, (n) => n + 1, ifAbsent: () => 1);
          }
        }
      }
      // Digits (10, in each of 3 languages) and 26 + 28 + 32 letters.
      expect(checked[LevelKind.characters], 30 + 26 + 28 + 32);
      // 20 words in each of 3 languages.
      expect(checked[LevelKind.words], 60);
    });

    test('characters have no character gap, words have one per letter', () {
      for (final language in MorseLanguage.values) {
        final codec = MorseCodec(language);
        for (final level in morseRegistry.levelsForLanguage(language)) {
          for (final item in level.characters) {
            final gaps = codec.encode(item).where((t) => t == _gap).length;
            expect(
              gaps,
              level.kind == LevelKind.words ? item.length - 1 : 0,
              reason: '${language.name} "$item"',
            );
          }
        }
      }
    });

    test('a word splits back into the tokens of its letters', () {
      for (final language in MorseLanguage.values) {
        final codec = MorseCodec(language);
        final alphabet = morseRegistry.forLanguage(language)!;
        for (final word in alphabet.wordList!) {
          expect(splitAtCharacterGaps(codec.encode(word)), [
            for (final letter in word.split('')) codec.encode(letter),
          ], reason: word);
        }
      }
    });

    test('the quiz marker is Morse ? and lasts 1500 ms', () {
      final tokens = english.encode('?');
      final expected = [
        for (final signal in questionMarkPattern) Signal(signal),
      ];
      expect(tokens, _tactile(expected));
      final pattern = buildVibrationPattern(tokens, defaultTiming);
      expect(pattern, [
        0,
        100,
        100,
        100,
        100,
        300,
        100,
        300,
        100,
        100,
        100,
        100,
      ]);
      expect(pattern.fold<int>(0, (sum, ms) => sum + ms), 1500);
    });
  });

  group('tactileCodecProvider', () {
    test('gives the Morse codec of each language', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final language in MorseLanguage.values) {
        final codec = container.read(tactileCodecProvider(language));
        expect(codec, isA<MorseCodec>());
        expect((codec as MorseCodec).language, language);
      }
      expect(
        container.read(tactileCodecProvider(MorseLanguage.russian)).encode('А'),
        [_s, _l],
      );
    });

    test('looks characters up in the overridden registry', () {
      final container = ProviderContainer(
        overrides: [
          morseRegistryProvider.overrideWithValue(
            MorseAlphabetRegistry([digitAlphabet]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final codec = container.read(tactileCodecProvider(MorseLanguage.english));

      expect(codec.encode('1'), [_s, _l, _l, _l, _l]);
      expect(() => codec.encode('A'), throwsArgumentError);
    });

    test('can be overridden for a language', () {
      final fake = _FixedCodec();
      final container = ProviderContainer(
        overrides: [
          tactileCodecProvider(MorseLanguage.arabic).overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(tactileCodecProvider(MorseLanguage.arabic)),
        same(fake),
      );
      expect(
        container.read(tactileCodecProvider(MorseLanguage.english)),
        isA<MorseCodec>(),
      );
    });
  });
}

/// A codec that encodes every text the same way.
class _FixedCodec implements TactileCodec {
  @override
  List<TactileToken> encode(String text) => const [_l];

  @override
  String describe(String text) => 'fixed';
}
