import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';

/// Composes a flat [MorseToken] pattern for [word] by looking up each
/// character in [alphabet] and joining the letter patterns with [CharGap].
///
/// Throws [ArgumentError] if [word] is empty or contains a character not
/// found in [alphabet].
List<MorseToken> composeWordPattern(
  String word,
  Map<String, List<MorseSignal>> alphabet,
) {
  if (word.isEmpty) {
    throw ArgumentError.value(word, 'word', 'must not be empty');
  }
  final result = <MorseToken>[];
  for (var i = 0; i < word.length; i++) {
    final letter = word[i];
    final letterPattern = alphabet[letter];
    if (letterPattern == null) {
      throw ArgumentError.value(
        letter,
        'word[$i]',
        'character not found in alphabet',
      );
    }
    for (final signal in letterPattern) {
      result.add(Signal(signal));
    }
    if (i < word.length - 1) {
      result.add(const CharGap());
    }
  }
  return result;
}

/// Builds a word-to-token-pattern map by calling [composeWordPattern] for
/// each word in [words] using the given [alphabet].
Map<String, List<MorseToken>> buildWordPatterns(
  List<String> words,
  Map<String, List<MorseSignal>> alphabet,
) {
  return {for (final word in words) word: composeWordPattern(word, alphabet)};
}

/// Builds a word-to-signal-pattern map by concatenating each letter's signals.
///
/// Unlike [buildWordPatterns], this returns flat [MorseSignal] lists without
/// [CharGap] tokens — suitable for the [Level.patterns] field.
Map<String, List<MorseSignal>> buildWordSignalPatterns(
  List<String> words,
  Map<String, List<MorseSignal>> alphabet,
) {
  return {
    for (final word in words)
      word: [
        for (final letter in word.split(''))
          ...alphabet[letter] ??
              (throw ArgumentError.value(
                letter,
                'word',
                'character not found in alphabet',
              )),
      ],
  };
}
