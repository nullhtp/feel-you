import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_alphabet_registry.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_punctuation.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:feel_you/tactile/tactile.dart';

/// Punctuation that every language's Morse codec encodes.
///
/// Only `?`, which marks the quiz. Other punctuation, and the space, are
/// left to the text reader to decide.
const Map<String, List<MorseSignal>> _punctuation = {'?': questionMarkPattern};

/// The Morse code as a [TactileCodec], for one [language].
///
/// Owns the per-language lookups that turn text into Morse: each character
/// is looked up in the language's letters, ignoring case, and the digits
/// (through [MorseAlphabetRegistry.encodeLetter]), then in the language
/// alphabet's [MorseAlphabet.aliases], then in the punctuation (`?`).
/// Consecutive characters are separated by a letter gap.
///
/// A dot becomes [TactileToken.shortPulse], a dash
/// [TactileToken.longPulse] and a letter gap [TactileToken.characterGap].
/// The description uses the companion overlay's notation (see
/// [formatMorseTokens]).
class MorseCodec implements TactileCodec {
  /// Creates the codec of [language], looking characters up in [registry]
  /// (the global [morseRegistry] by default).
  MorseCodec(this.language, {MorseAlphabetRegistry? registry})
    : _registry = registry ?? morseRegistry;

  /// The language whose letters this codec encodes, besides the digits and
  /// `?`.
  final MorseLanguage language;

  final MorseAlphabetRegistry _registry;

  @override
  List<TactileToken> encode(String text) => [
    for (final token in _morseTokens(text)) _tactileToken(token),
  ];

  @override
  String describe(String text) => formatMorseTokens(_morseTokens(text));

  /// The Morse tokens of [text]: each character's signals, with a [CharGap]
  /// between consecutive characters.
  List<MorseToken> _morseTokens(String text) {
    final tokens = <MorseToken>[];
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      final signals = _signalsOf(character);
      if (signals == null) {
        throw ArgumentError.value(
          character,
          'text',
          'cannot be encoded in ${language.name} Morse',
        );
      }
      if (tokens.isNotEmpty) tokens.add(const CharGap());
      for (final signal in signals) {
        tokens.add(Signal(signal));
      }
    }
    return tokens;
  }

  List<MorseSignal>? _signalsOf(String character) {
    final aliases = _registry.forLanguage(language)?.aliases ?? const {};
    return _registry.encodeLetter(character, language) ??
        aliases[character.toUpperCase()] ??
        aliases[character] ??
        _punctuation[character];
  }

  static TactileToken _tactileToken(MorseToken token) => switch (token) {
    Signal(signal: MorseSignal.dot) => TactileToken.shortPulse,
    Signal(signal: MorseSignal.dash) => TactileToken.longPulse,
    CharGap() => TactileToken.characterGap,
  };
}

/// Writes Morse [tokens] in the companion overlay's notation: `·` for a dot,
/// `—` for a dash and `/` for a letter gap, separated by single spaces
/// (e.g. `· · / —` for "IT").
///
/// Used for a text's pattern ([MorseCodec.describe]) and for the input the
/// user has tapped so far, which is Morse tokens rather than a text.
String formatMorseTokens(List<MorseToken> tokens) => tokens
    .map(
      (token) => switch (token) {
        Signal(signal: MorseSignal.dot) => '·',
        Signal(signal: MorseSignal.dash) => '—',
        CharGap() => '/',
      },
    )
    .join(' ');
