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
