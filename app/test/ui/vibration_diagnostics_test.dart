import 'dart:async';

import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/ui/vibration_diagnostics.dart';
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

/// Pumps a bare [VibrationDiagnostics] inside a [Stack], with [probe]
/// answering the capability queries.
Future<void> pumpDiagnostics(
  WidgetTester tester,
  VibrationCapabilityProbe probe,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [vibrationCapabilityProbeProvider.overrideWithValue(probe)],
      child: const MaterialApp(home: Stack(children: [VibrationDiagnostics()])),
    ),
  );
  await tester.pump();
}

/// The colour of the diagnostics readout.
Color? readoutColor(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byType(VibrationDiagnostics),
        matching: find.byType(Text),
      ),
    )
    .style
    ?.color;

void main() {
  group('describeVibrationCapabilities', () {
    test('formats every capability', () {
      expect(
        describeVibrationCapabilities(
          const VibrationCapabilities(
            hasVibrator: true,
            hasAmplitudeControl: false,
            hasCustomVibrationsSupport: true,
          ),
        ),
        'Vibration: OK · amplitude: no · custom: yes',
      );
    });

    test('reports a missing motor', () {
      expect(
        describeVibrationCapabilities(
          const VibrationCapabilities(
            hasVibrator: false,
            hasAmplitudeControl: false,
            hasCustomVibrationsSupport: false,
          ),
        ),
        'Vibration: NONE · amplitude: no · custom: no',
      );
    });

    test('reports unknown capabilities', () {
      expect(
        describeVibrationCapabilities(VibrationCapabilities.unknown),
        'Vibration: unknown · amplitude: unknown · custom: unknown',
      );
    });
  });

  group('VibrationDiagnostics', () {
    testWidgets('renders detected capabilities', (tester) async {
      await pumpDiagnostics(
        tester,
        FakeVibrationCapabilityProbe(amplitudeControl: false),
      );

      expect(
        find.text('Vibration: OK · amplitude: no · custom: yes'),
        findsOneWidget,
      );
    });

    testWidgets('highlights a missing capability', (tester) async {
      await pumpDiagnostics(
        tester,
        FakeVibrationCapabilityProbe(customVibrations: false),
      );
      expect(
        find.text('Vibration: OK · amplitude: yes · custom: no'),
        findsOneWidget,
      );
      expect(readoutColor(tester), Colors.amber);
    });

    testWidgets('stays dim when everything works', (tester) async {
      await pumpDiagnostics(tester, FakeVibrationCapabilityProbe());
      expect(
        find.text('Vibration: OK · amplitude: yes · custom: yes'),
        findsOneWidget,
      );
      expect(readoutColor(tester), isNot(Colors.amber));
    });

    testWidgets('renders unknown when detection fails', (tester) async {
      await pumpDiagnostics(
        tester,
        FakeVibrationCapabilityProbe(error: Exception('no plugin')),
      );
      expect(
        find.text('Vibration: unknown · amplitude: unknown · custom: unknown'),
        findsOneWidget,
      );
    });

    testWidgets('shows the real capabilities and a marker while the gate '
        'is bypassed', (tester) async {
      await pumpDiagnostics(
        tester,
        FakeVibrationCapabilityProbe(vibrator: false),
      );
      ProviderScope.containerOf(
        tester.element(find.byType(VibrationDiagnostics)),
      ).read(vibrationGateBypassProvider.notifier).bypass();
      await tester.pump();

      expect(
        find.text(
          'Vibration: NONE · amplitude: yes · custom: yes'
          ' · $vibrationGateBypassedMarker',
        ),
        findsOneWidget,
      );
      expect(readoutColor(tester), Colors.amber);
    });

    testWidgets('shows that detection is still running', (tester) async {
      await pumpDiagnostics(
        tester,
        FakeVibrationCapabilityProbe(gate: Completer<void>()),
      );
      expect(find.text(vibrationDiagnosticsCheckingLabel), findsOneWidget);
    });

    testWidgets('is part of the companion overlay', (tester) async {
      final classifier = FakeGestureClassifier();
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
              FakeVibrationCapabilityProbe(amplitudeControl: false),
            ),
          ],
          child: const MaterialApp(home: TouchSurface()),
        ),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(CompanionOverlay),
          matching: find.text('Vibration: OK · amplitude: no · custom: yes'),
        ),
        findsOneWidget,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TouchSurface)),
      );
      await container.read(teachingOrchestratorProvider.notifier).stop();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(_testRepeatPause);
      classifier.dispose();
    });
  });
}
