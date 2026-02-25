/// Configuration for all vibration timing durations.
///
/// All durations are in milliseconds. Every value has a sensible default
/// and can be overridden at construction time for tuning or testing.
class MorseTimingConfig {
  const MorseTimingConfig({
    this.dotDuration = 100,
    this.dashDuration = 300,
    this.interSymbolGap = 100,
    this.successPulseDuration = 80,
    this.successPulseGap = 80,
    this.successPulseCount = 3,
    this.errorBuzzDuration = 600,
  });

  /// Duration of a dot vibration in ms.
  final int dotDuration;

  /// Duration of a dash vibration in ms.
  final int dashDuration;

  /// Silence between consecutive symbols in ms.
  final int interSymbolGap;

  /// Duration of each pulse in the success signal in ms.
  final int successPulseDuration;

  /// Silence between success pulses in ms.
  final int successPulseGap;

  /// Number of pulses in the success signal.
  final int successPulseCount;

  /// Duration of the error buzz in ms.
  final int errorBuzzDuration;
}
