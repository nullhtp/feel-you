import 'package:feel_you/morse/morse_symbol.dart';

const _d = MorseSymbol.dot;
const _s = MorseSymbol.dash;
const _g = MorseSymbol.charGap;

/// Morse code patterns for common English words.
///
/// Each entry maps an uppercase word to its flat Morse pattern, with
/// [MorseSymbol.charGap] separating each letter's symbols.
///
/// Letter patterns (International Morse Code):
///   A: ·−    B: −···  C: −·−·  D: −··   E: ·
///   F: ··−·  G: −−·   H: ····  I: ··    L: ·−··
///   M: −−    N: −·    O: −−−   R: ·−·   S: ···
///   T: −     U: ··−   W: ·−−   Y: −·−−
const Map<String, List<MorseSymbol>> morseWords = {
  // 2-letter words
  'IT': [_d, _d, _g, _s],
  'IS': [_d, _d, _g, _d, _d, _d],
  'TO': [_s, _g, _s, _s, _s],
  'IN': [_d, _d, _g, _s, _d],
  'AT': [_d, _s, _g, _s],

  // 3-letter words
  'THE': [_s, _g, _d, _d, _d, _d, _g, _d],
  'AND': [_d, _s, _g, _s, _d, _g, _s, _d, _d],
  'FOR': [_d, _d, _s, _d, _g, _s, _s, _s, _g, _d, _s, _d],
  'ARE': [_d, _s, _g, _d, _s, _d, _g, _d],
  'BUT': [_s, _d, _d, _d, _g, _d, _d, _s, _g, _s],

  // 4-letter words
  'THAT': [_s, _g, _d, _d, _d, _d, _g, _d, _s, _g, _s],
  'WITH': [_d, _s, _s, _g, _d, _d, _g, _s, _g, _d, _d, _d, _d],
  'HAVE': [_d, _d, _d, _d, _g, _d, _s, _g, _d, _d, _d, _s, _g, _d],
  'THIS': [_s, _g, _d, _d, _d, _d, _g, _d, _d, _g, _d, _d, _d],
  'FROM': [
    _d, _d, _s, _d, _g, // F
    _d, _s, _d, _g, // R
    _s, _s, _s, _g, // O
    _s, _s, // M
  ],

  // 5-letter words
  'THEIR': [
    _s, _g, // T
    _d, _d, _d, _d, _g, // H
    _d, _g, // E
    _d, _d, _g, // I
    _d, _s, _d, // R
  ],
  'ABOUT': [
    _d, _s, _g, // A
    _s, _d, _d, _d, _g, // B
    _s, _s, _s, _g, // O
    _d, _d, _s, _g, // U
    _s, // T
  ],
  'WHICH': [
    _d, _s, _s, _g, // W
    _d, _d, _d, _d, _g, // H
    _d, _d, _g, // I
    _s, _d, _s, _d, _g, // C
    _d, _d, _d, _d, // H
  ],
  'WOULD': [
    _d, _s, _s, _g, // W
    _s, _s, _s, _g, // O
    _d, _d, _s, _g, // U
    _d, _s, _d, _d, _g, // L
    _s, _d, _d, // D
  ],
  'THERE': [
    _s, _g, // T
    _d, _d, _d, _d, _g, // H
    _d, _g, // E
    _d, _s, _d, _g, // R
    _d, // E
  ],
};

/// All 20 words in learning order: sorted by length (shortest first),
/// then by English usage frequency (most common first) within each group.
const List<String> morseWordsList = [
  // 2-letter
  'IT', 'IS', 'TO', 'IN', 'AT',
  // 3-letter
  'THE', 'AND', 'FOR', 'ARE', 'BUT',
  // 4-letter
  'THAT', 'WITH', 'HAVE', 'THIS', 'FROM',
  // 5-letter
  'THEIR', 'ABOUT', 'WHICH', 'WOULD', 'THERE',
];
