import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

void main() {
  group('encodeLetter (German)', () {
    test('encodes Ü, in upper and lower case', () {
      expect(encodeLetter('Ü', MorseLanguage.german), [_d, _d, _s, _s]);
      expect(encodeLetter('ü', MorseLanguage.german), [_d, _d, _s, _s]);
    });

    test('lowercase umlauts encode as uppercase', () {
      expect(
        encodeLetter('ä', MorseLanguage.german),
        encodeLetter('Ä', MorseLanguage.german),
      );
      expect(
        encodeLetter('ö', MorseLanguage.german),
        encodeLetter('Ö', MorseLanguage.german),
      );
    });

    test('ß is not taught', () {
      expect(encodeLetter('ß', MorseLanguage.german), isNull);
    });

    test('the German codec encodes the umlauts and rejects ß', () {
      final codec = MorseCodec(MorseLanguage.german);
      expect(codec.describe('Ü'), '· · — —');
      expect(codec.describe('MÜDE'), '— — / · · — — / — · · / ·');
      expect(() => codec.encode('ß'), throwsArgumentError);
    });

    test('encodes digits through the shared digits level', () {
      expect(encodeLetter('9', MorseLanguage.german), [_s, _s, _s, _s, _d]);
    });

    test('the umlauts are not English letters', () {
      for (final letter in ['Ä', 'Ö', 'Ü']) {
        expect(encodeLetter(letter, MorseLanguage.english), isNull);
      }
    });
  });

  group('decodePattern (German)', () {
    test('decodes Ö', () {
      expect(decodePattern([_s, _s, _s, _d], MorseLanguage.german), 'Ö');
    });

    test('the extension code of ß means nothing in German', () {
      expect(
        decodePattern([_d, _d, _d, _s, _s, _d, _d], MorseLanguage.german),
        isNull,
      );
    });

    test('decodes Ä, the pattern of Arabic ع', () {
      const pattern = [_d, _s, _d, _s];
      expect(decodePattern(pattern, MorseLanguage.german), 'Ä');
      expect(decodePattern(pattern, MorseLanguage.arabic), 'ع');
      expect(decodePattern(pattern, MorseLanguage.english), isNull);
    });

    test('digit patterns work in German language context', () {
      expect(decodePattern([_d, _d, _d, _d, _d], MorseLanguage.german), '5');
    });
  });

  group('round-trip encode/decode for German', () {
    test('encode then decode returns the letter for all 29 letters', () {
      for (final letter in germanAlphabet.characterOrder) {
        final pattern = encodeLetter(letter, MorseLanguage.german);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        expect(
          decodePattern(pattern!, MorseLanguage.german),
          letter,
          reason: 'Round-trip failed for $letter',
        );
      }
    });
  });
}
