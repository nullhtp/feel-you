import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';

/// Converts a list of [TactileToken]s into a vibration duration pattern.
///
/// Returns a list of millisecond values alternating between wait and vibrate
/// durations, as expected by the `vibration` package:
/// `[wait, vibrate, wait, vibrate, ...]`, starting with a wait (0 ms when the
/// tokens start with a pulse). With [config]:
///
/// - [TactileToken.shortPulse] vibrates for [MorseTimingConfig.dotDuration]
///   and [TactileToken.longPulse] for [MorseTimingConfig.dashDuration];
/// - [TactileToken.emptySlot] is silent for [MorseTimingConfig.dotDuration];
/// - two consecutive slots (pulses or empty slots) are separated by
///   [MorseTimingConfig.interSymbolGap];
/// - [TactileToken.characterGap] is a silence of
///   [MorseTimingConfig.interCharGap] in place of that gap.
///
/// Consecutive silences merge into one wait, so wait and vibrate segments
/// always alternate, and a trailing silence is kept, so playback lasts as
/// long as its tokens. Tokens without any pulse yield an empty pattern:
/// there is nothing to feel, and a lone wait would be a one-segment pattern,
/// which the iOS plugin vibrates through (see [buildVibrationIntensities]).
///
/// This is a pure function — no device interaction, fully unit-testable.
List<int> buildVibrationPattern(
  List<TactileToken> tokens,
  MorseTimingConfig config,
) {
  if (!tokens.any(_isPulse)) return const [];

  final pattern = <int>[];
  // Silence not yet written: it is flushed as one wait before the next pulse.
  var wait = 0;
  // Whether the previous token was a slot (a pulse or an empty slot), so the
  // next slot is separated from it by the inter-symbol gap.
  var afterSlot = false;
  for (final token in tokens) {
    switch (token) {
      case TactileToken.shortPulse || TactileToken.longPulse:
        if (afterSlot) wait += config.interSymbolGap;
        pattern
          ..add(wait)
          ..add(
            token == TactileToken.shortPulse
                ? config.dotDuration
                : config.dashDuration,
          );
        wait = 0;
        afterSlot = true;
      case TactileToken.emptySlot:
        if (afterSlot) wait += config.interSymbolGap;
        wait += config.dotDuration;
        afterSlot = true;
      case TactileToken.characterGap:
        wait += config.interCharGap;
        afterSlot = false;
    }
  }
  if (wait > 0) pattern.add(wait);
  return pattern;
}

bool _isPulse(TactileToken token) =>
    token == TactileToken.shortPulse || token == TactileToken.longPulse;

/// Intensity of a vibrate segment in a tactile pattern: full strength.
const int _vibrateIntensity = 255;

/// Builds the `intensities:` list to send together with a [pattern] from
/// [buildVibrationPattern].
///
/// Returns one value per segment of [pattern], so the result always has the
/// same length: `0` at every even (wait) index, including the leading wait,
/// and `255` at every odd (vibrate) index.
///
/// The `vibration` plugin on iOS needs this. It builds a Core Haptics pattern
/// from `intensities:` alone and ignores the wait/vibrate parity: a missing
/// or short list is padded with the last value (or 255 when empty), and
/// every segment with a non-zero intensity vibrates. Without explicit zeros
/// the gaps vibrate too, and a whole letter is felt as one continuous buzz.
/// Android plays the same rhythm either way: it reads `pattern:` as
/// alternating wait/vibrate, uses these values as amplitudes when the motor
/// has amplitude control, and ignores them otherwise.
///
/// A single-segment pattern is a lone wait and yields `[0]`, but the iOS
/// plugin ignores the intensities of a single-segment pattern and vibrates
/// for its whole duration. [buildVibrationPattern] never produces one: a
/// non-empty pattern always has a leading wait and at least one vibrate.
///
/// This is a pure function — no device interaction, fully unit-testable.
List<int> buildVibrationIntensities(List<int> pattern) {
  return List<int>.generate(
    pattern.length,
    (i) => i.isOdd ? _vibrateIntensity : 0,
    growable: false,
  );
}
