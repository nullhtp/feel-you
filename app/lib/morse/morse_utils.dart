import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter/foundation.dart';

/// Reverse lookup from pattern to letter, built once at startup.
final Map<String, String> _patternToLetter = {
  for (final entry in morseAlphabet.entries)
    _patternKey(entry.value): entry.key,
};

String _patternKey(List<MorseSymbol> symbols) =>
    symbols.map((s) => s.index).join(',');

/// Encodes a single letter (A-Z, case-insensitive) into its Morse pattern.
///
/// Returns `null` if [letter] is not a single letter A-Z.
List<MorseSymbol>? encodeLetter(String letter) {
  if (letter.isEmpty) return null;
  return morseAlphabet[letter.toUpperCase()];
}

/// Decodes a list of [MorseSymbol] values back to the corresponding letter.
///
/// Returns `null` if the pattern does not match any letter A-Z.
String? decodePattern(List<MorseSymbol> symbols) {
  if (symbols.isEmpty) return null;
  return _patternToLetter[_patternKey(symbols)];
}

/// Returns `true` if [symbols] is a valid Morse pattern for any letter A-Z.
bool isValidPattern(List<MorseSymbol> symbols) {
  if (symbols.isEmpty) return false;
  return _patternToLetter.containsKey(_patternKey(symbols));
}

/// Returns `true` if two Morse patterns are equal.
bool patternsEqual(List<MorseSymbol> a, List<MorseSymbol> b) =>
    listEquals(a, b);
