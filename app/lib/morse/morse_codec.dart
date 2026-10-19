import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_alphabet_registry.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_prosigns.dart';
import 'package:feel_you/morse/morse_punctuation.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:feel_you/tactile/tactile.dart';

/// Punctuation that every language's Morse codec encodes.
///
/// Only `?`, which marks the quiz. Other punctuation is left to the text
/// reader to decide.
const Map<String, List<MorseSignal>> _punctuation = {'?': questionMarkPattern};

/// What separates two words: any run of whitespace (spaces, tabs, line
/// breaks) is one word gap.
final RegExp _wordSeparator = RegExp(r'\s+');

/// How the description writes a word gap: two letter gaps' `/`.
const String _wordGapNotation = '//';

/// The Morse code as a [TactileCodec], for one [language].
///
/// Owns the per-language lookups that turn text into Morse: each character
/// is looked up in the language's letters, ignoring case, and the digits
/// (through [MorseAlphabetRegistry.encodeLetter]), then in the language
/// alphabet's [MorseAlphabet.aliases], then in the punctuation (`?`).
/// Consecutive characters of a word are separated by a letter gap.
///
/// Whitespace is not a character: any run of it between two words is one
/// word gap, and whitespace before the first word or after the last is
/// ignored. Each word is encoded as it would be on its own.
///
/// A [Prosign] is encoded from [morseProsignPattern] instead, as one
/// character, the same in every language: pulses only, with neither a
/// letter gap nor a word gap.
///
/// A dot becomes [TactileToken.shortPulse], a dash
/// [TactileToken.longPulse], a letter gap [TactileToken.characterGap] and a
/// word gap [TactileToken.wordGap]. The description uses the companion
/// overlay's notation (see [formatMorseTokens]), with `//` for a word gap.
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
    for (final (index, word) in _words(text).indexed) ...[
      if (index > 0) TactileToken.wordGap,
      for (final token in _morseTokens(word)) _tactileToken(token),
    ],
  ];

  @override
  String describe(String text) => _words(text)
      .map((word) => formatMorseTokens(_morseTokens(word)))
      .join(' $_wordGapNotation ');

  /// The [morseProsignPattern] of [prosign] as pulses, with no character
  /// gap and no word gap: the same in every language, whatever this codec's
  /// alphabet.
  @override
  List<TactileToken> encodeProsign(Prosign prosign) => [
    for (final token in _prosignTokens(prosign)) _tactileToken(token),
  ];

  @override
  String describeProsign(Prosign prosign) =>
      formatMorseTokens(_prosignTokens(prosign));

  /// The Morse tokens of [prosign]: its signals, without a [CharGap].
  static List<MorseToken> _prosignTokens(Prosign prosign) => [
    for (final signal in morseProsignPattern(prosign)) Signal(signal),
  ];

  /// The words of [text], without the whitespace around and between them.
  static Iterable<String> _words(String text) =>
      text.split(_wordSeparator).where((word) => word.isNotEmpty);

  /// The Morse tokens of [text], a single word: each character's signals,
  /// with a [CharGap] between consecutive characters.
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
