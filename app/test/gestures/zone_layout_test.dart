import 'dart:ui' show Size;

import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/gestures/zone_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZoneLayout', () {
    test('defaults to a bottom zone of 15 % of the height', () {
      expect(const GestureTimingConfig().bottomZoneFraction, 0.15);

      final zones = ZoneLayout(
        const Size(800, 600),
        const GestureTimingConfig(),
      );

      expect(zones.midX, 400);
      expect(zones.bottomZoneTop, 510);
    });

    test('takes the bottom-zone height from the config', () {
      final zones = ZoneLayout(
        const Size(800, 600),
        const GestureTimingConfig(bottomZoneFraction: 0.25),
      );

      expect(zones.bottomZoneTop, 450);
    });

    test('the bottom zone includes its top edge', () {
      final zones = ZoneLayout(
        const Size(800, 600),
        const GestureTimingConfig(),
      );

      expect(zones.isInBottomZone(509.9), isFalse);
      expect(zones.isInBottomZone(510), isTrue);
      expect(zones.isInBottomZone(600), isTrue);
    });

    test('the midpoint belongs to the right (dash) half', () {
      final zones = ZoneLayout(
        const Size(800, 600),
        const GestureTimingConfig(),
      );

      expect(zones.isInLeftHalf(0), isTrue);
      expect(zones.isInLeftHalf(399.9), isTrue);
      expect(zones.isInLeftHalf(400), isFalse);
      expect(zones.isInLeftHalf(800), isFalse);
    });
  });
}
