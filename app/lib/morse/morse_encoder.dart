import 'package:feel_you/morse/morse_alphabet_registry.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';

/// Encodes a single character (letter or digit, case-insensitive for Latin)
/// into its Morse signal pattern for [language].
///
/// Checks both the language-specific alphabet and the universal (digits)
/// alphabet. Returns `null` if the character is not recognised.
List<MorseSignal>? encodeLetter(String letter, MorseLanguage language) =>
    morseRegistry.encodeLetter(letter, language);

/// Decodes a list of [MorseSignal] values back to the corresponding
/// character for [language].
///
/// Checks both the language-specific alphabet and the universal (digits)
/// alphabet. Returns `null` if the pattern does not match any character.
String? decodePattern(List<MorseSignal> pattern, MorseLanguage language) =>
    morseRegistry.decodePattern(pattern, language);
