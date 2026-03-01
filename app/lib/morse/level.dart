import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';

/// A learnable character set with ordered characters and their Morse patterns.
class Level extends Equatable {
  const Level({
    required this.name,
    required this.characters,
    required this.patterns,
    this.language,
  });

  /// Identifier for the level (e.g., "digits", "letters", "arabic-letters").
  final String name;

  /// Ordered list of characters in the learning sequence.
  final List<String> characters;

  /// Map of each character to its Morse signal pattern.
  final Map<String, List<MorseSignal>> patterns;

  /// The language this level belongs to, or `null` if universal (e.g. digits).
  final MorseLanguage? language;

  @override
  List<Object?> get props => [name, characters, patterns, language];
}
