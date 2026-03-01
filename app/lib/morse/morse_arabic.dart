import 'package:feel_you/morse/morse_symbol.dart';

const _d = MorseSymbol.dot;
const _s = MorseSymbol.dash;

/// Standard Arabic Morse code patterns for all 28 Arabic letters.
///
/// Based on ITU Arabic Morse code standard.
/// Each entry maps an Arabic letter to its dot/dash sequence.
const Map<String, List<MorseSymbol>> morseArabicAlphabet = {
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

/// All 28 Arabic letters in standard Arabic alphabetical order,
/// defining the learning sequence.
const List<String> morseArabicLetters = [
  'ا', // Alif
  'ب', // Ba
  'ت', // Ta
  'ث', // Tha
  'ج', // Jim
  'ح', // Ha
  'خ', // Kha
  'د', // Dal
  'ذ', // Dhal
  'ر', // Ra
  'ز', // Zay
  'س', // Sin
  'ش', // Shin
  'ص', // Sad
  'ض', // Dad
  'ط', // Taa
  'ظ', // Dhaa
  'ع', // Ain
  'غ', // Ghain
  'ف', // Fa
  'ق', // Qaf
  'ك', // Kaf
  'ل', // Lam
  'م', // Mim
  'ن', // Nun
  'ه', // Ha
  'و', // Waw
  'ي', // Ya
];
