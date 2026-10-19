import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/vibration_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildVibrationIntensities', () {
    test('empty pattern produces empty intensities', () {
      expect(buildVibrationIntensities(const []), isEmpty);
    });

    test('single dot: silent leading wait, full-strength dot', () {
      expect(buildVibrationIntensities(const [0, 100]), [0, 255]);
    });

    test('R (dot dash dot) is silent on every gap', () {
      // wait(0) dot(100) gap(100) dash(300) gap(100) dot(100)
      expect(buildVibrationIntensities(const [0, 100, 100, 300, 100, 100]), [
        0,
        255,
        0,
        255,
        0,
        255,
      ]);
    });

    test('has the same length as the pattern', () {
      for (var length = 0; length <= 12; length++) {
        final pattern = List<int>.filled(length, 100);
        expect(
          buildVibrationIntensities(pattern),
          hasLength(length),
          reason: 'pattern of $length segments',
        );
      }
    });

    test('is zero exactly on the even (wait) indices', () {
      final intensities = buildVibrationIntensities(List<int>.filled(11, 100));
      for (var i = 0; i < intensities.length; i++) {
        expect(intensities[i], i.isEven ? 0 : 255, reason: 'segment $i');
      }
    });

    test('depends on segment position only, not on duration', () {
      expect(buildVibrationIntensities(const [7, 0, 300, 1]), [0, 255, 0, 255]);
    });

    test('odd-length pattern ends with a silent wait', () {
      expect(buildVibrationIntensities(const [0, 100, 300]), [0, 255, 0]);
    });

    test('single-segment pattern is a lone silent wait', () {
      expect(buildVibrationIntensities(const [500]), [0]);
    });
  });

  group('buildVibrationIntensities on every shipped pattern', () {
    // Distinct durations, so a segment landing on the wrong parity is caught.
    const config = MorseTimingConfig(
      dotDuration: 101,
      dashDuration: 303,
      interSymbolGap: 107,
      interCharGap: 311,
    );

    /// Checks that playing [tokens] vibrates exactly their pulses, in
    /// order, and keeps every inter-symbol and character gap silent.
    void expectFeltAsTokens(List<TactileToken> tokens, String reason) {
      final pattern = buildVibrationPattern(tokens, config);
      final intensities = buildVibrationIntensities(pattern);

      expect(intensities, hasLength(pattern.length), reason: reason);
      // The iOS plugin ignores the intensities of a one-segment pattern.
      expect(pattern.length, greaterThanOrEqualTo(2), reason: reason);

      final vibrated = [
        for (var i = 0; i < pattern.length; i++)
          if (intensities[i] > 0) pattern[i],
      ];
      final silent = [
        for (var i = 0; i < pattern.length; i++)
          if (intensities[i] == 0) pattern[i],
      ];

      expect(vibrated, [
        for (final token in tokens)
          if (token == TactileToken.shortPulse)
            config.dotDuration
          else if (token == TactileToken.longPulse)
            config.dashDuration,
      ], reason: reason);
      expect(silent, [
        0,
        for (var i = 1; i < tokens.length; i++)
          if (tokens[i] != TactileToken.characterGap &&
              tokens[i - 1] == TactileToken.characterGap)
            config.interCharGap
          else if (tokens[i] != TactileToken.characterGap)
            config.interSymbolGap,
      ], reason: reason);
    }

    /// The Morse codec of [alphabet]'s language (English for the digits,
    /// which every language shares).
    MorseCodec codecOf(MorseAlphabet alphabet) =>
        MorseCodec(alphabet.language ?? MorseLanguage.english);

    test('every character vibrates exactly its dots and dashes', () {
      for (final alphabet in morseRegistry.all) {
        for (final character in alphabet.characters.keys) {
          expectFeltAsTokens(
            codecOf(alphabet).encode(character),
            '${alphabet.language} "$character"',
          );
        }
      }
    });

    test('every word vibrates its dots and dashes and keeps character gaps '
        'silent', () {
      var words = 0;
      for (final alphabet in morseRegistry.all) {
        for (final word in alphabet.wordList ?? const <String>[]) {
          expectFeltAsTokens(
            codecOf(alphabet).encode(word),
            '${alphabet.language} "$word"',
          );
          words++;
        }
      }
      expect(words, greaterThan(0));
    });
  });
}
