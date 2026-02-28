import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MorseTimingConfig', () {
    test('has correct default values', () {
      const config = MorseTimingConfig();

      expect(config.dotDuration, 100);
      expect(config.dashDuration, 300);
      expect(config.interSymbolGap, 100);
    });

    test('accepts custom values', () {
      const config = MorseTimingConfig(
        dotDuration: 150,
        dashDuration: 450,
        interSymbolGap: 120,
      );

      expect(config.dotDuration, 150);
      expect(config.dashDuration, 450);
      expect(config.interSymbolGap, 120);
    });

    test('partial overrides keep other defaults', () {
      const config = MorseTimingConfig(dashDuration: 400);

      expect(config.dotDuration, 100);
      expect(config.dashDuration, 400);
      expect(config.interSymbolGap, 100);
    });
  });
}
