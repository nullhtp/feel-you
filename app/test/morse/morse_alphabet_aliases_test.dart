import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MorseAlphabet.aliases', () {
    test("Arabic أ and ى have Alif's pattern and are not letters", () {
      const alif = [MorseSignal.dot, MorseSignal.dash];
      expect(arabicAlphabet.aliases, {'أ': alif, 'ى': alif});
      expect(arabicAlphabet.characters['ا'], alif);
      expect(arabicAlphabet.characters.containsKey('أ'), isFalse);
      expect(arabicAlphabet.characters.containsKey('ى'), isFalse);
    });

    test("Russian Ё has Е's pattern and is not a letter", () {
      expect(russianAlphabet.aliases, {
        'Ё': [MorseSignal.dot],
      });
      expect(russianAlphabet.characters['Е'], [MorseSignal.dot]);
      expect(russianAlphabet.characters.containsKey('Ё'), isFalse);
    });

    test('the digits and English alphabets have none', () {
      expect(digitAlphabet.aliases, isEmpty);
      expect(englishAlphabet.aliases, isEmpty);
    });

    test('decoding gives the letter, never an alias', () {
      const alif = [MorseSignal.dot, MorseSignal.dash];
      expect(morseRegistry.decodePattern(alif, MorseLanguage.arabic), 'ا');
      expect(
        morseRegistry.decodePattern([MorseSignal.dot], MorseLanguage.russian),
        'Е',
      );
    });

    test('word patterns are built with the aliases', () {
      // ألم starts with أ, which has Alif's pattern.
      expect(arabicAlphabet.wordPatterns!['ألم']!.take(3), const [
        Signal(MorseSignal.dot),
        Signal(MorseSignal.dash),
        CharGap(),
      ]);
    });
  });
}
