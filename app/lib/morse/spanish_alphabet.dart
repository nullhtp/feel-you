import 'package:feel_you/morse/english_alphabet.dart';
import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:feel_you/morse/morse_word_builder.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// Morse patterns of the 27 Spanish letters: A-Z with the International
/// Morse patterns of [englishAlphabet], and Ñ.
///
/// Ñ (dash-dash-dot-dash-dash) is the code International Morse tables list
/// for Ñ among the non-ITU Latin extensions. It matches no other letter and
/// no digit.
final Map<String, List<MorseSignal>> _spanishCharacters = Map.unmodifiable({
  ...englishAlphabet.characters,
  'Ñ': const [_s, _s, _d, _s, _s],
});

/// All 27 Spanish letters in Spanish alphabetical order, the learning
/// sequence. Ñ is the fifteenth letter, between N and O, as in the alphabet
/// Spanish speakers learn.
const List<String> _spanishOrder = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'Ñ',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

/// All 20 Spanish words in learning order: sorted by length (shortest
/// first), chosen for practical daily communication needs of deaf-blind
/// users. They use only the letters above, so no accented vowels.
///
/// Needs a native-speaker review.
const List<String> _spanishWordList = [
  // 2-letter
  'NO', 'YA', 'YO', 'VE', 'AY',
  // 3-letter
  'VEN', 'SED', 'MAL', 'PAN', 'VOY',
  // 4-letter
  'HOLA', 'AGUA', 'BAÑO', 'BIEN', 'ALTO',
  // 5-letter
  'AYUDA', 'DOLOR', 'CALOR', 'SUEÑO', 'FELIZ',
];

/// Token patterns (with [CharGap] between letters) for every word in
/// [_spanishWordList], shared by the alphabet and its words level.
final Map<String, List<MorseToken>> _spanishWordPatterns = buildWordPatterns(
  _spanishWordList,
  _spanishCharacters,
);

/// The Spanish Morse alphabet.
final MorseAlphabet spanishAlphabet = MorseAlphabet(
  language: MorseLanguage.spanish,
  characters: _spanishCharacters,
  characterOrder: _spanishOrder,
  wordList: _spanishWordList,
  wordPatterns: _spanishWordPatterns,
  levels: [
    Level(
      name: 'spanish-letters',
      characters: _spanishOrder,
      patterns: _spanishCharacters,
      language: MorseLanguage.spanish,
    ),
    Level(
      name: 'spanish-words',
      kind: LevelKind.words,
      characters: _spanishWordList,
      patterns: buildWordSignalPatterns(_spanishWordList, _spanishCharacters),
      wordPatterns: _spanishWordPatterns,
      language: MorseLanguage.spanish,
    ),
  ],
);
