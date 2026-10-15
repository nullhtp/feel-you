import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

/// Long enough not to fire during the test; flushed explicitly at the end.
const _testRepeatPause = Duration(seconds: 5);

void main() {
  testWidgets(
    'dot/dash midpoint follows a surface size change without recreating '
    'the classifier',
    (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(1000, 600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Reproduce the old failure mode: a startup width of 0 would have
            // turned every tap into a dash.
            screenWidthProvider.overrideWithValue(0),
            vibrationServiceProvider.overrideWithValue(MockVibrationService()),
            shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
            teachingTimingConfigProvider.overrideWithValue(
              const TeachingTimingConfig(repeatPause: _testRepeatPause),
            ),
          ],
          child: const MaterialApp(home: TouchSurface()),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TouchSurface)),
      );
      final classifier = container.read(gestureClassifierProvider);
      final orchestrator = container.read(
        teachingOrchestratorProvider.notifier,
      );

      final signals = <MorseSignal>[];
      // Cancelled in tear-down: awaiting cancel() inside the fake-async test
      // body resolves in the root zone and stalls the next await.
      final subscription = classifier.events.listen((event) {
        if (event is MorseInput) signals.add(event.signal);
      });
      addTearDown(subscription.cancel);

      // 1000 px wide: midpoint 500, so x=300 is a dot.
      await tester.tapAt(const Offset(300, 100));
      await tester.pump();
      expect(classifier.screenWidth, 1000);
      expect(signals, [MorseSignal.dot]);

      // Surface shrinks (e.g. split-screen): midpoint 250, x=300 is a dash.
      tester.view.physicalSize = const Size(500, 600);
      await tester.pump();

      await tester.tapAt(const Offset(300, 100));
      await tester.pump();
      expect(classifier.screenWidth, 500);
      expect(signals, [MorseSignal.dot, MorseSignal.dash]);

      // Same classifier and orchestrator: no subscription or buffer was lost.
      expect(container.read(gestureClassifierProvider), same(classifier));
      expect(
        container.read(teachingOrchestratorProvider.notifier),
        same(orchestrator),
      );

      await orchestrator.stop();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(_testRepeatPause);
    },
  );
}
