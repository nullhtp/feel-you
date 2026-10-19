import 'package:feel_you/tactile/tactile.dart';
import 'package:flutter_test/flutter_test.dart';

const _short = TactileToken.shortPulse;
const _long = TactileToken.longPulse;
const _empty = TactileToken.emptySlot;
const _gap = TactileToken.characterGap;
const _wordGap = TactileToken.wordGap;

void main() {
  group('TactileToken', () {
    test('has exactly the five token kinds', () {
      expect(TactileToken.values, [_short, _long, _empty, _gap, _wordGap]);
    });
  });

  group('splitAtCharacterGaps', () {
    test('splits a word into its characters, in order', () {
      // "HI": H = 4 short, I = 2 short.
      expect(
        splitAtCharacterGaps(const [
          _short,
          _short,
          _short,
          _short,
          _gap,
          _short,
          _short,
        ]),
        [
          [_short, _short, _short, _short],
          [_short, _short],
        ],
      );
    });

    test('keeps a run of pulses without a gap as one character', () {
      // A prosign such as SOS: no character gap inside.
      const sos = [
        _short,
        _short,
        _short,
        _long,
        _long,
        _long,
        _short,
        _short,
        _short,
      ];
      expect(splitAtCharacterGaps(sos), [sos]);
    });

    test('keeps empty slots inside their character', () {
      expect(splitAtCharacterGaps(const [_short, _empty, _gap, _empty]), [
        [_short, _empty],
        [_empty],
      ]);
    });

    test('an empty pattern has no characters', () {
      expect(splitAtCharacterGaps(const []), isEmpty);
    });

    test('splits two words into their letters at the word gap too', () {
      // "HI OK": H, I, a word gap, O (3 long), K (long, short, long).
      expect(
        splitAtCharacterGaps(const [
          _short,
          _short,
          _short,
          _short,
          _gap,
          _short,
          _short,
          _wordGap,
          _long,
          _long,
          _long,
          _gap,
          _long,
          _short,
          _long,
        ]),
        [
          [_short, _short, _short, _short],
          [_short, _short],
          [_long, _long, _long],
          [_long, _short, _long],
        ],
      );
    });

    test('no character it returns contains a gap', () {
      final characters = splitAtCharacterGaps(const [
        _short,
        _wordGap,
        _long,
        _gap,
        _short,
      ]);
      expect(characters, [
        [_short],
        [_long],
        [_short],
      ]);
      for (final character in characters) {
        expect(character, isNot(contains(_gap)));
        expect(character, isNot(contains(_wordGap)));
      }
    });
  });
}
