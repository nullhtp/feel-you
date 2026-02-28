import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_digits.dart';

/// All available levels in order. Digits first (index 0), letters second
/// (index 1).
final List<Level> levels = [
  Level(name: 'digits', characters: morseDigitsList, patterns: morseDigits),
  Level(name: 'letters', characters: morseLetters, patterns: morseAlphabet),
];
