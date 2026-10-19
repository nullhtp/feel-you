import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// Morse Ñ.
const _enye = [_s, _s, _d, _s, _s];

void main() {
  group('encodeLetter (Spanish)', () {
    test('encodes Ñ', () {
      expect(encodeLetter('Ñ', MorseLanguage.spanish), _enye);
    });

    test('lowercase ñ encodes as Ñ', () {
      expect(encodeLetter('ñ', MorseLanguage.spanish), _enye);
    });

    test('encodes a letter shared with English', () {
      expect(encodeLetter('S', MorseLanguage.spanish), [_d, _d, _d]);
      expect(encodeLetter('s', MorseLanguage.spanish), [_d, _d, _d]);
    });

    test('encodes digits through the shared digits level', () {
      expect(encodeLetter('0', MorseLanguage.spanish), [_s, _s, _s, _s, _s]);
    });

    test('Ñ is not an English letter', () {
      expect(encodeLetter('Ñ', MorseLanguage.english), isNull);
    });
  });

  group('decodePattern (Spanish)', () {
    test('decodes Ñ', () {
      expect(decodePattern(_enye, MorseLanguage.spanish), 'Ñ');
    });

    test('the pattern of Ñ means nothing in English', () {
      expect(decodePattern(_enye, MorseLanguage.english), isNull);
    });

    test('digit patterns work in Spanish language context', () {
      expect(decodePattern([_d, _d, _d, _d, _d], MorseLanguage.spanish), '5');
    });
  });

  group('cross-language decode', () {
    test('dot-dash is A in English and Spanish, ا in Arabic, А in Russian', () {
      const pattern = [_d, _s];
      expect(decodePattern(pattern, MorseLanguage.english), 'A');
      expect(decodePattern(pattern, MorseLanguage.arabic), 'ا');
      expect(decodePattern(pattern, MorseLanguage.russian), 'А');
      expect(decodePattern(pattern, MorseLanguage.spanish), 'A');
    });
  });

  group('round-trip encode/decode for Spanish', () {
    test('encode then decode returns the letter for all 27 letters', () {
      for (final letter in spanishAlphabet.characterOrder) {
        final pattern = encodeLetter(letter, MorseLanguage.spanish);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        expect(
          decodePattern(pattern!, MorseLanguage.spanish),
          letter,
          reason: 'Round-trip failed for $letter',
        );
      }
    });
  });
}
