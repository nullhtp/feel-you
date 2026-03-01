import 'package:feel_you/morse/morse_symbol.dart';

const _d = MorseSymbol.dot;
const _s = MorseSymbol.dash;
const _g = MorseSymbol.charGap;

/// Morse code patterns for common Arabic words.
///
/// Each entry maps an Arabic word to its flat Morse pattern, with
/// [MorseSymbol.charGap] separating each letter's symbols.
///
/// Arabic letter patterns (ITU Arabic Morse Code):
///   ا: ·−    ب: −···  ت: −     ث: −·−·  ج: ·−−−
///   ح: ····  خ: −−−   د: −··   ذ: −−··  ر: ·−·
///   ز: −−−·  س: ···   ش: −−−−  ص: −··−  ض: ···−
///   ط: ··−   ظ: −·−−  ع: ·−·−  غ: −−·   ف: ··−·
///   ق: −−·−  ك: −·−   ل: ·−··  م: −−    ن: −·
///   ه: ··−·· و: ·−−   ي: ··
///
/// Note: أ (hamza on alif) and ى (alif maqsura) use the ا (alif) pattern.
const Map<String, List<MorseSymbol>> morseArabicWords = {
  // 2-letter words
  'في': [
    _d, _d, _s, _d, _g, // ف: ··−·
    _d, _d, // ي: ··
  ],
  'من': [
    _s, _s, _g, // م: −−
    _s, _d, // ن: −·
  ],
  'لا': [
    _d, _s, _d, _d, _g, // ل: ·−··
    _d, _s, // ا: ·−
  ],
  'ما': [
    _s, _s, _g, // م: −−
    _d, _s, // ا: ·−
  ],
  'هو': [
    _d, _d, _s, _d, _d, _g, // ه: ··−··
    _d, _s, _s, // و: ·−−
  ],

  // 3-letter words
  'هذا': [
    _d, _d, _s, _d, _d, _g, // ه: ··−··
    _s, _s, _d, _d, _g, // ذ: −−··
    _d, _s, // ا: ·−
  ],
  'على': [
    _d, _s, _d, _s, _g, // ع: ·−·−
    _d, _s, _d, _d, _g, // ل: ·−··
    _d, _s, // ى (alif maqsura — same pattern as alif): ·−
  ],
  'أنا': [
    _d, _s, _g, // أ (hamza on alif — same pattern as alif): ·−
    _s, _d, _g, // ن: −·
    _d, _s, // ا: ·−
  ],
  'كان': [
    _s, _d, _s, _g, // ك: −·−
    _d, _s, _g, // ا: ·−
    _s, _d, // ن: −·
  ],
  'بعد': [
    _s, _d, _d, _d, _g, // ب: −···
    _d, _s, _d, _s, _g, // ع: ·−·−
    _s, _d, _d, // د: −··
  ],

  // 4-letter words
  'الذي': [
    _d, _s, _g, // ا: ·−
    _d, _s, _d, _d, _g, // ل: ·−··
    _s, _s, _d, _d, _g, // ذ: −−··
    _d, _d, // ي: ··
  ],
  'التي': [
    _d, _s, _g, // ا: ·−
    _d, _s, _d, _d, _g, // ل: ·−··
    _s, _g, // ت: −
    _d, _d, // ي: ··
  ],
  'يمكن': [
    _d, _d, _g, // ي: ··
    _s, _s, _g, // م: −−
    _s, _d, _s, _g, // ك: −·−
    _s, _d, // ن: −·
  ],
  'كبير': [
    _s, _d, _s, _g, // ك: −·−
    _s, _d, _d, _d, _g, // ب: −···
    _d, _d, _g, // ي: ··
    _d, _s, _d, // ر: ·−·
  ],
  'منها': [
    _s, _s, _g, // م: −−
    _s, _d, _g, // ن: −·
    _d, _d, _s, _d, _d, _g, // ه: ··−··
    _d, _s, // ا: ·−
  ],

  // 5-letter words
  'عليها': [
    _d, _s, _d, _s, _g, // ع: ·−·−
    _d, _s, _d, _d, _g, // ل: ·−··
    _d, _d, _g, // ي: ··
    _d, _d, _s, _d, _d, _g, // ه: ··−··
    _d, _s, // ا: ·−
  ],
  'عندما': [
    _d, _s, _d, _s, _g, // ع: ·−·−
    _s, _d, _g, // ن: −·
    _s, _d, _d, _g, // د: −··
    _s, _s, _g, // م: −−
    _d, _s, // ا: ·−
  ],
  'بينما': [
    _s, _d, _d, _d, _g, // ب: −···
    _d, _d, _g, // ي: ··
    _s, _d, _g, // ن: −·
    _s, _s, _g, // م: −−
    _d, _s, // ا: ·−
  ],
  'البيت': [
    _d, _s, _g, // ا: ·−
    _d, _s, _d, _d, _g, // ل: ·−··
    _s, _d, _d, _d, _g, // ب: −···
    _d, _d, _g, // ي: ··
    _s, // ت: −
  ],
  'عليهم': [
    _d, _s, _d, _s, _g, // ع: ·−·−
    _d, _s, _d, _d, _g, // ل: ·−··
    _d, _d, _g, // ي: ··
    _d, _d, _s, _d, _d, _g, // ه: ··−··
    _s, _s, // م: −−
  ],
};

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
