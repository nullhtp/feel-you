import 'package:feel_you/morse/morse_alphabet.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/morse/morse_utils.dart';

/// Morse code patterns for common English words.
///
/// Each entry maps an uppercase word to its flat Morse pattern, with
/// [MorseSymbol.charGap] separating each letter's symbols.
///
/// Patterns are derived at runtime from [morseAlphabet] letter patterns
/// using [buildWordPatterns].
final Map<String, List<MorseSymbol>> morseWords = buildWordPatterns(
  morseWordsList,
  morseAlphabet,
);

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
