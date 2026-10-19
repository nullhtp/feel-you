import 'package:feel_you/morse/english_alphabet.dart';
import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:feel_you/morse/morse_word_builder.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// Morse patterns of the 29 German letters: A-Z with the International
/// Morse patterns of [englishAlphabet], and the umlauts Ä, Ö and Ü.
///
/// The umlauts use the codes International Morse tables list among the
/// Latin extensions. None matches another letter or a digit.
///
/// ß is not taught: it has no ITU code, its extension code (dot-dot-dot-
/// dash-dash-dot-dot) would be the only item longer than the quiz marker
/// `?` and differs from it by one leading dot, and German writes it SS in
/// capitals.
final Map<String, List<MorseSignal>> _germanCharacters = Map.unmodifiable({
  ...englishAlphabet.characters,
  'Ä': const [_d, _s, _d, _s],
  'Ö': const [_s, _s, _s, _d],
  'Ü': const [_d, _d, _s, _s],
});

/// All 29 German letters in learning order: A-Z, then Ä, Ö and Ü, the
/// order in which German alphabet lists add them after Z.
const List<String> _germanOrder = [
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
  'Ä',
  'Ö',
  'Ü',
];

/// All 20 German words in learning order: sorted by length (shortest
/// first), chosen for practical daily communication needs of deaf-blind
/// users. They use only the letters above.
///
/// Needs a native-speaker review.
const List<String> _germanWordList = [
  // 2-letter
  'JA', 'AU', 'DA', 'WO', 'DU',
  // 3-letter
  'GUT', 'WEH', 'KLO', 'GEH', 'AUF',
  // 4-letter
  'NEIN', 'HALT', 'KALT', 'WARM', 'MÜDE',
  // 5-letter
  'HILFE', 'DANKE', 'BITTE', 'HALLO', 'ESSEN',
];

/// Token patterns (with [CharGap] between letters) for every word in
/// [_germanWordList], shared by the alphabet and its words level.
final Map<String, List<MorseToken>> _germanWordPatterns = buildWordPatterns(
  _germanWordList,
  _germanCharacters,
);

/// The German Morse alphabet.
final MorseAlphabet germanAlphabet = MorseAlphabet(
  language: MorseLanguage.german,
  characters: _germanCharacters,
  characterOrder: _germanOrder,
  wordList: _germanWordList,
  wordPatterns: _germanWordPatterns,
  levels: [
    Level(
      name: 'german-letters',
      characters: _germanOrder,
      patterns: _germanCharacters,
      language: MorseLanguage.german,
    ),
    Level(
      name: 'german-words',
      kind: LevelKind.words,
      characters: _germanWordList,
      patterns: buildWordSignalPatterns(_germanWordList, _germanCharacters),
      wordPatterns: _germanWordPatterns,
      language: MorseLanguage.german,
    ),
  ],
);
