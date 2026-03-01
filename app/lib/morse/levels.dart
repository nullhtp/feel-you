import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_arabic.dart';
import 'package:feel_you/morse/morse_arabic_words.dart';
import 'package:feel_you/morse/morse_digits.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_words.dart';

/// All available levels in order.
///
/// Digits are universal (`language: null`).
/// English and Arabic levels are tagged with their respective language.
final List<Level> levels = [
  const Level(
    name: 'digits',
    characters: morseDigitsList,
    patterns: morseDigits,
  ),
  const Level(
    name: 'letters',
    characters: morseLetters,
    patterns: morseAlphabet,
    language: MorseLanguage.english,
  ),
  Level(
    name: 'words',
    characters: morseWordsList,
    patterns: morseWords,
    language: MorseLanguage.english,
  ),
  const Level(
    name: 'arabic-letters',
    characters: morseArabicLetters,
    patterns: morseArabicAlphabet,
    language: MorseLanguage.arabic,
  ),
  Level(
    name: 'arabic-words',
    characters: morseArabicWordsList,
    patterns: morseArabicWords,
    language: MorseLanguage.arabic,
  ),
];

/// Returns the ordered list of levels for [language].
///
/// Includes all universal levels (where `language` is `null`) followed by
/// levels specific to the given language, preserving insertion order.
List<Level> levelsForLanguage(MorseLanguage language) {
  return levels
      .where((l) => l.language == null || l.language == language)
      .toList();
}
