import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
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

// A double shake in a session returns to the language picker (issue #9).

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

/// Identifier vibrations: Morse ع and Р.
const _arabic = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dash,
];
const _russian = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

/// The app, launched straight into an Arabic session.
class _App {
  final store = InMemoryLanguagePreferenceStore(MorseLanguage.arabic);
  final classifier = FakeGestureClassifier();
  final vibration = MockVibrationService();
  final shake = FakeShakeDetector();

  Future<void> launch(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languagePreferenceStoreProvider.overrideWithValue(store),
          gestureClassifierProvider.overrideWithValue(classifier),
          vibrationServiceProvider.overrideWithValue(vibration),
          shakeDetectorProvider.overrideWithValue(shake),
          teachingTimingConfigProvider.overrideWithValue(
            const TeachingTimingConfig(repeatPause: _testRepeatPause),
          ),
          vibrationCapabilityProbeProvider.overrideWithValue(
            FakeVibrationCapabilityProbe(),
          ),
        ],
        child: const FeelYouApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(TouchSurface), findsOneWidget);
    expect(isTeachingRunning(tester), isTrue);
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  SessionState session(WidgetTester tester) =>
      container(tester).read(sessionNotifierProvider);

  bool isTeachingRunning(WidgetTester tester) =>
      container(tester).read(teachingOrchestratorProvider).isRunning;

  /// Double shakes and waits for the picker to finish appearing.
  Future<void> doubleShake(WidgetTester tester) async {
    shake
      ..addEvent(const Home())
      ..addEvent(const ChangeLanguage());
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await container(tester).read(teachingOrchestratorProvider.notifier).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);
    classifier.dispose();
    shake.dispose();
  }
}

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
  testWidgets('a double shake stops the session and opens the picker', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);

    app.shake.addEvent(const ChangeLanguage());
    await tester.pump();

    // Stopped at once, before the route transition ends.
    expect(app.isTeachingRunning(tester), isFalse);
    expect(app.shake.isPaused, isTrue);

    await tester.pumpAndSettle();
    expect(find.byType(LanguagePickerSurface), findsOneWidget);
    expect(find.byType(TouchSurface), findsNothing);
    expect(app.isTeachingRunning(tester), isFalse);

    await app.close(tester);
  });

  testWidgets('the picker starts on the current language and says so', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);
    app.vibration.reset();

    await app.doubleShake(tester);

    // The first shake went home; the picker then played the identifier of
    // the highlighted (current) language, Arabic.
    expect(app.vibration.patterns.last, _arabic);
    expect(
      tester.widget<Text>(find.text('العربية')).style?.color,
      Colors.black,
    );

    await app.close(tester);
  });

  testWidgets('a new language chosen without sight starts and is saved', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);
    await app.doubleShake(tester);

    // Swipe right: Arabic -> Russian.
    app.vibration.reset();
    await tester.dragFrom(const Offset(400, 300), const Offset(200, 0));
    await tester.pump();
    expect(app.vibration.patterns, [_russian]);

    // Hold anywhere to start it.
    final hold = await tester.startGesture(const Offset(100, 100));
    await tester.pump(LanguagePickerSurface.confirmHoldDuration);
    await hold.up();
    await tester.pumpAndSettle();

    expect(find.byType(TouchSurface), findsOneWidget);
    expect(find.byType(LanguagePickerSurface), findsNothing);
    expect(app.session(tester).language, MorseLanguage.russian);
    expect(app.store.read(), MorseLanguage.russian);
    expect(app.isTeachingRunning(tester), isTrue);
    expect(app.shake.isPaused, isFalse);

    // And the way back still works from the new session.
    await app.doubleShake(tester);
    expect(find.byType(LanguagePickerSurface), findsOneWidget);
    expect(app.vibration.patterns.last, _russian);

    await app.close(tester);
  });

  testWidgets('a single shake only goes home', (tester) async {
    final app = _App();
    await app.launch(tester);
    app.container(tester).read(sessionNotifierProvider.notifier).nextLevel();

    app.shake.addEvent(const Home());
    await tester.pumpAndSettle();

    expect(find.byType(TouchSurface), findsOneWidget);
    expect(find.byType(LanguagePickerSurface), findsNothing);
    expect(app.session(tester).levelIndex, 0);
    expect(app.isTeachingRunning(tester), isTrue);

    await app.close(tester);
  });

  testWidgets('a double shake is ignored while in the background', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);

    await _sendToBackground(tester);
    app.shake.addEvent(const ChangeLanguage());
    await tester.pumpAndSettle();

    expect(find.byType(TouchSurface), findsOneWidget);
    expect(find.byType(LanguagePickerSurface), findsNothing);

    await _bringToForeground(tester);
    expect(app.isTeachingRunning(tester), isTrue);

    await app.close(tester);
  });

  testWidgets('shakes during the transition do not restart the loop', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);

    app.shake.addEvent(const ChangeLanguage());
    await tester.pump();
    app.vibration.reset();

    // The rest of the second shake arrives while the picker slides in.
    app.shake.addEvent(const Home());
    await tester.pumpAndSettle();

    expect(app.isTeachingRunning(tester), isFalse);
    expect(find.byType(LanguagePickerSurface), findsOneWidget);
    // Only the picker's identifier played, not a lesson pattern.
    expect(app.vibration.patterns, [_arabic]);

    await app.close(tester);
  });
}
