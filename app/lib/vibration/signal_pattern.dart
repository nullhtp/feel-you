import 'package:equatable/equatable.dart';
import 'package:feel_you/vibration/vibration_capabilities.dart';

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

// ---------------------------------------------------------------------------
// Duration-only fallbacks for motors without amplitude control
// ---------------------------------------------------------------------------
//
// Without amplitude control the plugin drops `intensities:`, and Android
// reads `pattern:` as alternating `[wait, vibrate, wait, vibrate, ...]`.
// Played that way, [successSignal] (which starts with a vibrate segment)
// shifts by one segment into four 40ms taps, and [errorSignal] becomes a
// single 500ms *wait*: the error is never felt at all.
//
// The fallbacks below therefore start with a 0ms off segment and alternate
// off/on, with intensities of exactly 0 and 255. They feel the same whether
// or not the platform honours the intensities, and they rely on duration
// and rhythm alone to stay distinct from Morse and from each other.

/// Success signal without amplitude control: five short taps.
///
/// Same rhythm as [successSignal], with the gaps lengthened from 40ms to
/// 60ms so slower motors stop between taps instead of blurring into one
/// buzz. Unmistakably different from Morse because:
///   - 50ms taps are half a Morse dot (100ms).
///   - 60ms gaps are shorter than any Morse gap (100ms).
///   - Five equal rapid taps match no Morse letter.
///
/// ```text
///   0ms  50ms  60ms  50ms  60ms  50ms  60ms  50ms  60ms  50ms
///        ████  ····  ████  ····  ████  ····  ████  ····  ████
/// ```
///
/// Total duration: 490ms.
const durationOnlySuccessSignal = SignalPattern(
  [0, 50, 60, 50, 60, 50, 60, 50, 60, 50],
  [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
);

/// Error signal without amplitude control: one long continuous buzz.
///
/// Longer than [errorSignal] (500ms) because, without amplitude control,
/// duration is the only contrast left. Unmistakably different from Morse
/// because:
///   - 700ms is more than twice the Morse dash (300ms).
///   - No gaps: one solid wall of vibration, unlike the success taps.
///
/// ```text
///   0ms  700ms
///        ███████████████████████████████████
/// ```
///
/// Total duration: 700ms.
const durationOnlyErrorSignal = SignalPattern([0, 700], [0, 255]);

/// The success signal to play on a device with [capabilities].
///
/// [successSignal] when amplitude control is present or unknown,
/// [durationOnlySuccessSignal] when the device definitely lacks it.
SignalPattern successSignalFor(VibrationCapabilities capabilities) =>
    capabilities.canControlAmplitude
    ? successSignal
    : durationOnlySuccessSignal;

/// The error signal to play on a device with [capabilities].
///
/// [errorSignal] when amplitude control is present or unknown,
/// [durationOnlyErrorSignal] when the device definitely lacks it.
SignalPattern errorSignalFor(VibrationCapabilities capabilities) =>
    capabilities.canControlAmplitude ? errorSignal : durationOnlyErrorSignal;
