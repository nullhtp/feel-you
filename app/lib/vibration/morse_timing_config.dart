/// Configuration for Morse code vibration timing durations.
///
/// All durations are in milliseconds. Every value has a sensible default
/// and can be overridden at construction time for tuning or testing.
///
/// The vibration engine times every tactile token with these values, for
/// any codec (see `buildVibrationPattern`): a short pulse lasts
/// [dotDuration], a long pulse [dashDuration], an empty slot is silent for
/// [dotDuration], consecutive slots are [interSymbolGap] apart, and a
/// character gap is [interCharGap] of silence.
///
/// Note: the success and error signals are fixed patterns in
/// `signal_pattern.dart` (see `successSignalFor` and `errorSignalFor`)
/// because their rhythmic structure doesn't decompose into simple
/// duration/steps parameters.
class MorseTimingConfig {
  const MorseTimingConfig({
    this.dotDuration = 100,
    this.dashDuration = 300,
    this.interSymbolGap = 100,
    this.interCharGap = 300,
  });

  /// Duration of a dot vibration in ms.
  final int dotDuration;

  /// Duration of a dash vibration in ms.
  final int dashDuration;

  /// Silence between consecutive symbols in ms.
  final int interSymbolGap;

  /// Silence between characters within a word in ms (3× dot duration per ITU).
  final int interCharGap;
}
