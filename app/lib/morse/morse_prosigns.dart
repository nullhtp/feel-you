import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/tactile/tactile.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// The International Morse pattern of [prosign]: one character, sent with
/// no letter gap inside, the same in every language.
///
/// | Prosign | Morse | Pattern |
/// |---|---|---|
/// | [Prosign.endOfMessage] | AR | `· − · − ·` |
/// | [Prosign.wait] | AS | `· − · · ·` |
/// | [Prosign.sos] | SOS | `· · · − − − · · ·` |
/// | [Prosign.error] | HH | `· · · · · · · ·` |
///
/// None is the pattern of a digit, of a letter of any language's letters
/// level, or of `?` (see `morse_prosigns_test.dart`), so a prosign is never
/// taken for an item the user has learned. ITU writes `+` and `&` with the
/// patterns of AR and AS; the codec encodes neither as text.
List<MorseSignal> morseProsignPattern(Prosign prosign) => switch (prosign) {
  Prosign.endOfMessage => const [_d, _s, _d, _s, _d],
  Prosign.wait => const [_d, _s, _d, _d, _d],
  Prosign.sos => const [_d, _d, _d, _s, _s, _s, _d, _d, _d],
  Prosign.error => const [_d, _d, _d, _d, _d, _d, _d, _d],
};
