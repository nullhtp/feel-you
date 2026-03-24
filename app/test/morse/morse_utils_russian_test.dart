import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeLetter (Russian)', () {
    test('encodes Russian letter С', () {
      expect(encodeLetter('С', MorseLanguage.russian), [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('encodes Russian letter А', () {
      expect(encodeLetter('А', MorseLanguage.russian), [
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('encodes Russian letter Щ', () {
      expect(encodeLetter('Щ', MorseLanguage.russian), [
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dash,
      ]);
    });

    test('lowercase а encodes same as uppercase А', () {
      expect(
        encodeLetter('а', MorseLanguage.russian),
        encodeLetter('А', MorseLanguage.russian),
      );
    });
  });

  group('decodePattern (Russian)', () {
    test('dot-dash decodes to А in Russian', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dash,
        ], MorseLanguage.russian),
        'А',
      );
    });

    test('three dots decodes to С in Russian', () {
      expect(
        decodePattern([
          MorseSignal.dot,
          MorseSignal.dot,
          MorseSignal.dot,
        ], MorseLanguage.russian),
        'С',
      );
    });

    test('digit patterns work in Russian language context', () {
      final fiveDots = [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dot,
      ];
      expect(decodePattern(fiveDots, MorseLanguage.russian), '5');
    });
  });

  group('cross-language decode', () {
    test('dot-dash returns A for English, ا for Arabic, А for Russian', () {
      final pattern = [MorseSignal.dot, MorseSignal.dash];
      expect(decodePattern(pattern, MorseLanguage.english), 'A');
      expect(decodePattern(pattern, MorseLanguage.arabic), 'ا');
      expect(decodePattern(pattern, MorseLanguage.russian), 'А');
    });

    test('three dots returns S for English, س for Arabic, С for Russian', () {
      final pattern = [MorseSignal.dot, MorseSignal.dot, MorseSignal.dot];
      expect(decodePattern(pattern, MorseLanguage.english), 'S');
      expect(decodePattern(pattern, MorseLanguage.arabic), 'س');
      expect(decodePattern(pattern, MorseLanguage.russian), 'С');
    });
  });

  group('round-trip encode/decode for Russian', () {
    test('encode then decode returns original for all Russian letters', () {
      for (final letter in russianAlphabet.characterOrder) {
        final pattern = encodeLetter(letter, MorseLanguage.russian);
        expect(pattern, isNotNull, reason: 'Failed to encode $letter');
        final decoded = decodePattern(pattern!, MorseLanguage.russian);
        expect(decoded, letter, reason: 'Round-trip failed for $letter');
      }
    });
  });
}
