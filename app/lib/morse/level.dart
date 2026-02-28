import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse_symbol.dart';

/// A learnable character set with ordered characters and their Morse patterns.
class Level extends Equatable {
  const Level({
    required this.name,
    required this.characters,
    required this.patterns,
  });

  /// Identifier for the level (e.g., "digits", "letters").
  final String name;

  /// Ordered list of characters in the learning sequence.
  final List<String> characters;

  /// Map of each character to its Morse code pattern.
  final Map<String, List<MorseSymbol>> patterns;

  @override
  List<Object?> get props => [name];
}
