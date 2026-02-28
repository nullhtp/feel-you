import 'package:equatable/equatable.dart';

/// A signal pattern consisting of durations and corresponding amplitudes.
///
/// Used with `Vibration.vibrate(pattern:, intensities:)` to produce a
/// continuous vibration in a single native call — no gaps between steps.
class SignalPattern extends Equatable {
  const SignalPattern(this.pattern, this.intensities);

  /// Duration of each consecutive segment in ms.
  final List<int> pattern;

  /// Amplitude (1–255) for each segment.
  final List<int> intensities;

  /// Total duration of the signal in ms.
  int get totalDuration => pattern.fold(0, (sum, d) => sum + d);

  @override
  List<Object?> get props => [pattern, intensities];

  @override
  String toString() =>
      'SignalPattern(pattern: $pattern, intensities: $intensities)';
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
