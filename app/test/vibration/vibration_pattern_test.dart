import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/morse_vibration_pattern.dart';
import 'package:feel_you/vibration/signal_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = MorseTimingConfig();

  group('buildMorseVibrationPattern', () {
    test('single dot produces [0, 100]', () {
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dot),
      ], config);
      expect(pattern, [0, 100]);
    });

    test('single dash produces [0, 300]', () {
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dash),
      ], config);
      expect(pattern, [0, 300]);
    });

    test('dot-dash produces [0, 100, 100, 300]', () {
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
      ], config);
      expect(pattern, [0, 100, 100, 300]);
    });

    test('three dots (S) produces correct pattern', () {
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
      ], config);
      expect(pattern, [0, 100, 100, 100, 100, 100]);
    });

    test('empty input produces empty pattern', () {
      final pattern = buildMorseVibrationPattern([], config);
      expect(pattern, isEmpty);
    });

    test('uses custom config values', () {
      const custom = MorseTimingConfig(
        dotDuration: 150,
        dashDuration: 450,
        interSymbolGap: 200,
      );
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
      ], custom);
      expect(pattern, [0, 150, 200, 450]);
    });

    test('CharGap produces inter-character silence', () {
      // "IT" = dot dot CharGap dash
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const CharGap(),
        const Signal(MorseSignal.dash),
      ], config);
      // dot(100) gap(100) dot(100) charGap(300) dash(300)
      expect(pattern, [0, 100, 100, 100, 300, 300]);
    });

    test('CharGap replaces inter-symbol gap at boundary', () {
      // Single char then CharGap then single char: dot CharGap dot
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dot),
        const CharGap(),
        const Signal(MorseSignal.dot),
      ], config);
      // dot(100) charGap(300) dot(100)
      expect(pattern, [0, 100, 300, 100]);
    });

    test('CharGap with custom interCharGap config', () {
      const custom = MorseTimingConfig(interCharGap: 500);
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dot),
        const CharGap(),
        const Signal(MorseSignal.dash),
      ], custom);
      // dot(100) charGap(500) dash(300)
      expect(pattern, [0, 100, 500, 300]);
    });

    test('multiple CharGaps in a word pattern', () {
      // "THE" = dash CharGap dot dot dot dot CharGap dot
      final pattern = buildMorseVibrationPattern([
        const Signal(MorseSignal.dash),
        const CharGap(),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dot),
        const CharGap(),
        const Signal(MorseSignal.dot),
      ], config);
      // dash(300) charGap(300) dot(100) gap(100) dot(100) gap(100)
      // dot(100) gap(100) dot(100) charGap(300) dot(100)
      expect(pattern, [
        0,
        300,
        300,
        100,
        100,
        100,
        100,
        100,
        100,
        100,
        300,
        100,
      ]);
    });
  });

  group('successSignal', () {
    test('is five rapid taps with gaps', () {
      expect(successSignal.pattern, [50, 40, 50, 40, 50, 40, 50, 40, 50]);
      expect(successSignal.intensities, [255, 0, 255, 0, 255, 0, 255, 0, 255]);
    });

    test('total duration is 410ms', () {
      expect(successSignal.totalDuration, 410);
    });

    test('all pulses are equal length', () {
      final pulses = <int>[];
      for (var i = 0; i < successSignal.pattern.length; i++) {
        if (successSignal.intensities[i] > 0) {
          pulses.add(successSignal.pattern[i]);
        }
      }
      expect(pulses, [50, 50, 50, 50, 50]);
    });

    test('pulse duration is shorter than Morse dot', () {
      for (var i = 0; i < successSignal.pattern.length; i++) {
        if (successSignal.intensities[i] > 0) {
          expect(successSignal.pattern[i], lessThan(config.dotDuration));
        }
      }
    });

    test('gap duration is shorter than Morse gap', () {
      for (var i = 0; i < successSignal.pattern.length; i++) {
        if (successSignal.intensities[i] == 0) {
          expect(successSignal.pattern[i], lessThan(config.interSymbolGap));
        }
      }
    });
  });

  group('errorSignal', () {
    test('is a single long continuous buzz', () {
      expect(errorSignal.pattern, [500]);
      expect(errorSignal.intensities, [255]);
    });

    test('total duration is 500ms', () {
      expect(errorSignal.totalDuration, 500);
    });

    test('duration is longer than Morse dash', () {
      expect(errorSignal.pattern[0], greaterThan(config.dashDuration));
    });

    test('has no gaps', () {
      for (final intensity in errorSignal.intensities) {
        expect(intensity, greaterThan(0));
      }
    });
  });

  group('success vs error contrast', () {
    test('success has multiple segments, error has one', () {
      expect(successSignal.pattern.length, greaterThan(1));
      expect(errorSignal.pattern.length, 1);
    });

    test('success is shorter than error', () {
      expect(successSignal.totalDuration, lessThan(errorSignal.totalDuration));
    });
  });
}
