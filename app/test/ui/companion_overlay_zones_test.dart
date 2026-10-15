import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';

/// The default test surface, in logical pixels.
const _surface = Size(800, 600);

/// Renders only the overlay, backed by [classifier].
Widget _buildOverlay(FakeGestureClassifier classifier) {
  return ProviderScope(
    overrides: [gestureClassifierProvider.overrideWithValue(classifier)],
    child: const MaterialApp(home: CompanionOverlay()),
  );
}

void main() {
  group('CompanionOverlay zones', () {
    for (final config in const [
      GestureTimingConfig(),
      GestureTimingConfig(bottomZoneFraction: 0.25),
    ]) {
      testWidgets('are drawn where the classifier puts them (bottom zone '
          '${config.bottomZoneFraction})', (tester) async {
        final classifier = FakeGestureClassifier(config: config);
        final zones = ZoneLayout(_surface, config);

        await tester.pumpWidget(_buildOverlay(classifier));

        // The bottom-zone label is centred in the bottom zone ...
        final submit = tester.getCenter(find.text('SUBMIT'));
        expect(submit.dy, (zones.bottomZoneTop + _surface.height) / 2);

        // ... and the dot/dash labels in the halves above it.
        final dot = tester.getCenter(find.text('DOT'));
        final dash = tester.getCenter(find.text('DASH'));
        expect(dot.dx, zones.midX / 2);
        expect(dash.dx, zones.midX * 3 / 2);
        expect(dot.dy, zones.bottomZoneTop / 2);
        expect(dash.dy, zones.bottomZoneTop / 2);

        await tester.pumpWidget(const SizedBox());
        classifier.dispose();
      });
    }
  });
}
