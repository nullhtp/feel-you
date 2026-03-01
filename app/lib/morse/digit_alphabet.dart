import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_signal.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// International Morse Code patterns for digits 0-9.
const Map<String, List<MorseSignal>> _digitCharacters = {
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
const List<String> _digitOrder = [
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

/// The universal digit alphabet — included for all languages.
final MorseAlphabet digitAlphabet = MorseAlphabet(
  language: null,
  characters: _digitCharacters,
  characterOrder: _digitOrder,
  levels: const [
    Level(name: 'digits', characters: _digitOrder, patterns: _digitCharacters),
  ],
);
