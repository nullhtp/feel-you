import 'package:feel_you/morse/morse_arabic.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/morse/morse_utils.dart';

/// Extended Arabic alphabet that includes variant character forms.
///
/// أ (hamza on alif) and ى (alif maqsura) share the same Morse pattern as
/// ا (alif). These aliases are needed for word pattern composition but are
/// kept separate from [morseArabicAlphabet] to avoid polluting the
/// reverse-lookup table used by [decodePatternForLanguage].
final Map<String, List<MorseSymbol>> _arabicAlphabetWithAliases = {
  ...morseArabicAlphabet,
  'أ': morseArabicAlphabet['ا']!, // Hamza on Alif
  'ى': morseArabicAlphabet['ا']!, // Alif Maqsura
};

/// Morse code patterns for common Arabic words.
///
/// Each entry maps an Arabic word to its flat Morse pattern, with
/// [MorseSymbol.charGap] separating each letter's symbols.
///
/// Patterns are derived at runtime from [morseArabicAlphabet] letter patterns
/// (with aliases for أ and ى) using [buildWordPatterns].
final Map<String, List<MorseSymbol>> morseArabicWords = buildWordPatterns(
  morseArabicWordsList,
  _arabicAlphabetWithAliases,
);

/// All 20 Arabic words in learning order: sorted by length (shortest first),
/// then by Arabic usage frequency (most common first) within each group.
const List<String> morseArabicWordsList = [
  // 2-letter
  'في', 'من', 'لا', 'ما', 'هو',
  // 3-letter
  'هذا', 'على', 'أنا', 'كان', 'بعد',
  // 4-letter
  'الذي', 'التي', 'يمكن', 'كبير', 'منها',
  // 5-letter
  'عليها', 'عندما', 'بينما', 'البيت', 'عليهم',
];
