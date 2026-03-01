import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_arabic.dart';
import 'package:feel_you/morse/morse_digits.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter/foundation.dart';

/// Reverse lookup from pattern to character, built once at startup.
/// Includes Latin letters A-Z and digits 0-9.
final Map<String, String> _patternToCharacter = {
  for (final entry in morseAlphabet.entries)
    _patternKey(entry.value): entry.key,
  for (final entry in morseDigits.entries) _patternKey(entry.value): entry.key,
};

/// Reverse lookup from pattern to Arabic character, built once at startup.
final Map<String, String> _patternToArabicCharacter = {
  for (final entry in morseArabicAlphabet.entries)
    _patternKey(entry.value): entry.key,
  for (final entry in morseDigits.entries) _patternKey(entry.value): entry.key,
};

String _patternKey(List<MorseSymbol> symbols) =>
    symbols.map((s) => s.index).join(',');

/// Encodes a single character (A-Z, 0-9, or Arabic letter, case-insensitive
/// for Latin) into its Morse pattern.
///
/// Returns `null` if [letter] is not a recognised character.
List<MorseSymbol>? encodeLetter(String letter) {
  if (letter.isEmpty) return null;
  return morseAlphabet[letter.toUpperCase()] ??
      morseDigits[letter] ??
      morseArabicAlphabet[letter];
}

/// Decodes a list of [MorseSymbol] values back to the corresponding
/// character (Latin letter or digit).
///
/// Returns `null` if the pattern does not match any known character.
/// For language-aware decoding, use [decodePatternForLanguage].
String? decodePattern(List<MorseSymbol> symbols) {
  if (symbols.isEmpty) return null;
  return _patternToCharacter[_patternKey(symbols)];
}

/// Decodes a list of [MorseSymbol] values using the alphabet for [language].
///
/// When [language] is [MorseLanguage.english], uses Latin letters + digits.
/// When [language] is [MorseLanguage.arabic], uses Arabic letters + digits.
///
/// Returns `null` if the pattern does not match any known character.
String? decodePatternForLanguage(
  List<MorseSymbol> symbols,
  MorseLanguage language,
) {
  if (symbols.isEmpty) return null;
  final key = _patternKey(symbols);
  return switch (language) {
    MorseLanguage.english => _patternToCharacter[key],
    MorseLanguage.arabic => _patternToArabicCharacter[key],
  };
}

/// Returns `true` if [symbols] is a valid Morse pattern for any known
/// character (Latin letter A-Z, Arabic letter, or digit 0-9).
bool isValidPattern(List<MorseSymbol> symbols) {
  if (symbols.isEmpty) return false;
  final key = _patternKey(symbols);
  return _patternToCharacter.containsKey(key) ||
      _patternToArabicCharacter.containsKey(key);
}

/// Returns `true` if two Morse patterns are equal.
bool patternsEqual(List<MorseSymbol> a, List<MorseSymbol> b) =>
    listEquals(a, b);
