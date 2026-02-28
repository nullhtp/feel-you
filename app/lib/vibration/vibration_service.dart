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

/// A signal pattern consisting of durations and corresponding amplitudes.
///
/// Used with `Vibration.vibrate(pattern:, intensities:)` to produce a
/// continuous vibration in a single native call — no gaps between steps.
class SignalPattern {
  const SignalPattern(this.pattern, this.intensities);

  /// Duration of each consecutive segment in ms.
  final List<int> pattern;

  /// Amplitude (1–255) for each segment.
  final List<int> intensities;

  /// Total duration of the signal in ms.
  int get totalDuration => pattern.fold(0, (sum, d) => sum + d);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalPattern &&
          _listEquals(pattern, other.pattern) &&
          _listEquals(intensities, other.intensities);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(pattern), Object.hashAll(intensities));

  @override
  String toString() =>
      'SignalPattern(pattern: $pattern, intensities: $intensities)';

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Success signal: five rapid taps — "ta-ta-ta-ta-ta".
///
/// Five very short full-intensity taps with tiny gaps.
/// Unmistakably different from Morse because:
///   - 50ms taps are shorter than any Morse symbol (dot=100ms).
///   - 40ms gaps are shorter than any Morse gap (100ms).
///   - Five equal rapid taps match no Morse letter.
///
/// ```
///   50ms  40ms  50ms  40ms  50ms  40ms  50ms  40ms  50ms
///   ████  ····  ████  ····  ████  ····  ████  ····  ████
/// ```
///
/// Total duration: 410ms.
const successSignal = SignalPattern(
  [50, 40, 50, 40, 50, 40, 50, 40, 50],
  [255, 0, 255, 0, 255, 0, 255, 0, 255],
);

/// Error signal: single long continuous buzz.
///
/// One unbroken full-intensity vibration, longer than any Morse dash (300ms).
/// Unmistakably different from Morse because:
///   - 500ms is longer than any single Morse symbol.
///   - No gaps — one solid wall of vibration.
///
/// ```
///   500ms
///   ██████████████████████████
/// ```
///
/// Total duration: 500ms.
const errorSignal = SignalPattern([500], [255]);

/// Abstract interface for triggering vibrations.
///
/// Implementations can use real device haptics or be mocked for testing.
abstract class VibrationService {
  /// Plays a Morse code pattern as a vibration sequence.
  Future<void> playMorsePattern(List<MorseSymbol> symbols);

  /// Plays the success signal (triple rapid tap).
  Future<void> playSuccess();

  /// Plays the error signal (single long buzz).
  Future<void> playError();

  /// Cancels any ongoing vibration.
  Future<void> cancel();
}

/// Concrete [VibrationService] that uses the `vibration` package.
///
/// For Morse patterns, uses the standard `pattern:` API (no intensities).
/// For success/error signals, uses a single `vibrate(pattern:, intensities:)`
/// call so the OS plays the entire ramp natively without gaps.
class DeviceVibrationService implements VibrationService {
  DeviceVibrationService({this.config = const MorseTimingConfig()});

  final MorseTimingConfig config;

  @override
  Future<void> playMorsePattern(List<MorseSymbol> symbols) async {
    final pattern = buildMorseVibrationPattern(symbols, config);
    if (pattern.isEmpty) return;
    await Vibration.vibrate(pattern: pattern);
    var total = 0;
    for (final ms in pattern) {
      total += ms;
    }
    await Future<void>.delayed(Duration(milliseconds: total));
  }

  @override
  Future<void> playSuccess() async {
    await _playSignal(successSignal);
  }

  @override
  Future<void> playError() async {
    await _playSignal(errorSignal);
  }

  /// Plays a signal pattern in a single native call.
  Future<void> _playSignal(SignalPattern signal) async {
    await Vibration.vibrate(
      pattern: signal.pattern,
      intensities: signal.intensities,
    );
    await Future<void>.delayed(Duration(milliseconds: signal.totalDuration));
  }

  @override
  Future<void> cancel() async {
    await Vibration.cancel();
  }
}
