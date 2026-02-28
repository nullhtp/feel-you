import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_digits.dart';
import 'package:feel_you/morse/morse_words.dart';

/// All available levels in order. Digits first (index 0), letters second
/// (index 1), words third (index 2).
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
  ),
  const Level(name: 'words', characters: morseWordsList, patterns: morseWords),
];
