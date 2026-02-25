import 'package:feel_you/morse/morse_symbol.dart';

const _d = MorseSymbol.dot;
const _s = MorseSymbol.dash;

/// International Morse Code patterns for letters A-Z.
///
/// Each entry maps an uppercase letter to its dot/dash sequence.
const Map<String, List<MorseSymbol>> morseAlphabet = {
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
const List<String> morseLetters = [
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
