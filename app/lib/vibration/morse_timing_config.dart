/// Configuration for Morse code vibration timing durations.
///
/// All durations are in milliseconds. Every value has a sensible default
/// and can be overridden at construction time for tuning or testing.
///
/// Note: success/error signal patterns are hardcoded in
/// [buildSuccessSignal] and [buildErrorSignal] because their rhythmic
/// structure doesn't decompose into simple duration/steps parameters.
class MorseTimingConfig {
  const MorseTimingConfig({
    this.dotDuration = 100,
    this.dashDuration = 300,
    this.interSymbolGap = 100,
  });

  /// Duration of a dot vibration in ms.
  final int dotDuration;

  /// Duration of a dash vibration in ms.
  final int dashDuration;

  /// Silence between consecutive symbols in ms.
  final int interSymbolGap;
}
