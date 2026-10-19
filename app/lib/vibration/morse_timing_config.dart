import 'package:equatable/equatable.dart';

/// Configuration for Morse code vibration timing durations.
///
/// All durations are in milliseconds. Every value has a sensible default
/// and can be overridden at construction time for tuning or testing, or
/// replaced in a copy (see [copyWith]). Configs compare by value.
///
/// The vibration engine times every tactile token with these values, for
/// any codec (see `buildVibrationPattern`): a short pulse lasts
/// [dotDuration], a long pulse [dashDuration], an empty slot is silent for
/// [dotDuration], consecutive slots are [interSymbolGap] apart, a character
/// gap is [interCharGap] of silence and a word gap [interWordGap].
///
/// The defaults are the lesson timing. A reading speed stretches only the
/// two gaps between characters and words (see `ReadingSpeed.timing`).
///
/// Note: the success and error signals are fixed patterns in
/// `signal_pattern.dart` (see `successSignalFor` and `errorSignalFor`)
/// because their rhythmic structure doesn't decompose into simple
/// duration/steps parameters.
class MorseTimingConfig extends Equatable {
  const MorseTimingConfig({
    this.dotDuration = 100,
    this.dashDuration = 300,
    this.interSymbolGap = 100,
    this.interCharGap = 300,
    this.interWordGap = 700,
  });

  /// Duration of a dot vibration in ms.
  final int dotDuration;

  /// Duration of a dash vibration in ms.
  final int dashDuration;

  /// Silence between consecutive symbols in ms.
  final int interSymbolGap;

  /// Silence between characters within a word in ms (3× dot duration per ITU).
  final int interCharGap;

  /// Silence between words in ms (7× dot duration per ITU).
  ///
  /// Independent of [interCharGap], so a speed can stretch each on its own.
  final int interWordGap;

  /// A copy with the given values replaced.
  MorseTimingConfig copyWith({
    int? dotDuration,
    int? dashDuration,
    int? interSymbolGap,
    int? interCharGap,
    int? interWordGap,
  }) => MorseTimingConfig(
    dotDuration: dotDuration ?? this.dotDuration,
    dashDuration: dashDuration ?? this.dashDuration,
    interSymbolGap: interSymbolGap ?? this.interSymbolGap,
    interCharGap: interCharGap ?? this.interCharGap,
    interWordGap: interWordGap ?? this.interWordGap,
  );

  @override
  List<Object?> get props => [
    dotDuration,
    dashDuration,
    interSymbolGap,
    interCharGap,
    interWordGap,
  ];

  @override
  bool get stringify => true;
}
