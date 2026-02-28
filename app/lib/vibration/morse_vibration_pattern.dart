import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';

/// Converts a list of [MorseSymbol]s into a vibration duration pattern.
///
/// Returns a list of millisecond values alternating between wait and vibrate
/// durations, as expected by the `vibration` package:
/// `[wait, vibrate, wait, vibrate, ...]`.
///
/// This is a pure function — no device interaction, fully unit-testable.
List<int> buildMorseVibrationPattern(
  List<MorseSymbol> symbols,
  MorseTimingConfig config,
) {
  if (symbols.isEmpty) return const [];

  final pattern = <int>[0]; // initial wait of 0ms
  for (var i = 0; i < symbols.length; i++) {
    switch (symbols[i]) {
      case MorseSymbol.dot:
      case MorseSymbol.dash:
        final duration = symbols[i] == MorseSymbol.dot
            ? config.dotDuration
            : config.dashDuration;
        pattern.add(duration);
        if (i < symbols.length - 1 && symbols[i + 1] != MorseSymbol.charGap) {
          pattern.add(config.interSymbolGap);
        }
      case MorseSymbol.charGap:
        // Replace the trailing inter-symbol gap (if any) with the char gap,
        // or add the char gap silence directly.
        pattern.add(config.interCharGap);
    }
  }
  return pattern;
}
