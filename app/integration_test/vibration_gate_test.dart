import 'dart:async';
import 'dart:io' show Platform;

import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/ui/vibration_diagnostics.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// The vibration gate end to end (`vibration-capability-gate`).

/// Whether this runs on the iOS simulator, which has no vibration motor.
///
/// The app sees no environment there, but it runs from the simulator's
/// own folder.
bool get _onIosSimulator =>
    Platform.isIOS && Platform.resolvedExecutable.contains('/CoreSimulator/');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RecordingVibrationService vibration;
  late E2EApp app;

  Future<void> launch(WidgetTester tester, MorseLanguage? savedLanguage) {
    vibration = RecordingVibrationService();
    app = E2EApp(savedLanguage: savedLanguage, vibration: vibration);
    return app.launch(tester);
  }

  Future<void> waitForDetection(WidgetTester tester) => waitUntil(
    tester,
    () => app.container(tester).read(vibrationCapabilitiesProvider).hasValue,
    reason: 'detection ends',
  );

  bool shown(Type screen) => find.byType(screen).evaluate().isNotEmpty;

  for (final savedLanguage in [null, MorseLanguage.english]) {
    final firstScreen = savedLanguage == null ? 'the picker' : 'the lessons';

    testWidgets("with the device's own answers, the gate decides whether "
        '$firstScreen may open', (tester) async {
      // No FakeVibrationPlatform: the device answers for itself.
      await launch(tester, savedLanguage);
      await waitForDetection(tester);
      await tester.pump();
      final detected = app
          .container(tester)
          .read(vibrationCapabilitiesProvider)
          .value!;

      if (_onIosSimulator) {
        expect(
          detected.hasVibrator,
          isFalse,
          reason: 'the iOS simulator has no vibration motor',
        );
      }

      if (detected.canVibrate) {
        expect(find.byType(NoVibrationScreen), findsNothing);
        expect(
          find.byType(
            savedLanguage == null ? LanguagePickerSurface : TouchSurface,
          ),
          findsOneWidget,
        );
      } else {
        await waitUntil(
          tester,
          () => shown(NoVibrationScreen),
          reason: 'the No vibration screen replaces $firstScreen',
        );
        expect(find.text('No vibration motor'), findsOneWidget);
        expect(find.byType(LanguagePickerSurface), findsNothing);
        expect(find.byType(TouchSurface), findsNothing);
        expect(app.isTeachingRunning(tester), isFalse);
        // The picker waits for detection, so it never played its
        // identifier.
        if (savedLanguage == null) expect(vibration.patterns, isEmpty);
      }

      await app.close(tester);
    });

    testWidgets(
      'the debug button on the No vibration screen opens $firstScreen',
      (tester) async {
        FakeVibrationPlatform(hasVibrator: false).install(tester);
        await launch(tester, savedLanguage);
        await waitUntil(
          tester,
          () => shown(NoVibrationScreen),
          reason: 'the No vibration screen is shown',
        );

        await tester.tap(find.text(noVibrationBypassLabel));
        await tester.pump();
        final opened = savedLanguage == null
            ? LanguagePickerSurface
            : TouchSurface;
        await waitUntil(
          tester,
          () => shown(opened),
          reason: 'the bypass opens $firstScreen',
        );
        expect(find.byType(NoVibrationScreen), findsNothing);

        if (savedLanguage != null) {
          expect(app.isTeachingRunning(tester), isTrue);
          // The helper's readout still shows the real answer.
          expect(find.textContaining('Vibration: NONE'), findsOneWidget);
          expect(
            find.textContaining(vibrationGateBypassedMarker),
            findsOneWidget,
          );
        }

        await app.close(tester);
      },
      skip: !kDebugMode,
    );
  }

  testWidgets('a detection that ends after a language was started replaces '
      'the lessons and stops the loop', (tester) async {
    final detection = Completer<void>();
    FakeVibrationPlatform(
      hasVibrator: false,
      answersAfter: detection.future,
    ).install(tester);
    await launch(tester, null);
    expect(find.byType(LanguagePickerSurface), findsOneWidget);
    await waitFor(tester, const Duration(milliseconds: 300));
    // Still detecting: the picker has not announced itself.
    expect(vibration.patterns, isEmpty);

    // Hold anywhere for 1 s to start the highlighted language, English.
    final finger = await tester.startGesture(
      tester.getCenter(find.byType(LanguagePickerSurface)),
    );
    await waitFor(
      tester,
      LanguagePickerSurface.confirmHoldDuration +
          const Duration(milliseconds: 200),
    );
    await finger.up();
    await waitUntil(
      tester,
      () => shown(TouchSurface) && app.isTeachingRunning(tester),
      reason: 'the lessons open and the loop runs',
    );

    detection.complete();
    await waitUntil(
      tester,
      () => shown(NoVibrationScreen),
      reason: 'the late detection closes the gate',
    );
    expect(find.byType(TouchSurface), findsNothing);
    expect(app.isTeachingRunning(tester), isFalse);

    await app.close(tester);
  });
}
