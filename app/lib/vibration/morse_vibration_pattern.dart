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
    final duration = switch (symbols[i]) {
      MorseSymbol.dot => config.dotDuration,
      MorseSymbol.dash => config.dashDuration,
    };
    pattern.add(duration);
    if (i < symbols.length - 1) {
      pattern.add(config.interSymbolGap);
    }
  }
  return pattern;
}
