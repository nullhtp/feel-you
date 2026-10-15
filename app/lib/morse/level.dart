import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';

/// What a [Level]'s items are, which decides how they are taught.
///
/// Behaviour that differs between single characters and words (playback,
/// answer evaluation, the bottom-zone action) must switch on this kind,
/// never on a level's position in the level list.
enum LevelKind {
  /// Each item is a single character (e.g. a digit or a letter).
  ///
  /// Patterns are played as plain signals, input is compared signal by
  /// signal, and the bottom zone submits the input.
  characters,

  /// Each item is a multi-character word.
  ///
  /// Patterns are played with [CharGap] pauses between letters, input is
  /// compared token by token including gaps, and the bottom zone inserts a
  /// [CharGap].
  words,
}

/// A learnable character set with ordered characters and their Morse patterns.
class Level extends Equatable {
  const Level({
    required this.name,
    required this.characters,
    required this.patterns,
    this.kind = LevelKind.characters,
    this.wordPatterns,
    this.language,
  }) : assert(
         kind != LevelKind.words || wordPatterns != null,
         'A words level must provide wordPatterns.',
       );

  /// Identifier for the level (e.g., "digits", "letters", "arabic-letters").
  final String name;

  /// Ordered list of characters in the learning sequence.
  final List<String> characters;

  /// Map of each character to its Morse signal pattern.
  final Map<String, List<MorseSignal>> patterns;

  /// Whether this level teaches single characters or words.
  final LevelKind kind;

  /// Map of each word to its token pattern, with [CharGap] between letters.
  ///
  /// Required when [kind] is [LevelKind.words]; unused for character levels.
  final Map<String, List<MorseToken>>? wordPatterns;

  /// The language this level belongs to, or `null` if universal (e.g. digits).
  final MorseLanguage? language;

  @override
  List<Object?> get props => [
    name,
    characters,
    patterns,
    kind,
    wordPatterns,
    language,
  ];
}
