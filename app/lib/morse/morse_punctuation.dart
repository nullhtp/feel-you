import 'package:feel_you/morse/morse_signal.dart';

/// Morse `?` (`··−−··`), played when the user enters a level's quiz.
///
/// It is not an item of any level. At 6 elements it is longer than every
/// digit and letter (5 at most), and it has no letter gaps, so it can't be
/// mistaken for an item or a word. It is also a real Morse symbol, which the
/// user can use later.
const List<MorseSignal> questionMarkPattern = [
  MorseSignal.dot,
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dot,
];
