import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// The pause between pattern repetitions (the production default).
final _repeatPause = const TeachingTimingConfig().repeatPause;

/// Long enough for the teaching loop to have repeated several times.
final _severalRepeatCycles = _repeatPause * 4;

/// The pigeon channel `WakelockPlus.toggle` sends its requests on.
const _wakelockToggleChannel =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.'
    'WakelockPlusApi.toggle';

/// Decodes wakelock_plus pigeon messages, where a `ToggleMessage` is a
/// custom type wrapping the list `[enable]`.
class _WakelockMessageCodec extends StandardMessageCodec {
  const _WakelockMessageCodec();

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    if (type >= 128) return readValue(buffer);
    return super.readValueOfType(type, buffer);
  }
}

/// Mocks the wakelock platform channel and returns the list of requested
/// wakelock states (`true` = enable, `false` = disable) in call order.
List<bool> mockWakelock(WidgetTester tester) {
  const codec = _WakelockMessageCodec();
  final toggles = <bool>[];
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    _wakelockToggleChannel,
    (message) async {
      final args = codec.decodeMessage(message)! as List<Object?>;
      final toggleMessage = args.first! as List<Object?>;
      toggles.add(toggleMessage.first! as bool);
      return codec.encodeMessage(<Object?>[]);
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      _wakelockToggleChannel,
      null,
    ),
  );
  return toggles;
}

/// Builds a [ProviderScope] with test overrides and [TouchSurface] as child.
Widget buildTestWidget({
  required GestureClassifier classifier,
  required MockVibrationService vibration,
}) {
  return ProviderScope(
    overrides: [
      gestureClassifierProvider.overrideWithValue(classifier),
      vibrationServiceProvider.overrideWithValue(vibration),
      shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
    ],
    child: const MaterialApp(home: TouchSurface()),
  );
}

/// Whether the teaching orchestrator behind the [TouchSurface] is running.
bool isTeachingRunning(WidgetTester tester) {
  final element = tester.element(find.byType(TouchSurface));
  final container = ProviderScope.containerOf(element);
  return container.read(teachingOrchestratorProvider).isRunning;
}

/// Simulates the app leaving the foreground, stepping through every
/// intermediate state like the engine does.
Future<void> sendToBackground(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

/// Simulates the app returning to the foreground, stepping through every
/// intermediate state like the engine does.
Future<void> bringToForeground(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

/// Cleanly tears down the widget: stops the orchestrator, flushes timers,
/// and removes the widget tree.
Future<void> cleanUp(WidgetTester tester) async {
  final finder = find.byType(TouchSurface);
  if (finder.evaluate().isNotEmpty) {
    final element = tester.element(finder);
    final container = ProviderScope.containerOf(element);
    await container.read(teachingOrchestratorProvider.notifier).stop();
  }

  // Replace widget tree to trigger dispose.
  await tester.pumpWidget(const SizedBox());

  // Flush any lingering Future.delayed timer from the orchestrator's loop.
  await tester.pump(_repeatPause);
}

void main() {
  group('app lifecycle', () {
    testWidgets('backgrounding cancels vibration and stops the repeat loop', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );
      await tester.pump();

      // The loop plays the pattern and repeats it after each pause.
      expect(vibration.patterns, hasLength(1));
      await tester.pump(_repeatPause);
      expect(vibration.patterns, hasLength(2));

      vibration.reset();
      await sendToBackground(tester);

      expect(vibration.callLog, ['cancel']);
      expect(isTeachingRunning(tester), isFalse);

      // Nothing else vibrates while backgrounded.
      vibration.reset();
      await tester.pump(_severalRepeatCycles);
      expect(vibration.calls, isEmpty);
      expect(isTeachingRunning(tester), isFalse);

      await bringToForeground(tester);
      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('resuming replays the current character from the start', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );
      await tester.pump();
      final firstPattern = vibration.patterns.single;

      await sendToBackground(tester);
      await tester.pump(_severalRepeatCycles);
      vibration.reset();

      await bringToForeground(tester);

      expect(isTeachingRunning(tester), isTrue);
      expect(vibration.patterns, [firstPattern]);

      // The loop keeps repeating after the resume.
      await tester.pump(_repeatPause);
      expect(vibration.patterns, [firstPattern, firstPattern]);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('going inactive alone (e.g. an incoming call) stops the loop', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );
      await tester.pump();

      vibration.reset();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(vibration.callLog, ['cancel']);
      expect(isTeachingRunning(tester), isFalse);

      await tester.pump(_severalRepeatCycles);
      expect(vibration.callLog, ['cancel']);

      vibration.reset();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(isTeachingRunning(tester), isTrue);
      expect(vibration.patterns, hasLength(1));

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('survives repeated background/foreground cycles', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );
      await tester.pump();

      for (var cycle = 0; cycle < 3; cycle++) {
        vibration.reset();
        await sendToBackground(tester);
        await tester.pump(_severalRepeatCycles);
        expect(vibration.callLog, ['cancel'], reason: 'cycle $cycle');

        vibration.reset();
        await bringToForeground(tester);
        expect(vibration.patterns, hasLength(1), reason: 'cycle $cycle');
        expect(isTeachingRunning(tester), isTrue, reason: 'cycle $cycle');
      }

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets(
      'a resumed notification without a prior pause does not restart',
      (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(classifier: classifier, vibration: vibration),
        );
        await tester.pump();
        expect(vibration.patterns, hasLength(1));

        vibration.reset();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        expect(vibration.calls, isEmpty);
        expect(isTeachingRunning(tester), isTrue);

        await cleanUp(tester);
        classifier.dispose();
      },
    );

    testWidgets(
      'releases the wakelock in the background and re-acquires it on resume',
      (tester) async {
        final wakelockToggles = mockWakelock(tester);
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pumpWidget(
          buildTestWidget(classifier: classifier, vibration: vibration),
        );
        await tester.pump();
        expect(wakelockToggles, [true]);

        await sendToBackground(tester);
        expect(wakelockToggles, [true, false]);

        await bringToForeground(tester);
        expect(wakelockToggles, [true, false, true]);

        await cleanUp(tester);
        classifier.dispose();
      },
    );

    testWidgets(
      'a press held while backgrounding is abandoned, not classified',
      (tester) async {
        // Real classifier so its long-hold (reset) timer actually runs.
        final classifier = GestureClassifier(screenWidth: 800);
        // The listener ends when the classifier is disposed and its stream
        // closes. (Awaiting an explicit cancel() here hangs the test.)
        final events = <GestureEvent>[];
        classifier.events.listen(events.add);
        final vibration = MockVibrationService();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pumpWidget(
          buildTestWidget(classifier: classifier, vibration: vibration),
        );
        await tester.pump();

        // Finger goes down, then the app is backgrounded mid-press.
        final center = tester.getCenter(find.byType(TouchSurface));
        final gesture = await tester.startGesture(center);
        await sendToBackground(tester);
        vibration.reset();

        // Well past the long-hold threshold: no Reset fires, so the loop
        // is not restarted in the background.
        await tester.pump(_severalRepeatCycles);
        expect(events, isEmpty);
        expect(vibration.calls, isEmpty);
        expect(isTeachingRunning(tester), isFalse);

        await bringToForeground(tester);
        expect(vibration.patterns, hasLength(1));

        // The stale release of the old pointer is ignored.
        await gesture.up();
        await tester.pump();
        expect(events, isEmpty);

        await cleanUp(tester);
        classifier.dispose();
      },
    );
  });
}
