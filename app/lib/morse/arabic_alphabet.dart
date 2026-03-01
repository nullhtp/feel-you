import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_word_builder.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// Standard Arabic Morse code patterns for all 28 Arabic letters.
const Map<String, List<MorseSignal>> _arabicCharacters = {
  'ا': [_d, _s], // Alif — ITU: A
  'ب': [_s, _d, _d, _d], // Ba — ITU: B
  'ت': [_s], // Ta — ITU: T
  'ث': [_s, _d, _s, _d], // Tha — ITU: C
  'ج': [_d, _s, _s, _s], // Jim — ITU: J
  'ح': [_d, _d, _d, _d], // Ha — ITU: H
  'خ': [_s, _s, _s], // Kha — ITU: O
  'د': [_s, _d, _d], // Dal — ITU: D
  'ذ': [_s, _s, _d, _d], // Dhal — ITU: Z
  'ر': [_d, _s, _d], // Ra — ITU: R
  'ز': [_s, _s, _s, _d], // Zay — ITU: Ö
  'س': [_d, _d, _d], // Sin — ITU: S
  'ش': [_s, _s, _s, _s], // Shin — ITU: CH
  'ص': [_s, _d, _d, _s], // Sad — ITU: X
  'ض': [_d, _d, _d, _s], // Dad — ITU: V
  'ط': [_d, _d, _s], // Taa — ITU: U
  'ظ': [_s, _d, _s, _s], // Dhaa — ITU: Y
  'ع': [_d, _s, _d, _s], // Ain — ITU: Ä
  'غ': [_s, _s, _d], // Ghain — ITU: G
  'ف': [_d, _d, _s, _d], // Fa — ITU: F
  'ق': [_s, _s, _d, _s], // Qaf — ITU: Q
  'ك': [_s, _d, _s], // Kaf — ITU: K
  'ل': [_d, _s, _d, _d], // Lam — ITU: L
  'م': [_s, _s], // Mim — ITU: M
  'ن': [_s, _d], // Nun — ITU: N
  'ه': [_d, _d, _s, _d, _d], // Ha — ITU: É
  'و': [_d, _s, _s], // Waw — ITU: W
  'ي': [_d, _d], // Ya — ITU: I
};

/// All 28 Arabic letters in standard Arabic alphabetical order.
const List<String> _arabicOrder = [
  'ا',
  'ب',
  'ت',
  'ث',
  'ج',
  'ح',
  'خ',
  'د',
  'ذ',
  'ر',
  'ز',
  'س',
  'ش',
  'ص',
  'ض',
  'ط',
  'ظ',
  'ع',
  'غ',
  'ف',
  'ق',
  'ك',
  'ل',
  'م',
  'ن',
  'ه',
  'و',
  'ي',
];

/// Extended Arabic alphabet with variant character forms.
///
/// أ (hamza on alif) and ى (alif maqsura) share the same Morse pattern as
/// ا (alif). These aliases are needed for word pattern composition but are
/// kept separate from the main alphabet to avoid polluting reverse-lookups.
final Map<String, List<MorseSignal>> _arabicWithAliases = {
  ..._arabicCharacters,
  'أ': _arabicCharacters['ا']!, // Hamza on Alif
  'ى': _arabicCharacters['ا']!, // Alif Maqsura
};

/// All 20 Arabic words in learning order.
const List<String> _arabicWordList = [
  // 2-letter
  'في', 'من', 'لا', 'ما', 'هو',
  // 3-letter
  'هذا', 'على', 'أنا', 'كان', 'بعد',
  // 4-letter
  'الذي', 'التي', 'يمكن', 'كبير', 'منها',
  // 5-letter
  'عليها', 'عندما', 'بينما', 'البيت', 'عليهم',
];

/// The Arabic Morse alphabet.
final MorseAlphabet arabicAlphabet = MorseAlphabet(
  language: MorseLanguage.arabic,
  characters: _arabicCharacters,
  characterOrder: _arabicOrder,
  wordList: _arabicWordList,
  wordPatterns: buildWordPatterns(_arabicWordList, _arabicWithAliases),
  levels: [
    const Level(
      name: 'arabic-letters',
      characters: _arabicOrder,
      patterns: _arabicCharacters,
      language: MorseLanguage.arabic,
    ),
    Level(
      name: 'arabic-words',
      characters: _arabicWordList,
      patterns: buildWordSignalPatterns(_arabicWordList, _arabicWithAliases),
      language: MorseLanguage.arabic,
    ),
  ],
);
