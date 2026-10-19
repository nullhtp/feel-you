import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/signal_pattern.dart';
import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

const _withAmplitude = VibrationCapabilities(
  hasVibrator: true,
  hasAmplitudeControl: true,
  hasCustomVibrationsSupport: true,
);

const _withoutAmplitude = VibrationCapabilities(
  hasVibrator: true,
  hasAmplitudeControl: false,
  hasCustomVibrationsSupport: true,
);

/// Durations of the vibrating segments when the platform honours
/// `intensities:` (each segment is on when its intensity is above zero).
List<int> _pulsesWithIntensities(SignalPattern signal) => [
  for (var i = 0; i < signal.pattern.length; i++)
    if (signal.intensities[i] > 0) signal.pattern[i],
];

/// Durations of the silent segments when the platform honours
/// `intensities:`, ignoring zero-length segments.
List<int> _gapsWithIntensities(SignalPattern signal) => [
  for (var i = 0; i < signal.pattern.length; i++)
    if (signal.intensities[i] == 0 && signal.pattern[i] > 0) signal.pattern[i],
];

/// Durations of the vibrating segments when the platform ignores
/// `intensities:` and reads `pattern:` as `[wait, vibrate, wait, ...]`, as
/// Android does without amplitude control.
List<int> _pulsesWithoutIntensities(SignalPattern signal) => [
  for (var i = 1; i < signal.pattern.length; i += 2)
    if (signal.pattern[i] > 0) signal.pattern[i],
];

void main() {
  const config = MorseTimingConfig();
  final morseDurations = {
    config.dotDuration,
    config.dashDuration,
    config.interSymbolGap,
    config.interCharGap,
  };

  group('signal selection', () {
    test('uses the intensity signals with amplitude control', () {
      expect(successSignalFor(_withAmplitude), successSignal);
      expect(errorSignalFor(_withAmplitude), errorSignal);
    });

    test('keeps the intensity signals when amplitude control is unknown', () {
      expect(successSignalFor(VibrationCapabilities.unknown), successSignal);
      expect(errorSignalFor(VibrationCapabilities.unknown), errorSignal);
    });

    test('uses the duration-only signals without amplitude control', () {
      expect(successSignalFor(_withoutAmplitude), durationOnlySuccessSignal);
      expect(errorSignalFor(_withoutAmplitude), durationOnlyErrorSignal);
    });
  });

  group('intensity signals without amplitude control', () {
    // Documents why the fallback exists: played as plain `[wait, vibrate]`
    // timings, the intensity-based signals lose their shape.
    test('the error signal would not vibrate at all', () {
      expect(_pulsesWithoutIntensities(errorSignal), isEmpty);
    });

    test('the success signal would lose a tap', () {
      expect(_pulsesWithoutIntensities(successSignal), [40, 40, 40, 40]);
    });
  });

  group('duration-only signals', () {
    for (final (name, signal) in [
      ('success', durationOnlySuccessSignal),
      ('error', durationOnlyErrorSignal),
    ]) {
      group(name, () {
        test('contains no Morse dot, dash or gap duration', () {
          for (final duration in signal.pattern) {
            expect(morseDurations, isNot(contains(duration)));
          }
        });

        test('has one intensity per segment', () {
          expect(signal.intensities, hasLength(signal.pattern.length));
        });

        test('alternates off and full, starting with off', () {
          for (var i = 0; i < signal.intensities.length; i++) {
            expect(signal.intensities[i], i.isEven ? 0 : 255);
          }
        });

        test('feels the same whether or not intensities are honoured', () {
          expect(
            _pulsesWithoutIntensities(signal),
            _pulsesWithIntensities(signal),
          );
        });
      });
    }

    test('success is five equal taps shorter than a Morse dot', () {
      final pulses = _pulsesWithIntensities(durationOnlySuccessSignal);
      expect(pulses, hasLength(5));
      for (final pulse in pulses) {
        expect(pulse, pulses.first);
        expect(pulse, lessThan(config.dotDuration));
      }
    });

    test('success gaps are shorter than any Morse gap', () {
      final gaps = _gapsWithIntensities(durationOnlySuccessSignal);
      expect(gaps, hasLength(4));
      for (final gap in gaps) {
        expect(gap, lessThan(config.interSymbolGap));
      }
    });

    test('error is one buzz more than twice as long as a Morse dash', () {
      final pulses = _pulsesWithIntensities(durationOnlyErrorSignal);
      expect(pulses, hasLength(1));
      expect(pulses.single, greaterThan(2 * config.dashDuration));
    });

    test('success and error differ in tap count and length', () {
      final success = _pulsesWithIntensities(durationOnlySuccessSignal);
      final error = _pulsesWithIntensities(durationOnlyErrorSignal);
      expect(success.length, isNot(error.length));
      expect(success.reduce((a, b) => a > b ? a : b), lessThan(error.single));
    });

    test('match the documented values', () {
      expect(durationOnlySuccessSignal.pattern, [
        0,
        50,
        60,
        50,
        60,
        50,
        60,
        50,
        60,
        50,
      ]);
      expect(durationOnlySuccessSignal.totalDuration, 490);
      expect(durationOnlyErrorSignal.pattern, [0, 700]);
      expect(durationOnlyErrorSignal.totalDuration, 700);
    });
  });

  group('cloud-off signal', () {
    test('is two 700 ms buzzes, 300 ms apart (1700 ms)', () {
      expect(cloudOffSignal.pattern, [0, 700, 300, 700]);
      expect(cloudOffSignal.intensities, [0, 255, 0, 255]);
      expect(_pulsesWithIntensities(cloudOffSignal), [700, 700]);
      expect(_gapsWithIntensities(cloudOffSignal), [300]);
      expect(cloudOffSignal.totalDuration, 1700);
    });

    test('alternates off and full, starting with off', () {
      expect(cloudOffSignal.intensities, hasLength(4));
      for (var i = 0; i < cloudOffSignal.intensities.length; i++) {
        expect(cloudOffSignal.intensities[i], i.isEven ? 0 : 255);
      }
    });

    test('feels the same whether or not intensities are honoured', () {
      // On a motor without amplitude control Android reads the pattern as
      // [wait, vibrate, wait, vibrate]: still two 700 ms buzzes.
      expect(_pulsesWithoutIntensities(cloudOffSignal), [700, 700]);
      expect(
        _pulsesWithoutIntensities(cloudOffSignal),
        _pulsesWithIntensities(cloudOffSignal),
      );
    });

    test('each buzz is more than twice as long as a Morse dash', () {
      for (final pulse in _pulsesWithIntensities(cloudOffSignal)) {
        expect(pulse, greaterThan(2 * config.dashDuration));
      }
    });

    test('has two buzzes where both error signals have one', () {
      expect(_pulsesWithIntensities(cloudOffSignal), hasLength(2));
      for (final error in [errorSignal, durationOnlyErrorSignal]) {
        expect(_pulsesWithIntensities(error), hasLength(1));
      }
      expect(cloudOffSignal, isNot(errorSignal));
      expect(cloudOffSignal, isNot(durationOnlyErrorSignal));
    });

    test('differs from the success signals', () {
      expect(cloudOffSignal, isNot(successSignal));
      expect(cloudOffSignal, isNot(durationOnlySuccessSignal));
      expect(
        _pulsesWithIntensities(cloudOffSignal).first,
        greaterThan(_pulsesWithIntensities(successSignal).first),
      );
    });
  });
}
