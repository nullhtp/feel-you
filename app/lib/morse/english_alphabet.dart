import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_word_builder.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// International Morse Code patterns for letters A-Z.
const Map<String, List<MorseSignal>> _englishCharacters = {
  'A': [_d, _s],
  'B': [_s, _d, _d, _d],
  'C': [_s, _d, _s, _d],
  'D': [_s, _d, _d],
  'E': [_d],
  'F': [_d, _d, _s, _d],
  'G': [_s, _s, _d],
  'H': [_d, _d, _d, _d],
  'I': [_d, _d],
  'J': [_d, _s, _s, _s],
  'K': [_s, _d, _s],
  'L': [_d, _s, _d, _d],
  'M': [_s, _s],
  'N': [_s, _d],
  'O': [_s, _s, _s],
  'P': [_d, _s, _s, _d],
  'Q': [_s, _s, _d, _s],
  'R': [_d, _s, _d],
  'S': [_d, _d, _d],
  'T': [_s],
  'U': [_d, _d, _s],
  'V': [_d, _d, _d, _s],
  'W': [_d, _s, _s],
  'X': [_s, _d, _d, _s],
  'Y': [_s, _d, _s, _s],
  'Z': [_s, _s, _d, _d],
};

/// All 26 letters in alphabetical order, defining the learning sequence.
const List<String> _englishOrder = [
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
];

/// All 20 words in learning order: sorted by length (shortest first),
/// then by English usage frequency (most common first) within each group.
const List<String> _englishWordList = [
  // 2-letter
  'IT', 'IS', 'TO', 'IN', 'AT',
  // 3-letter
  'THE', 'AND', 'FOR', 'ARE', 'BUT',
  // 4-letter
  'THAT', 'WITH', 'HAVE', 'THIS', 'FROM',
  // 5-letter
  'THEIR', 'ABOUT', 'WHICH', 'WOULD', 'THERE',
];

/// The English Morse alphabet.
final MorseAlphabet englishAlphabet = MorseAlphabet(
  language: MorseLanguage.english,
  characters: _englishCharacters,
  characterOrder: _englishOrder,
  wordList: _englishWordList,
  wordPatterns: buildWordPatterns(_englishWordList, _englishCharacters),
  levels: [
    const Level(
      name: 'letters',
      characters: _englishOrder,
      patterns: _englishCharacters,
      language: MorseLanguage.english,
    ),
    Level(
      name: 'words',
      characters: _englishWordList,
      patterns: buildWordSignalPatterns(_englishWordList, _englishCharacters),
      language: MorseLanguage.english,
    ),
  ],
);
