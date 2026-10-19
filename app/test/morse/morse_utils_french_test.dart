import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

void main() {
  group('encodeLetter (French)', () {
    test('encodes É', () {
      expect(encodeLetter('É', MorseLanguage.french), [_d, _d, _s, _d, _d]);
    });

    test('lowercase accented letters encode as uppercase', () {
      for (final (lower, upper) in [
        ('à', 'À'),
        ('ç', 'Ç'),
        ('é', 'É'),
        ('è', 'È'),
      ]) {
        expect(
          encodeLetter(lower, MorseLanguage.french),
          encodeLetter(upper, MorseLanguage.french),
          reason: lower,
        );
      }
    });

    test('encodes digits through the shared digits level', () {
      expect(encodeLetter('7', MorseLanguage.french), [_s, _s, _d, _d, _d]);
    });

    test('accented letters are not English letters', () {
      for (final letter in ['À', 'Ç', 'É', 'È']) {
        expect(encodeLetter(letter, MorseLanguage.english), isNull);
      }
    });
  });

  group('decodePattern (French)', () {
    test('decodes Ç', () {
      expect(decodePattern([_s, _d, _s, _d, _d], MorseLanguage.french), 'Ç');
    });

    test('the pattern of É means nothing in English', () {
      expect(
        decodePattern([_d, _d, _s, _d, _d], MorseLanguage.english),
        isNull,
      );
    });

    test('digit patterns work in French language context', () {
      expect(decodePattern([_d, _d, _d, _d, _d], MorseLanguage.french), '5');
    });
  });

  group('round-trip encode/decode for French', () {
    test('encode then decode returns the letter for all 30 letters', () {
      for (final letter in frenchAlphabet.characterOrder) {
        final pattern = encodeLetter(letter, MorseLanguage.french);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        expect(
          decodePattern(pattern!, MorseLanguage.french),
          letter,
          reason: 'Round-trip failed for $letter',
        );
      }
    });
  });
}
