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

/// Classifier thresholds (production defaults).
const _timing = GestureTimingConfig();

/// Well past both the silence timeout and the long-hold (reset) threshold,
/// so any event a cancelled press could cause has had time to fire.
final _pastAllTimers = Duration(
  milliseconds: _timing.resetMinDuration + _timing.silenceTimeout + 500,
);

/// Pumps a [TouchSurface] backed by the real [GestureClassifier] and returns
/// every [GestureEvent] it emits.
///
/// The default test surface is 800x600, so x < 400 is a dot and y >= 510 is
/// the bottom zone.
Future<List<GestureEvent>> pumpSurface(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        screenWidthProvider.overrideWithValue(800),
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
  final events = <GestureEvent>[];
  // Cancelled in tear-down: awaiting cancel() inside the fake-async test
  // body stalls the next await.
  final subscription = container
      .read(gestureClassifierProvider)
      .events
      .listen(events.add);
  addTearDown(subscription.cancel);
  return events;
}

/// Stops the orchestrator, disposes the tree (and with it the classifier)
/// and flushes the orchestrator's pending repeat pause.
Future<void> cleanUp(WidgetTester tester) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(TouchSurface)),
  );
  await container.read(teachingOrchestratorProvider.notifier).stop();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(_testRepeatPause);
}

void main() {
  group('a pointer cancelled by the system is not classified', () {
    testWidgets('short press on the left half emits no dot', (tester) async {
      final events = await pumpSurface(tester);

      final gesture = await tester.startGesture(const Offset(100, 300));
      await gesture.cancel();
      await tester.pump(_pastAllTimers);

      expect(events, isEmpty);

      await cleanUp(tester);
    });

    testWidgets('short press on the right half emits no dash', (tester) async {
      final events = await pumpSurface(tester);

      final gesture = await tester.startGesture(const Offset(700, 300));
      await gesture.cancel();
      await tester.pump(_pastAllTimers);

      expect(events, isEmpty);

      await cleanUp(tester);
    });

    testWidgets(
      'horizontal swipe distance (edge back gesture) emits no navigation',
      (tester) async {
        final events = await pumpSurface(tester);

        // Control: the same movement released normally is a swipe.
        final swipe = await tester.startGesture(const Offset(10, 300));
        await swipe.moveBy(const Offset(300, 0));
        await swipe.up();
        await tester.pump();
        expect(events, [const NavigateNext()]);
        events.clear();

        final cancelled = await tester.startGesture(const Offset(10, 300));
        await cancelled.moveBy(const Offset(300, 0));
        await cancelled.cancel();
        await tester.pump(_pastAllTimers);

        expect(events, isEmpty);

        await cleanUp(tester);
      },
    );

    testWidgets(
      'vertical swipe distance (notification shade) emits no navigation',
      (tester) async {
        final events = await pumpSurface(tester);

        final gesture = await tester.startGesture(const Offset(100, 5));
        await gesture.moveBy(const Offset(0, 300));
        await gesture.cancel();
        await tester.pump(_pastAllTimers);

        expect(events, isEmpty);

        await cleanUp(tester);
      },
    );

    testWidgets('long hold cancelled before the threshold emits no Reset', (
      tester,
    ) async {
      final events = await pumpSurface(tester);

      final gesture = await tester.startGesture(const Offset(100, 300));
      await tester.pump(Duration(milliseconds: _timing.resetMinDuration ~/ 2));
      await gesture.cancel();
      await tester.pump(_pastAllTimers);

      expect(events, isEmpty);

      await cleanUp(tester);
    });

    testWidgets('press in the bottom zone emits no BottomZoneAction', (
      tester,
    ) async {
      final events = await pumpSurface(tester);

      final gesture = await tester.startGesture(const Offset(100, 590));
      await gesture.cancel();
      await tester.pump(_pastAllTimers);

      expect(events, isEmpty);

      await cleanUp(tester);
    });

    testWidgets('input entered before the cancelled press still completes', (
      tester,
    ) async {
      final events = await pumpSurface(tester);

      await tester.tapAt(const Offset(100, 300));
      await tester.pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);

      final gesture = await tester.startGesture(const Offset(700, 300));
      await gesture.cancel();
      await tester.pump(_pastAllTimers);

      expect(events, [
        const MorseInput(MorseSignal.dot),
        const InputComplete([Signal(MorseSignal.dot)]),
      ]);

      await cleanUp(tester);
    });
  });
}
