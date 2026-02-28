import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_digits.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter/foundation.dart';

/// Reverse lookup from pattern to character, built once at startup.
/// Includes both letters A-Z and digits 0-9.
final Map<String, String> _patternToCharacter = {
  for (final entry in morseAlphabet.entries)
    _patternKey(entry.value): entry.key,
  for (final entry in morseDigits.entries) _patternKey(entry.value): entry.key,
};

String _patternKey(List<MorseSymbol> symbols) =>
    symbols.map((s) => s.index).join(',');

/// Encodes a single character (A-Z or 0-9, case-insensitive) into its Morse
/// pattern.
///
/// Returns `null` if [letter] is not a recognised character.
List<MorseSymbol>? encodeLetter(String letter) {
  if (letter.isEmpty) return null;
  return morseAlphabet[letter.toUpperCase()] ?? morseDigits[letter];
}

/// Decodes a list of [MorseSymbol] values back to the corresponding
/// character (letter or digit).
///
/// Returns `null` if the pattern does not match any known character.
String? decodePattern(List<MorseSymbol> symbols) {
  if (symbols.isEmpty) return null;
  return _patternToCharacter[_patternKey(symbols)];
}

/// Returns `true` if [symbols] is a valid Morse pattern for any known
/// character (letter A-Z or digit 0-9).
bool isValidPattern(List<MorseSymbol> symbols) {
  if (symbols.isEmpty) return false;
  return _patternToCharacter.containsKey(_patternKey(symbols));
}

/// Returns `true` if two Morse patterns are equal.
bool patternsEqual(List<MorseSymbol> a, List<MorseSymbol> b) =>
    listEquals(a, b);
