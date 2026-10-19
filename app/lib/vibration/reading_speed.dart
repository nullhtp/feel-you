import 'package:feel_you/vibration/morse_timing_config.dart';

/// How fast reading modes play text, in effective words per minute, with
/// Farnsworth timing.
///
/// Farnsworth timing keeps every pulse as it is and slows a text down by
/// stretching only the silences between characters and between words, so a
/// letter learned in the lessons feels the same at every speed. The
/// character speed is fixed at [characterSpeed], the speed of the 100 ms
/// dot: the standard word PARIS is 50 dot units, 5 s at 100 ms a unit.
///
/// With the default timing, the gaps are:
///
/// | Speed | Character gap | Word gap |
/// |---|---|---|
/// | [wpm12] | 300 ms | 700 ms |
/// | [wpm10] | 458 ms | 1068 ms |
/// | [wpm8] | 695 ms | 1621 ms |
/// | [wpm6] | 1089 ms | 2542 ms |
/// | [wpm5] | 1405 ms | 3279 ms |
///
/// Only reading modes play at a reading speed. The lessons keep their own
/// timing, whatever speed is saved.
enum ReadingSpeed {
  /// 12 wpm, the default: the character speed, so nothing is stretched.
  wpm12(12),

  /// 10 wpm.
  wpm10(10),

  /// 8 wpm.
  wpm8(8),

  /// 6 wpm.
  wpm6(6),

  /// 5 wpm, the slowest.
  wpm5(5);

  const ReadingSpeed(this.wordsPerMinute);

  /// The effective speed, in words per minute (PARIS).
  final int wordsPerMinute;

  /// The speed nothing has changed yet: today's timing.
  static const standard = ReadingSpeed.wpm12;

  /// The character speed in words per minute, fixed at that of the 100 ms
  /// dot: the speed at which the pulses of every reading speed are played.
  static const characterSpeed = 12;

  /// The speed of [wordsPerMinute], or `null` if it is not one of the
  /// speeds.
  static ReadingSpeed? fromWordsPerMinute(int wordsPerMinute) {
    for (final speed in values) {
      if (speed.wordsPerMinute == wordsPerMinute) return speed;
    }
    return null;
  }

  /// How much the gaps between characters and words are stretched at this
  /// speed, by the ARRL Farnsworth formula.
  ///
  /// At a character speed c and an effective speed s (both in wpm), the
  /// extra time per standard word is `ta = (60c − 37.2s) / (c·s)` seconds,
  /// spread over the 19 dot units of gap in PARIS (four 3-unit character
  /// gaps and one 7-unit word gap): a character gap lasts `3·ta / 19` and a
  /// word gap `7·ta / 19`. At s = c, ta is 19 dots, the standard 3- and
  /// 7-dot gaps, so both gaps are the standard ones multiplied by
  /// `ta(s) / ta(c) = (60c − 37.2s) / (22.8s)`.
  ///
  /// Computed from integers (`(600c − 372s) / (228s)`), so it is exactly 1
  /// at [standard].
  double get gapStretch {
    const c = characterSpeed;
    final s = wordsPerMinute;
    return (600 * c - 372 * s) / (228 * s);
  }

  /// The timing of this speed: [base] (the lesson timing) with its
  /// character gap and word gap multiplied by [gapStretch] and rounded to
  /// whole milliseconds.
  ///
  /// Dots, dashes and the gap between the pulses of a character are
  /// [base]'s at every speed, and at [standard] the result equals [base].
  MorseTimingConfig timing(MorseTimingConfig base) => base.copyWith(
    interCharGap: (base.interCharGap * gapStretch).round(),
    interWordGap: (base.interWordGap * gapStretch).round(),
  );
}
