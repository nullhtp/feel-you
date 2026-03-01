import 'package:feel_you/morse/morse_alphabet_registry.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:flutter/foundation.dart';

/// Returns `true` if two Morse signal patterns are equal.
bool patternsEqual(List<MorseSignal> a, List<MorseSignal> b) =>
    listEquals(a, b);

/// Returns `true` if [pattern] is a valid Morse pattern for any known
/// character in the universal or language-specific alphabet.
bool isValidPattern(List<MorseSignal> pattern, MorseLanguage language) {
  if (pattern.isEmpty) return false;
  return morseRegistry.decodePattern(pattern, language) != null;
}

/// Returns `true` if two Morse token patterns (including [CharGap]) are equal.
bool tokenPatternsEqual(List<MorseToken> a, List<MorseToken> b) =>
    listEquals(a, b);
