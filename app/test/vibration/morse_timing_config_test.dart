import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MorseTimingConfig', () {
    test('has correct default values', () {
      const config = MorseTimingConfig();

      expect(config.dotDuration, 100);
      expect(config.dashDuration, 300);
      expect(config.interSymbolGap, 100);
      expect(config.interCharGap, 300);
      expect(config.interWordGap, 700);
    });

    test('accepts custom values', () {
      const config = MorseTimingConfig(
        dotDuration: 150,
        dashDuration: 450,
        interSymbolGap: 120,
        interCharGap: 450,
        interWordGap: 900,
      );

      expect(config.dotDuration, 150);
      expect(config.dashDuration, 450);
      expect(config.interSymbolGap, 120);
      expect(config.interCharGap, 450);
      expect(config.interWordGap, 900);
    });

    test('partial overrides keep other defaults', () {
      const config = MorseTimingConfig(dashDuration: 400);

      expect(config.dotDuration, 100);
      expect(config.dashDuration, 400);
      expect(config.interSymbolGap, 100);
      expect(config.interCharGap, 300);
    });

    test('interCharGap defaults to 3x dot duration', () {
      const config = MorseTimingConfig();
      expect(config.interCharGap, config.dotDuration * 3);
    });

    test('interWordGap defaults to 7x dot duration', () {
      const config = MorseTimingConfig();
      expect(config.interWordGap, config.dotDuration * 7);
    });

    test('the character and word gaps are independent', () {
      const config = MorseTimingConfig(interWordGap: 1000);
      expect(config.interCharGap, 300);
      expect(config.interWordGap, 1000);
      expect(const MorseTimingConfig(interCharGap: 500).interWordGap, 700);
    });

    test('copyWith replaces only the given values', () {
      const config = MorseTimingConfig();
      expect(
        config.copyWith(interWordGap: 1000),
        const MorseTimingConfig(interWordGap: 1000),
      );
      expect(
        config.copyWith(
          dotDuration: 1,
          dashDuration: 2,
          interSymbolGap: 3,
          interCharGap: 4,
          interWordGap: 5,
        ),
        const MorseTimingConfig(
          dotDuration: 1,
          dashDuration: 2,
          interSymbolGap: 3,
          interCharGap: 4,
          interWordGap: 5,
        ),
      );
      expect(config.copyWith(), config);
    });

    test('compares by value', () {
      // copyWith builds a new instance, so equality cannot be identity.
      final copy = const MorseTimingConfig().copyWith(interCharGap: 300);
      expect(copy, isNot(same(const MorseTimingConfig())));
      expect(copy, const MorseTimingConfig());
      expect(copy.hashCode, const MorseTimingConfig().hashCode);
      expect(
        const MorseTimingConfig(),
        isNot(const MorseTimingConfig(interWordGap: 701)),
      );
    });
  });
}
