import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// The repeat pause used in tests. Must be long enough to not fire during
/// the test, but we flush it explicitly in tearDown.
const _testRepeatPause = Duration(seconds: 5);

/// Builds a [ProviderScope] with test overrides and [TouchSurface] as child.
Widget buildTestWidget({
  required FakeGestureClassifier classifier,
  required MockVibrationService vibration,
}) {
  return ProviderScope(
    overrides: [
      gestureClassifierProvider.overrideWithValue(classifier),
      vibrationServiceProvider.overrideWithValue(vibration),
      shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
      teachingTimingConfigProvider.overrideWithValue(
        const TeachingTimingConfig(repeatPause: _testRepeatPause),
      ),
    ],
    child: const MaterialApp(home: TouchSurface()),
  );
}

/// Cleanly tears down the widget: stops orchestrator, flushes timers,
/// and removes the widget tree.
Future<void> cleanUp(WidgetTester tester) async {
  // Stop the orchestrator if it's running.
  final finder = find.byType(TouchSurface);
  if (finder.evaluate().isNotEmpty) {
    final element = tester.element(finder);
    final container = ProviderScope.containerOf(element);
    await container.read(teachingOrchestratorProvider.notifier).stop();
  }

  // Replace widget tree to trigger dispose.
  await tester.pumpWidget(const SizedBox());

  // Flush the lingering Future.delayed timer from the orchestrator's loop.
  // The timer was created before stop() was called and cannot be cancelled,
  // but advancing past it clears it from the fake async zone.
  await tester.pump(_testRepeatPause);
}

void main() {
  // -------------------------------------------------------------------------
  // 5.1 Renders a full-screen black container
  // -------------------------------------------------------------------------
  group('rendering', () {
    testWidgets('renders a full-screen black Scaffold', (tester) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );

      // Find the Scaffold and verify its background color.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);

      // Verify there's a SizedBox.expand for full-screen coverage.
      expect(find.byType(SizedBox), findsOneWidget);

      await cleanUp(tester);
      classifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // 5.2 Pointer events forwarded to GestureClassifier
  // -------------------------------------------------------------------------
  group('pointer event forwarding', () {
    testWidgets(
      'pointer down event is forwarded as TouchDown with timestamp and x',
      (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(classifier: classifier, vibration: vibration),
        );

        // Simulate a pointer down event at a specific position.
        final center = tester.getCenter(find.byType(SizedBox));
        final downGesture = await tester.startGesture(center);

        expect(classifier.touchEvents, hasLength(1));
        final event = classifier.touchEvents.first;
        expect(event, isA<TouchDown>());
        final touchDown = event as TouchDown;
        expect(touchDown.position, center.dx);

        await downGesture.up();
        await cleanUp(tester);
        classifier.dispose();
      },
    );

    testWidgets(
      'pointer up event is forwarded as TouchUp with timestamp and x',
      (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(classifier: classifier, vibration: vibration),
        );

        final center = tester.getCenter(find.byType(SizedBox));
        final gesture = await tester.startGesture(center);
        await gesture.up();

        expect(classifier.touchEvents, hasLength(2));

        final downEvent = classifier.touchEvents[0];
        expect(downEvent, isA<TouchDown>());

        final upEvent = classifier.touchEvents[1];
        expect(upEvent, isA<TouchUp>());
        final touchUp = upEvent as TouchUp;
        expect(touchUp.position, center.dx);

        await cleanUp(tester);
        classifier.dispose();
      },
    );

    testWidgets(
      'only primary pointer events are forwarded (multi-touch ignored)',
      (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(classifier: classifier, vibration: vibration),
        );

        final center = tester.getCenter(find.byType(SizedBox));
        final offset2 = center + const Offset(50, 0);

        // First finger down.
        final finger1 = await tester.startGesture(center);

        // Second finger down — should be ignored.
        final finger2 = await tester.startGesture(offset2);

        // Only one TouchDown should have been recorded.
        expect(classifier.touchEvents, hasLength(1));
        expect(classifier.touchEvents.first, isA<TouchDown>());

        // Second finger up — should be ignored.
        await finger2.up();
        expect(classifier.touchEvents, hasLength(1));

        // First finger up — should be forwarded.
        await finger1.up();
        expect(classifier.touchEvents, hasLength(2));
        expect(classifier.touchEvents[1], isA<TouchUp>());

        await cleanUp(tester);
        classifier.dispose();
      },
    );

    testWidgets('pointer cancel is forwarded as TouchUp', (tester) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );

      final center = tester.getCenter(find.byType(SizedBox));
      final gesture = await tester.startGesture(center);

      expect(classifier.touchEvents, hasLength(1));
      expect(classifier.touchEvents.first, isA<TouchDown>());

      // Simulate a pointer cancel (e.g. system gesture intercept).
      await gesture.cancel();

      expect(classifier.touchEvents, hasLength(2));
      expect(classifier.touchEvents[1], isA<TouchUp>());

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('new primary pointer is accepted after previous one ends', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );

      final center = tester.getCenter(find.byType(SizedBox));

      // First gesture.
      final gesture1 = await tester.startGesture(center);
      await gesture1.up();

      expect(classifier.touchEvents, hasLength(2));

      // Second gesture — should be accepted as new primary.
      final gesture2 = await tester.startGesture(center);
      await gesture2.up();

      expect(classifier.touchEvents, hasLength(4));
      expect(classifier.touchEvents[2], isA<TouchDown>());
      expect(classifier.touchEvents[3], isA<TouchUp>());

      await cleanUp(tester);
      classifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // 5.3 PopScope prevents back navigation
  // -------------------------------------------------------------------------
  group('back navigation prevention', () {
    testWidgets('PopScope has canPop set to false', (tester) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, false);

      await cleanUp(tester);
      classifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // 5.4 Teaching orchestrator start/stop on mount/dispose
  // -------------------------------------------------------------------------
  group('teaching orchestrator lifecycle', () {
    testWidgets('orchestrator is started on mount', (tester) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );

      // Pump to trigger the post-frame callback.
      await tester.pump();

      // Read the orchestrator state from the widget's ProviderScope.
      final element = tester.element(find.byType(TouchSurface));
      final container = ProviderScope.containerOf(element);
      final state = container.read(teachingOrchestratorProvider);

      expect(state.isRunning, true);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('orchestrator is stopped on dispose', (tester) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );

      // Pump to start the orchestrator.
      await tester.pump();

      // Verify running before dispose.
      final element = tester.element(find.byType(TouchSurface));
      final container = ProviderScope.containerOf(element);
      expect(container.read(teachingOrchestratorProvider).isRunning, true);

      // Clean up — this stops orchestrator and disposes widget.
      await cleanUp(tester);

      // After dispose, the orchestrator's stop should have been called.
      // We verify via the vibration service — stop calls cancel.
      expect(vibration.callLog, contains('cancel'));

      classifier.dispose();
    });
  });
}
