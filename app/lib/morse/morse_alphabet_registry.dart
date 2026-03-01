import 'package:feel_you/morse/arabic_alphabet.dart';
import 'package:feel_you/morse/digit_alphabet.dart';
import 'package:feel_you/morse/english_alphabet.dart';
import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';

/// Central registry of all Morse alphabets.
///
/// Provides lookup methods for alphabets, levels, and encode/decode
/// operations. Populated at module initialization with digit, English,
/// and Arabic alphabets.
class MorseAlphabetRegistry {
  MorseAlphabetRegistry(List<MorseAlphabet> alphabets)
    : _alphabets = List.unmodifiable(alphabets) {
    // Build reverse-lookup maps per language for decoding.
    for (final alphabet in _alphabets) {
      final reverseMap = <String, String>{};
      for (final entry in alphabet.characters.entries) {
        reverseMap[_patternKey(entry.value)] = entry.key;
      }
      if (alphabet.language == null) {
        _universalReverse = reverseMap;
      } else {
        _languageReverse[alphabet.language!] = reverseMap;
      }
    }
  }

  final List<MorseAlphabet> _alphabets;
  Map<String, String> _universalReverse = {};
  final Map<MorseLanguage, Map<String, String>> _languageReverse = {};

  /// All registered alphabets.
  List<MorseAlphabet> get all => _alphabets;

  /// The universal alphabet (language is null), e.g. digits.
  MorseAlphabet get universal =>
      _alphabets.firstWhere((a) => a.language == null);

  /// Returns the alphabet for a specific language, or null if not registered.
  MorseAlphabet? forLanguage(MorseLanguage language) {
    for (final a in _alphabets) {
      if (a.language == language) return a;
    }
    return null;
  }

  /// Returns an ordered, unmodifiable list of levels for [language].
  ///
  /// Includes universal levels first, then language-specific levels.
  List<Level> levelsForLanguage(MorseLanguage language) {
    final result = <Level>[];
    for (final a in _alphabets) {
      if (a.language == null || a.language == language) {
        result.addAll(a.levels);
      }
    }
    return List.unmodifiable(result);
  }

  /// Encodes a single character into its Morse signal pattern.
  ///
  /// Checks the language-specific alphabet and the universal alphabet.
  /// Returns null if the character is not found.
  List<MorseSignal>? encodeLetter(String letter, MorseLanguage language) {
    if (letter.isEmpty) return null;
    final langAlphabet = forLanguage(language);
    final upperLetter = letter.toUpperCase();

    // Try language-specific first.
    final langResult =
        langAlphabet?.characters[upperLetter] ??
        langAlphabet?.characters[letter];
    if (langResult != null) return langResult;

    // Fall back to universal (digits).
    return universal.characters[letter];
  }

  /// Decodes a signal pattern back to the corresponding character.
  ///
  /// Checks the language-specific alphabet and the universal alphabet.
  /// Returns null if no match is found.
  String? decodePattern(List<MorseSignal> pattern, MorseLanguage language) {
    if (pattern.isEmpty) return null;
    final key = _patternKey(pattern);

    // Try language-specific first.
    final langMap = _languageReverse[language];
    final langResult = langMap?[key];
    if (langResult != null) return langResult;

    // Fall back to universal.
    return _universalReverse[key];
  }

  static String _patternKey(List<MorseSignal> signals) =>
      signals.map((s) => s.index).join(',');
}

/// The global Morse alphabet registry, pre-populated with all alphabets.
final MorseAlphabetRegistry morseRegistry = MorseAlphabetRegistry([
  digitAlphabet,
  englishAlphabet,
  arabicAlphabet,
]);
