import 'package:feel_you/morse/english_alphabet.dart';
import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:feel_you/morse/morse_word_builder.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// Morse patterns of the 30 French letters: A-Z with the International
/// Morse patterns of [englishAlphabet], and the accented letters À, Ç, É
/// and È.
///
/// The accented letters use the codes International Morse tables list
/// among the Latin extensions (É is also in the ITU standard). None matches
/// another letter or a digit.
final Map<String, List<MorseSignal>> _frenchCharacters = Map.unmodifiable({
  ...englishAlphabet.characters,
  'À': const [_d, _s, _s, _d, _s],
  'Ç': const [_s, _d, _s, _d, _d],
  'É': const [_d, _d, _s, _d, _d],
  'È': const [_d, _s, _d, _d, _s],
});

/// All 30 French letters in learning order: A-Z, then the accented
/// letters by base letter, with É before È as in French dictionary order.
///
/// French counts 26 letters, so A-Z keep their places and the accented
/// letters come after Z.
const List<String> _frenchOrder = [
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
  'À',
  'Ç',
  'É',
  'È',
];

/// All 20 French words in learning order: sorted by length (shortest
/// first), chosen for practical daily communication needs of deaf-blind
/// users. They use only the letters above.
///
/// Needs a native-speaker review.
const List<String> _frenchWordList = [
  // 2-letter
  'ÇA', 'VA', 'LÀ', 'OK', 'HÉ',
  // 3-letter
  'OUI', 'NON', 'EAU', 'MAL', 'BON',
  // 4-letter
  'AIDE', 'FAIM', 'SOIF', 'BIEN', 'STOP',
  // 5-letter
  'MERCI', 'FROID', 'CHAUD', 'SALUT', 'APRÈS',
];

/// Token patterns (with [CharGap] between letters) for every word in
/// [_frenchWordList], shared by the alphabet and its words level.
final Map<String, List<MorseToken>> _frenchWordPatterns = buildWordPatterns(
  _frenchWordList,
  _frenchCharacters,
);

/// The French Morse alphabet.
final MorseAlphabet frenchAlphabet = MorseAlphabet(
  language: MorseLanguage.french,
  characters: _frenchCharacters,
  characterOrder: _frenchOrder,
  wordList: _frenchWordList,
  wordPatterns: _frenchWordPatterns,
  levels: [
    Level(
      name: 'french-letters',
      characters: _frenchOrder,
      patterns: _frenchCharacters,
      language: MorseLanguage.french,
    ),
    Level(
      name: 'french-words',
      kind: LevelKind.words,
      characters: _frenchWordList,
      patterns: buildWordSignalPatterns(_frenchWordList, _frenchCharacters),
      wordPatterns: _frenchWordPatterns,
      language: MorseLanguage.french,
    ),
  ],
);
