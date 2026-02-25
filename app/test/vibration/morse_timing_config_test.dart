import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MorseTimingConfig', () {
    test('has correct default values', () {
      const config = MorseTimingConfig();

      expect(config.dotDuration, 100);
      expect(config.dashDuration, 300);
      expect(config.interSymbolGap, 100);
      expect(config.successPulseDuration, 80);
      expect(config.successPulseGap, 80);
      expect(config.successPulseCount, 3);
      expect(config.errorBuzzDuration, 600);
    });

    test('accepts custom values', () {
      const config = MorseTimingConfig(
        dotDuration: 150,
        dashDuration: 450,
        interSymbolGap: 120,
        successPulseDuration: 100,
        successPulseGap: 100,
        successPulseCount: 5,
        errorBuzzDuration: 800,
      );

      expect(config.dotDuration, 150);
      expect(config.dashDuration, 450);
      expect(config.interSymbolGap, 120);
      expect(config.successPulseDuration, 100);
      expect(config.successPulseGap, 100);
      expect(config.successPulseCount, 5);
      expect(config.errorBuzzDuration, 800);
    });

    test('partial overrides keep other defaults', () {
      const config = MorseTimingConfig(errorBuzzDuration: 800);

      expect(config.dotDuration, 100);
      expect(config.dashDuration, 300);
      expect(config.interSymbolGap, 100);
      expect(config.errorBuzzDuration, 800);
    });
  });
}
