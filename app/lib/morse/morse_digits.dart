import 'package:feel_you/morse/morse_symbol.dart';

const _d = MorseSymbol.dot;
const _s = MorseSymbol.dash;

/// International Morse Code patterns for digits 0-9.
///
/// Each entry maps a digit string to its dot/dash sequence.
const Map<String, List<MorseSymbol>> morseDigits = {
  '0': [_s, _s, _s, _s, _s],
  '1': [_d, _s, _s, _s, _s],
  '2': [_d, _d, _s, _s, _s],
  '3': [_d, _d, _d, _s, _s],
  '4': [_d, _d, _d, _d, _s],
  '5': [_d, _d, _d, _d, _d],
  '6': [_s, _d, _d, _d, _d],
  '7': [_s, _s, _d, _d, _d],
  '8': [_s, _s, _s, _d, _d],
  '9': [_s, _s, _s, _s, _d],
};

/// All 10 digits in order, defining the learning sequence.
const List<String> morseDigitsList = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];
