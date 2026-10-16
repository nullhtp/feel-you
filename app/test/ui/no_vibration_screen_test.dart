import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/ui/vibration_diagnostics.dart';
import 'package:feel_you/ui/vibration_gate.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_vibration_capability_probe.dart';
import '../test_doubles/mock_vibration_service.dart';

/// Long repeat pause to prevent orchestrator from interfering.
const _testRepeatPause = Duration(seconds: 5);

/// The debug-only bypass button.
final _bypassButton = find.widgetWithText(
  OutlinedButton,
  noVibrationBypassLabel,
);

/// Pumps the [LanguagePickerSurface] behind the app's [VibrationGate] on a
/// device without a vibration motor (amplitude control and custom patterns
/// still reported as present).
Future<void> _pumpMotorlessPicker(
  WidgetTester tester,
  FakeGestureClassifier classifier,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gestureClassifierProvider.overrideWithValue(classifier),
        vibrationServiceProvider.overrideWithValue(MockVibrationService()),
        shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
        teachingTimingConfigProvider.overrideWithValue(
          const TeachingTimingConfig(repeatPause: _testRepeatPause),
        ),
        vibrationCapabilityProbeProvider.overrideWithValue(
          FakeVibrationCapabilityProbe(vibrator: false),
        ),
      ],
      child: MaterialApp(
        builder: (_, navigator) => VibrationGate(child: navigator!),
        home: const LanguagePickerSurface(),
      ),
    ),
  );
  await tester.pump();
}

/// Reads the provider container behind the widget under test.
ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

/// Stops the teaching loop if a session was started, then tears down the
/// widget tree.
Future<void> _cleanUp(WidgetTester tester) async {
  if (find.byType(TouchSurface).evaluate().isNotEmpty) {
    await _containerOf(
      tester,
    ).read(teachingOrchestratorProvider.notifier).stop();
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(_testRepeatPause);
}

void main() {
  group('NoVibrationScreen debug bypass', () {
    // Tests always run in debug mode (kDebugMode is true), so the button is
    // there. Release and profile builds compile it out: both the button and
    // the bypass in effectiveVibrationCapabilitiesProvider are guarded by
    // the compile-time constant kDebugMode.
    setUp(() => expect(kDebugMode, isTrue));

    testWidgets('shows a labelled bypass button', (tester) async {
      final classifier = FakeGestureClassifier();
      await _pumpMotorlessPicker(tester, classifier);

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(_bypassButton, findsOneWidget);
      expect(
        tester.getSemantics(_bypassButton),
        matchesSemantics(
          isButton: true,
          label: noVibrationBypassLabel,
          hint: 'Opens the language picker although nothing will vibrate',
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await _cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('keeps the gate closed until the button is tapped', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      await _pumpMotorlessPicker(tester, classifier);
      await tester.pumpAndSettle();

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.text('English'), findsNothing);
      expect(_containerOf(tester).read(vibrationGateBypassProvider), isFalse);
      expect(
        _containerOf(
          tester,
        ).read(effectiveVibrationCapabilitiesProvider).canVibrate,
        isFalse,
      );

      await _cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('opens the gate when tapped', (tester) async {
      final classifier = FakeGestureClassifier();
      await _pumpMotorlessPicker(tester, classifier);

      await tester.tap(_bypassButton);
      await tester.pump();

      final container = _containerOf(tester);
      expect(container.read(vibrationGateBypassProvider), isTrue);
      expect(
        container.read(effectiveVibrationCapabilitiesProvider).canVibrate,
        isTrue,
      );
      // The device's real answer is unchanged.
      expect(
        container.read(vibrationCapabilitiesProvider).requireValue.hasVibrator,
        isFalse,
      );
      expect(find.byType(NoVibrationScreen), findsNothing);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);

      await _cleanUp(tester);
      classifier.dispose();
    });

    testWidgets('lets a session start, with the real capabilities and the '
        'bypass marker in the overlay', (tester) async {
      final classifier = FakeGestureClassifier();
      await _pumpMotorlessPicker(tester, classifier);

      await tester.tap(_bypassButton);
      await tester.pump();
      // Tap highlights English; holding anywhere starts it.
      await tester.tap(find.text('English'));
      await tester.pump();
      final hold = await tester.startGesture(
        tester.getCenter(find.byType(LanguagePickerSurface)),
      );
      await tester.pump(LanguagePickerSurface.confirmHoldDuration);
      await hold.up();
      await tester.pump();
      await tester.pump();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CompanionOverlay),
          matching: find.text(
            'Vibration: NONE · amplitude: yes · custom: yes'
            ' · $vibrationGateBypassedMarker',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byType(VibrationDiagnostics),
                matching: find.byType(Text),
              ),
            )
            .style
            ?.color,
        Colors.amber,
      );

      await _cleanUp(tester);
      classifier.dispose();
    });
  });
}
