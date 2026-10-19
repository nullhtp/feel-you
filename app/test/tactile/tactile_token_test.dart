import 'package:feel_you/tactile/tactile.dart';
import 'package:flutter_test/flutter_test.dart';

const _short = TactileToken.shortPulse;
const _long = TactileToken.longPulse;
const _empty = TactileToken.emptySlot;
const _gap = TactileToken.characterGap;

void main() {
  group('TactileToken', () {
    test('has exactly the four token kinds', () {
      expect(TactileToken.values, [_short, _long, _empty, _gap]);
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
  });
}
