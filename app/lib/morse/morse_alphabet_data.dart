import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';

/// A complete Morse code alphabet for a language (or universal, e.g. digits).
///
/// Each language defines its character-to-signal mappings, learning order,
/// optional word data, and the levels it contributes to the learning system.
///
/// Adding a new language means creating one instance of this class.
class MorseAlphabet {
  MorseAlphabet({
    required this.language,
    required this.characters,
    required this.characterOrder,
    required this.levels,
    this.wordList,
    this.wordPatterns,
  });

  /// The language this alphabet belongs to, or `null` if universal (digits).
  final MorseLanguage? language;

  /// Maps each character to its Morse signal pattern.
  final Map<String, List<MorseSignal>> characters;

  /// Ordered list of characters defining the learning sequence.
  final List<String> characterOrder;

  /// Optional word list for word-level learning.
  final List<String>? wordList;

  /// Optional word-to-token-pattern mapping for word-level learning.
  final Map<String, List<MorseToken>>? wordPatterns;

  /// The levels defined by this alphabet.
  final List<Level> levels;
}
