import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:vibration/vibration.dart';

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

/// Builds the vibration pattern for the success signal.
///
/// Returns alternating wait/vibrate durations for the configured pulse count,
/// with pulses separated by the configured gap.
List<int> buildSuccessVibrationPattern(MorseTimingConfig config) {
  final pattern = <int>[0]; // initial wait of 0ms
  for (var i = 0; i < config.successPulseCount; i++) {
    pattern.add(config.successPulseDuration);
    if (i < config.successPulseCount - 1) {
      pattern.add(config.successPulseGap);
    }
  }
  return pattern;
}

/// Builds the vibration pattern for the error signal.
///
/// Returns a single long buzz with the configured error duration.
List<int> buildErrorVibrationPattern(MorseTimingConfig config) {
  return [0, config.errorBuzzDuration];
}

/// Abstract interface for triggering vibrations.
///
/// Implementations can use real device haptics or be mocked for testing.
abstract class VibrationService {
  /// Plays a Morse code pattern as a vibration sequence.
  Future<void> playMorsePattern(List<MorseSymbol> symbols);

  /// Plays the success signal (short rhythmic pulses).
  Future<void> playSuccess();

  /// Plays the error signal (one long buzz).
  Future<void> playError();

  /// Cancels any ongoing vibration.
  Future<void> cancel();
}

/// Concrete [VibrationService] that uses the `vibration` package.
///
/// The `vibration` plugin fires the vibration asynchronously on the platform
/// and returns immediately. To give callers (e.g. the teaching orchestrator)
/// accurate timing, each play method waits for the total duration of the
/// vibration pattern before returning.
class DeviceVibrationService implements VibrationService {
  DeviceVibrationService({this.config = const MorseTimingConfig()});

  final MorseTimingConfig config;

  /// Calculates the total duration of a vibration pattern in milliseconds.
  ///
  /// The pattern is a list of alternating wait/vibrate durations.
  static int _patternDuration(List<int> pattern) {
    var total = 0;
    for (final ms in pattern) {
      total += ms;
    }
    return total;
  }

  @override
  Future<void> playMorsePattern(List<MorseSymbol> symbols) async {
    final pattern = buildMorseVibrationPattern(symbols, config);
    if (pattern.isEmpty) return;
    await Vibration.vibrate(pattern: pattern);
    await Future<void>.delayed(
      Duration(milliseconds: _patternDuration(pattern)),
    );
  }

  @override
  Future<void> playSuccess() async {
    final pattern = buildSuccessVibrationPattern(config);
    await Vibration.vibrate(pattern: pattern);
    await Future<void>.delayed(
      Duration(milliseconds: _patternDuration(pattern)),
    );
  }

  @override
  Future<void> playError() async {
    final pattern = buildErrorVibrationPattern(config);
    await Vibration.vibrate(pattern: pattern);
    await Future<void>.delayed(
      Duration(milliseconds: _patternDuration(pattern)),
    );
  }

  @override
  Future<void> cancel() async {
    await Vibration.cancel();
  }
}
