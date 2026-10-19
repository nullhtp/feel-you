import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/signal_pattern.dart';
import 'package:feel_you/vibration/vibration_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = MorseTimingConfig();

  group('buildVibrationPattern', () {
    test('single dot produces [0, 100]', () {
      final pattern = buildVibrationPattern([TactileToken.shortPulse], config);
      expect(pattern, [0, 100]);
    });

    test('single dash produces [0, 300]', () {
      final pattern = buildVibrationPattern([TactileToken.longPulse], config);
      expect(pattern, [0, 300]);
    });

    test('dot-dash produces [0, 100, 100, 300]', () {
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.longPulse,
      ], config);
      expect(pattern, [0, 100, 100, 300]);
    });

    test('three dots (S) produces correct pattern', () {
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.shortPulse,
        TactileToken.shortPulse,
      ], config);
      expect(pattern, [0, 100, 100, 100, 100, 100]);
    });

    test('empty input produces empty pattern', () {
      final pattern = buildVibrationPattern([], config);
      expect(pattern, isEmpty);
    });

    test('uses custom config values', () {
      const custom = MorseTimingConfig(
        dotDuration: 150,
        dashDuration: 450,
        interSymbolGap: 200,
      );
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.longPulse,
      ], custom);
      expect(pattern, [0, 150, 200, 450]);
    });

    test('character gap produces inter-character silence', () {
      // "IT" = dot dot character gap dash
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.shortPulse,
        TactileToken.characterGap,
        TactileToken.longPulse,
      ], config);
      // dot(100) gap(100) dot(100) charGap(300) dash(300)
      expect(pattern, [0, 100, 100, 100, 300, 300]);
    });

    test('character gap replaces inter-symbol gap at boundary', () {
      // Single char, character gap, single char: dot gap dot
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.characterGap,
        TactileToken.shortPulse,
      ], config);
      // dot(100) characterGap(300) dot(100)
      expect(pattern, [0, 100, 300, 100]);
    });

    test('character gap with custom interCharGap config', () {
      const custom = MorseTimingConfig(interCharGap: 500);
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.characterGap,
        TactileToken.longPulse,
      ], custom);
      // dot(100) charGap(500) dash(300)
      expect(pattern, [0, 100, 500, 300]);
    });

    test('multiple character gaps in a word pattern', () {
      // "THE" = dash gap dot dot dot dot gap dot
      final pattern = buildVibrationPattern([
        TactileToken.longPulse,
        TactileToken.characterGap,
        TactileToken.shortPulse,
        TactileToken.shortPulse,
        TactileToken.shortPulse,
        TactileToken.shortPulse,
        TactileToken.characterGap,
        TactileToken.shortPulse,
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

    test('a run of pulses without a gap has only inter-symbol gaps', () {
      // A prosign such as SOS is one character: no character gap inside.
      final pattern = buildVibrationPattern([
        for (var i = 0; i < 3; i++) TactileToken.shortPulse,
        for (var i = 0; i < 3; i++) TactileToken.longPulse,
        for (var i = 0; i < 3; i++) TactileToken.shortPulse,
      ], config);
      final waits = [for (var i = 2; i < pattern.length; i += 2) pattern[i]];
      expect(waits, List.filled(8, config.interSymbolGap));
      expect(pattern.first, 0);
      expect(pattern, hasLength(18));
    });

    test('empty slot is a silent slot between inter-symbol gaps', () {
      // pulse, empty slot, pulse: 100 on, 100 + 100 + 100 off, 100 on.
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.emptySlot,
        TactileToken.shortPulse,
      ], config);
      expect(pattern, [0, 100, 300, 100]);
    });

    test('slots are evenly spaced whether raised or empty', () {
      // A braille-like cell of six slots: 1, 3 and 6 raised.
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.emptySlot,
        TactileToken.shortPulse,
        TactileToken.emptySlot,
        TactileToken.emptySlot,
        TactileToken.shortPulse,
      ], config);
      // Slot period = dot (100) + inter-symbol gap (100).
      expect(pattern, [0, 100, 300, 100, 500, 100]);
    });

    test('leading silences merge into the first wait', () {
      final pattern = buildVibrationPattern([
        TactileToken.emptySlot,
        TactileToken.shortPulse,
      ], config);
      // empty slot (100) + inter-symbol gap (100), then the pulse.
      expect(pattern, [200, 100]);
    });

    test('consecutive character gaps merge into one wait', () {
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.characterGap,
        TactileToken.characterGap,
        TactileToken.shortPulse,
      ], config);
      expect(pattern, [0, 100, 600, 100]);
    });

    test('a trailing silence is kept', () {
      final pattern = buildVibrationPattern([
        TactileToken.shortPulse,
        TactileToken.emptySlot,
      ], config);
      expect(pattern, [0, 100, 200]);
    });

    test('tokens without a pulse produce an empty pattern', () {
      expect(
        buildVibrationPattern([TactileToken.characterGap], config),
        isEmpty,
      );
      expect(buildVibrationPattern([TactileToken.emptySlot], config), isEmpty);
      expect(
        buildVibrationPattern([
          TactileToken.emptySlot,
          TactileToken.characterGap,
          TactileToken.emptySlot,
        ], config),
        isEmpty,
      );
    });

    test('wait and vibrate segments always alternate', () {
      // Every vibrate segment is a pulse duration, every wait a sum of
      // silences: a pulse never lands on a wait index.
      const custom = MorseTimingConfig(
        dotDuration: 101,
        dashDuration: 303,
        interSymbolGap: 107,
        interCharGap: 311,
      );
      final pattern = buildVibrationPattern([
        TactileToken.characterGap,
        TactileToken.emptySlot,
        TactileToken.longPulse,
        TactileToken.characterGap,
        TactileToken.emptySlot,
        TactileToken.shortPulse,
        TactileToken.shortPulse,
        TactileToken.characterGap,
      ], custom);
      expect(pattern, [
        311 + 101 + 107, // gap, empty slot, inter-symbol gap
        303, // long pulse
        311 + 101 + 107, // gap, empty slot, inter-symbol gap
        101, // short pulse
        107, // inter-symbol gap
        101, // short pulse
        311, // trailing gap
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
