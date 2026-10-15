import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_vibration_capability_probe.dart';
import '../test_doubles/mock_vibration_service.dart';

// A TouchSurface that is on its way out must not restart the loop, and
// removing one whose loop is still running must not modify a provider while
// the widget tree is being torn down (issue #23).

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

/// Identifier vibration of the picker for Arabic: Morse ع.
const _arabic = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dash,
];

/// Test doubles shared by the app and the surface-only harness.
class _Doubles {
  final classifier = FakeGestureClassifier();
  final vibration = MockVibrationService();
  final shake = FakeShakeDetector();

  List<Override> get overrides => [
    gestureClassifierProvider.overrideWithValue(classifier),
    vibrationServiceProvider.overrideWithValue(vibration),
    shakeDetectorProvider.overrideWithValue(shake),
    teachingTimingConfigProvider.overrideWithValue(
      const TeachingTimingConfig(repeatPause: _testRepeatPause),
    ),
    vibrationCapabilityProbeProvider.overrideWithValue(
      FakeVibrationCapabilityProbe(),
    ),
  ];

  /// Removes the tree, flushes the loop's timers and disposes the doubles.
  ///
  /// Deliberately does not stop the orchestrator first: tearing the tree
  /// down with the loop in any state must be safe.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);
    classifier.dispose();
    shake.dispose();
  }
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

bool _isTeachingRunning(WidgetTester tester) =>
    _container(tester).read(teachingOrchestratorProvider).isRunning;

/// Simulates the app leaving the foreground.
Future<void> _sendToBackground(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

/// Simulates the app returning to the foreground.
Future<void> _bringToForeground(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

void main() {
  group('double shake transition', () {
    testWidgets('a trip to the background during the transition does not '
        'restart the loop', (tester) async {
      final doubles = _Doubles();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...doubles.overrides,
            languagePreferenceStoreProvider.overrideWithValue(
              InMemoryLanguagePreferenceStore(MorseLanguage.arabic),
            ),
          ],
          child: const FeelYouApp(),
        ),
      );
      await tester.pump();
      expect(_isTeachingRunning(tester), isTrue);

      // The double shake stops the loop and starts the route transition.
      doubles.shake.addEvent(const ChangeLanguage());
      await tester.pump();
      expect(_isTeachingRunning(tester), isFalse);
      doubles.vibration.reset();

      // The notification shade (or a call) comes and goes before the picker
      // has finished sliding in.
      await _sendToBackground(tester);
      await _bringToForeground(tester);

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_isTeachingRunning(tester), isFalse);
      expect(doubles.shake.isPaused, isTrue);

      // The transition ends and the outgoing surface is disposed.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LanguagePickerSurface), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(_isTeachingRunning(tester), isFalse);
      // Only the picker's identifier played, not a lesson pattern.
      expect(doubles.vibration.patterns, [_arabic]);

      await doubles.close(tester);
    });
  });

  group('removing a surface whose loop is running', () {
    /// Shows a [TouchSurface] keyed by `surfaceKey` while `show` is true.
    Future<void> pumpSurface(
      WidgetTester tester,
      _Doubles doubles, {
      required ValueNotifier<bool> show,
      ValueNotifier<int>? surfaceKey,
    }) async {
      final key = surfaceKey ?? ValueNotifier(0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: doubles.overrides,
          child: MaterialApp(
            home: ListenableBuilder(
              listenable: Listenable.merge([show, key]),
              builder: (_, _) => show.value
                  ? TouchSurface(key: ValueKey(key.value))
                  : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('stops the loop without an error', (tester) async {
      final doubles = _Doubles();
      final show = ValueNotifier(true);
      await pumpSurface(tester, doubles, show: show);
      expect(_isTeachingRunning(tester), isTrue);
      expect(doubles.vibration.patterns, hasLength(1));
      doubles.vibration.reset();

      // Removed in a rebuild, with no stop() beforehand.
      show.value = false;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(TouchSurface), findsNothing);
      expect(doubles.vibration.callLog, ['cancel']);
      expect(_isTeachingRunning(tester), isFalse);
      expect(doubles.shake.isPaused, isTrue);

      // Nothing plays afterwards, and late gestures are ignored.
      doubles.classifier.addEvent(const NavigateNext());
      await tester.pump(_testRepeatPause * 3);
      expect(doubles.vibration.callLog, ['cancel']);
      expect(_isTeachingRunning(tester), isFalse);

      // A new surface starts the loop again.
      doubles.vibration.reset();
      show.value = true;
      await tester.pump();

      expect(_isTeachingRunning(tester), isTrue);
      expect(doubles.vibration.patterns, hasLength(1));
      expect(doubles.shake.isPaused, isFalse);

      await doubles.close(tester);
      show.dispose();
    });

    testWidgets('a surface replacing it in the same frame keeps the loop '
        'running', (tester) async {
      final doubles = _Doubles();
      final show = ValueNotifier(true);
      final surfaceKey = ValueNotifier(0);
      await pumpSurface(tester, doubles, show: show, surfaceKey: surfaceKey);
      expect(_isTeachingRunning(tester), isTrue);
      doubles.vibration.reset();

      // The old surface is disposed and the new one starts in one frame.
      surfaceKey.value = 1;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_isTeachingRunning(tester), isTrue);
      expect(doubles.shake.isPaused, isFalse);
      // The old loop was cancelled and the new one played once.
      expect(doubles.vibration.patterns, hasLength(1));

      // Only the new loop repeats.
      doubles.vibration.reset();
      await tester.pump(_testRepeatPause);
      expect(doubles.vibration.patterns, hasLength(1));

      await doubles.close(tester);
      show.dispose();
      surfaceKey.dispose();
    });
  });
}
