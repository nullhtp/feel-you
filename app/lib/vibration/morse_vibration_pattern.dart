import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';

/// Converts a list of [MorseToken]s into a vibration duration pattern.
///
/// Returns a list of millisecond values alternating between wait and vibrate
/// durations, as expected by the `vibration` package:
/// `[wait, vibrate, wait, vibrate, ...]`.
///
/// This is a pure function — no device interaction, fully unit-testable.
List<int> buildMorseVibrationPattern(
  List<MorseToken> tokens,
  MorseTimingConfig config,
) {
  if (tokens.isEmpty) return const [];

  final pattern = <int>[0]; // initial wait of 0ms
  for (var i = 0; i < tokens.length; i++) {
    switch (tokens[i]) {
      case Signal(signal: final s):
        final duration = s == MorseSignal.dot
            ? config.dotDuration
            : config.dashDuration;
        pattern.add(duration);
        if (i < tokens.length - 1 && tokens[i + 1] is! CharGap) {
          pattern.add(config.interSymbolGap);
        }
      case CharGap():
        // Replace the trailing inter-symbol gap (if any) with the char gap,
        // or add the char gap silence directly.
        pattern.add(config.interCharGap);
    }
  }
  return pattern;
}

/// Convenience function to convert a list of [MorseSignal]s (single-character
/// patterns) into a vibration duration pattern.
List<int> buildMorseVibrationPatternFromSignals(
  List<MorseSignal> signals,
  MorseTimingConfig config,
) {
  return buildMorseVibrationPattern(
    signals.map((s) => Signal(s) as MorseToken).toList(),
    config,
  );
}

/// Intensity of a vibrate segment in a Morse pattern: full strength.
const int _morseVibrateIntensity = 255;

/// Builds the `intensities:` list to send together with a Morse [pattern]
/// from [buildMorseVibrationPattern].
///
/// Returns one value per segment of [pattern], so the result always has the
/// same length: `0` at every even (wait) index, including the leading 0ms
/// wait, and `255` at every odd (vibrate) index.
///
/// The `vibration` plugin on iOS needs this. It builds a Core Haptics pattern
/// from `intensities:` alone and ignores the wait/vibrate parity: a missing
/// or short list is padded with the last value (or 255 when empty), and
/// every segment with a non-zero intensity vibrates. Without explicit zeros
/// the gaps vibrate too, and a whole letter is felt as one continuous buzz.
/// Android plays the same rhythm either way: it reads `pattern:` as
/// alternating wait/vibrate, uses these values as amplitudes when the motor
/// has amplitude control, and ignores them otherwise.
///
/// A single-segment pattern is a lone wait and yields `[0]`, but the iOS
/// plugin ignores the intensities of a single-segment pattern and vibrates
/// for its whole duration. The builders above never produce one: a
/// non-empty pattern always has the leading wait and at least one vibrate.
///
/// This is a pure function — no device interaction, fully unit-testable.
List<int> buildMorseVibrationIntensities(List<int> pattern) {
  return List<int>.generate(
    pattern.length,
    (i) => i.isOdd ? _morseVibrateIntensity : 0,
    growable: false,
  );
}
