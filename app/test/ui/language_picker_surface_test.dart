import 'dart:async';

import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/ui/vibration_gate.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_vibration_capability_probe.dart';
import '../test_doubles/mock_vibration_service.dart';

/// Long repeat pause to prevent orchestrator from interfering.
const _testRepeatPause = Duration(seconds: 5);

/// Builds the [LanguagePickerSurface], behind the app's [VibrationGate],
/// with [probe] answering the capability queries. When [probe] is null, the
/// real (device) probe is used.
Widget buildTestWidget({
  required FakeGestureClassifier classifier,
  required MockVibrationService vibration,
  VibrationCapabilityProbe? probe,
}) {
  return ProviderScope(
    overrides: [
      gestureClassifierProvider.overrideWithValue(classifier),
      vibrationServiceProvider.overrideWithValue(vibration),
      shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
      teachingTimingConfigProvider.overrideWithValue(
        const TeachingTimingConfig(repeatPause: _testRepeatPause),
      ),
      if (probe != null)
        vibrationCapabilityProbeProvider.overrideWithValue(probe),
    ],
    child: MaterialApp(
      builder: (_, navigator) => VibrationGate(child: navigator!),
      home: const LanguagePickerSurface(),
    ),
  );
}

/// Reads the provider container behind the widget under test.
ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

/// Holds a finger on the picker long enough to start the highlighted
/// language, lifts it, then lets the identifier and the default
/// post-feedback pause after it pass, so the session opens.
Future<void> holdToStart(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(LanguagePickerSurface)),
  );
  await tester.pump(LanguagePickerSurface.confirmHoldDuration);
  await gesture.up();
  await tester.pump(const TeachingTimingConfig().postFeedbackPause);
}

/// Cleanly tears down the widget tree, stopping the teaching loop if a
/// session was started.
Future<void> cleanUp(WidgetTester tester) async {
  if (find.byType(TouchSurface).evaluate().isNotEmpty) {
    await containerOf(
      tester,
    ).read(teachingOrchestratorProvider.notifier).stop();
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(_testRepeatPause);
}

void main() {
  group('LanguagePickerSurface vibration gate', () {
    testWidgets('shows the no-vibration screen when there is no motor', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          probe: FakeVibrationCapabilityProbe(vibrator: false),
        ),
      );
      await tester.pump();

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.text('No vibration motor'), findsOneWidget);
      expect(find.text('English'), findsNothing);
      expect(find.text('Русский'), findsNothing);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('does not start a session when there is no motor', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          probe: FakeVibrationCapabilityProbe(vibrator: false),
        ),
      );
      await tester.pump();

      // Tapping anywhere on the screen does nothing.
      await tester.tap(find.byType(NoVibrationScreen), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(TouchSurface), findsNothing);
      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(vibration.calls, isEmpty);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('ignores a tap that lands before the switch to the '
        'no-vibration screen', (tester) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      final gate = Completer<void>();

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          probe: FakeVibrationCapabilityProbe(vibrator: false, gate: gate),
        ),
      );
      expect(find.text('English'), findsOneWidget);

      // Detection finishes, but the picker has not been rebuilt yet.
      gate.complete();
      await containerOf(tester).read(vibrationCapabilitiesProvider.future);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.byType(TouchSurface), findsNothing);
      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(vibration.calls, isEmpty);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('shows the language buttons when the device can vibrate', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          probe: FakeVibrationCapabilityProbe(),
        ),
      );
      await tester.pump();

      expect(find.byType(NoVibrationScreen), findsNothing);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('shows the language buttons while detection is running', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();
      final gate = Completer<void>();

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          probe: FakeVibrationCapabilityProbe(gate: gate),
        ),
      );
      await tester.pump();

      expect(
        containerOf(tester).read(vibrationCapabilitiesProvider).isLoading,
        isTrue,
      );
      expect(find.byType(NoVibrationScreen), findsNothing);
      expect(find.text('English'), findsOneWidget);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('shows the language buttons when detection fails', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          probe: FakeVibrationCapabilityProbe(error: Exception('no plugin')),
        ),
      );
      await tester.pump();

      expect(find.byType(NoVibrationScreen), findsNothing);
      expect(find.text('English'), findsOneWidget);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('shows the language buttons without a probe override', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(classifier: classifier, vibration: vibration),
      );
      await tester.pump();

      expect(find.byType(NoVibrationScreen), findsNothing);
      expect(find.text('English'), findsOneWidget);

      await cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('starts a session when the device can vibrate', (tester) async {
      final classifier = FakeGestureClassifier();
      final vibration = MockVibrationService();

      await tester.pumpWidget(
        buildTestWidget(
          classifier: classifier,
          vibration: vibration,
          probe: FakeVibrationCapabilityProbe(amplitudeControl: false),
        ),
      );
      await tester.pump();

      // Tap highlights Russian; the hold starts it.
      await tester.tap(find.text('Русский'));
      await tester.pump();
      expect(find.byType(TouchSurface), findsNothing);
      await holdToStart(tester);
      await tester.pump();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(
        containerOf(tester).read(sessionNotifierProvider).language,
        MorseLanguage.russian,
      );
      expect(vibration.calls.first.type, VibrationCallType.playMorsePattern);

      await cleanUp(tester);
      classifier.dispose();
    });
  });
}
