import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/session/session_state.dart';
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

// Gesture events that arrive while the app is in the background must not
// restart the teaching loop or play feedback (issue #14).

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// The pause between pattern repetitions (the production default).
final _repeatPause = const TeachingTimingConfig().repeatPause;

/// Long enough for the teaching loop to have repeated several times.
final _severalRepeatCycles = _repeatPause * 4;

/// Well past the classifier's default silence timeout.
final _afterSilence = Duration(
  milliseconds: const GestureTimingConfig().silenceTimeout * 2,
);

/// Builds a [ProviderScope] with test overrides and [TouchSurface] as child.
Widget buildTestWidget({
  required GestureClassifier classifier,
  required MockVibrationService vibration,
  required FakeShakeDetector shake,
}) {
  return ProviderScope(
    overrides: [
      gestureClassifierProvider.overrideWithValue(classifier),
      vibrationServiceProvider.overrideWithValue(vibration),
      shakeDetectorProvider.overrideWithValue(shake),
    ],
    child: const MaterialApp(home: TouchSurface()),
  );
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TouchSurface)));

/// Whether the teaching orchestrator behind the [TouchSurface] is running.
bool isTeachingRunning(WidgetTester tester) =>
    _container(tester).read(teachingOrchestratorProvider).isRunning;

/// The current learning session state.
SessionState sessionState(WidgetTester tester) =>
    _container(tester).read(sessionNotifierProvider);

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
    await _container(tester).read(teachingOrchestratorProvider.notifier).stop();
  }

  // Replace widget tree to trigger dispose.
  await tester.pumpWidget(const SizedBox());

  // Flush any lingering Future.delayed timer from the orchestrator's loop.
  await tester.pump(_repeatPause);
}

/// Every event that would restart the loop if handled.
const _navigationEvents = <GestureEvent>[
  NavigateNext(),
  NavigatePrevious(),
  Reset(),
  NavigateUp(),
  NavigateDown(),
  Home(),
];

void main() {
  group('gestures while backgrounded', () {
    testWidgets('a shake does not restart the loop in the background', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      final shake = FakeShakeDetector();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          shake: shake,
        ),
      );
      await tester.pump();
      final firstPattern = vibration.patterns.single;

      await sendToBackground(tester);
      expect(shake.isPaused, isTrue);
      vibration.reset();

      shake.addEvent(const Home());
      await tester.pump(_severalRepeatCycles);

      expect(vibration.calls, isEmpty);
      expect(isTeachingRunning(tester), isFalse);

      // Back in the foreground the loop and shake detection resume.
      await bringToForeground(tester);
      expect(shake.isPaused, isFalse);
      expect(isTeachingRunning(tester), isTrue);
      expect(vibration.patterns, [firstPattern]);

      await cleanUp(tester);
      classifier.dispose();
      shake.dispose();
    });

    testWidgets('swipes, resets and navigation are ignored in the background', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      final shake = FakeShakeDetector();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          shake: shake,
        ),
      );
      await tester.pump();

      await sendToBackground(tester);
      final sessionBefore = sessionState(tester);
      vibration.reset();

      for (final event in _navigationEvents) {
        classifier.addEvent(event);
        await tester.pump();
      }
      await tester.pump(_severalRepeatCycles);

      expect(vibration.calls, isEmpty);
      expect(isTeachingRunning(tester), isFalse);
      expect(sessionState(tester), sessionBefore);

      await bringToForeground(tester);
      await cleanUp(tester);
      classifier.dispose();
      shake.dispose();
    });

    testWidgets(
      'a half-entered pattern is not judged in the background or on resume',
      (tester) async {
        // Real classifier so its silence timer actually runs.
        final classifier = GestureClassifier(screenWidth: 800);
        // The listener ends when the classifier is disposed and its stream
        // closes. (Awaiting an explicit cancel() here hangs the test.)
        final events = <GestureEvent>[];
        classifier.events.listen(events.add);
        final vibration = MockVibrationService();
        final shake = FakeShakeDetector();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pumpWidget(
          buildTestWidget(
            classifier: classifier,
            vibration: vibration,
            shake: shake,
          ),
        );
        await tester.pump();
        final firstPattern = vibration.patterns.single;

        // Tap one dot (left half, above the bottom zone), then background
        // the app before the silence timeout completes the input.
        final size = tester.getSize(find.byType(TouchSurface));
        await tester.tapAt(Offset(size.width / 4, size.height / 4));
        await tester.pump();
        expect(events, [const MorseInput(MorseSignal.dot)]);

        await sendToBackground(tester);
        expect(classifier.inputBufferNotifier.value, isEmpty);
        vibration.reset();

        await tester.pump(_afterSilence);
        expect(events.whereType<InputComplete>(), isEmpty);
        expect(vibration.calls, isEmpty);

        // After resume the stale dot is not judged either.
        await bringToForeground(tester);
        await tester.pump(_afterSilence);
        expect(events.whereType<InputComplete>(), isEmpty);
        expect(vibration.callLog, isNot(contains('playSuccess')));
        expect(vibration.callLog, isNot(contains('playError')));
        expect(vibration.patterns.first, firstPattern);

        await cleanUp(tester);
        classifier.dispose();
        shake.dispose();
      },
    );
  });
}
