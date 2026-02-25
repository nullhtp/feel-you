import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = MorseTimingConfig();

  group('buildMorseVibrationPattern', () {
    test('single dot produces [0, 100]', () {
      final pattern = buildMorseVibrationPattern([MorseSymbol.dot], config);
      expect(pattern, [0, 100]);
    });

    test('single dash produces [0, 300]', () {
      final pattern = buildMorseVibrationPattern([MorseSymbol.dash], config);
      expect(pattern, [0, 300]);
    });

    test('dot-dash produces [0, 100, 100, 300]', () {
      final pattern = buildMorseVibrationPattern([
        MorseSymbol.dot,
        MorseSymbol.dash,
      ], config);
      expect(pattern, [0, 100, 100, 300]);
    });

    test('three dots (S) produces correct pattern', () {
      final pattern = buildMorseVibrationPattern([
        MorseSymbol.dot,
        MorseSymbol.dot,
        MorseSymbol.dot,
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
        MorseSymbol.dot,
        MorseSymbol.dash,
      ], custom);
      expect(pattern, [0, 150, 200, 450]);
    });
  });

  group('buildSuccessVibrationPattern', () {
    test('default produces 3 pulses of 80ms with 80ms gaps', () {
      final pattern = buildSuccessVibrationPattern(config);
      // [0, 80, 80, 80, 80, 80] = wait 0, vib 80, wait 80, vib 80, wait 80,
      // vib 80
      expect(pattern, [0, 80, 80, 80, 80, 80]);
    });

    test('custom pulse count', () {
      const custom = MorseTimingConfig(
        successPulseCount: 2,
        successPulseDuration: 50,
        successPulseGap: 60,
      );
      final pattern = buildSuccessVibrationPattern(custom);
      expect(pattern, [0, 50, 60, 50]);
    });

    test('single pulse has no gap', () {
      const custom = MorseTimingConfig(successPulseCount: 1);
      final pattern = buildSuccessVibrationPattern(custom);
      expect(pattern, [0, 80]);
    });
  });

  group('buildErrorVibrationPattern', () {
    test('default produces [0, 600]', () {
      final pattern = buildErrorVibrationPattern(config);
      expect(pattern, [0, 600]);
    });

    test('custom error buzz duration', () {
      const custom = MorseTimingConfig(errorBuzzDuration: 800);
      final pattern = buildErrorVibrationPattern(custom);
      expect(pattern, [0, 800]);
    });
  });
}
