import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
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

// A double shake in a session returns to the home menu (#41; it used to
// open the language picker, issue #9).

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

/// Silence between a confirmed identifier and the next screen: the default
/// post-feedback pause (only the repeat pause is overridden here).
final _confirmPause = const TeachingTimingConfig().postFeedbackPause;

/// Identifier vibrations: the menu's Morse L and S, the picker's Morse ع
/// and Р.
const _learn = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dot,
];
const _settings = [MorseSignal.dot, MorseSignal.dot, MorseSignal.dot];
const _arabic = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dash,
];
const _russian = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

/// Holds a finger anywhere for 1 second, the hold that confirms on the menu
/// and on the picker, then lets the next screen open.
Future<void> _holdToConfirm(WidgetTester tester) async {
  final hold = await tester.startGesture(const Offset(100, 100));
  await tester.pump(HomeMenuSurface.confirmHoldDuration);
  await hold.up();
  await tester.pump(_confirmPause);
  await tester.pumpAndSettle();
}

/// Swipes right across the middle of the screen.
Future<void> _swipeRight(WidgetTester tester) async {
  await tester.dragFrom(const Offset(400, 300), const Offset(200, 0));
  await tester.pump();
}

/// Whether [label]'s column is drawn highlighted (inverted: black text).
bool _isHighlighted(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color == Colors.black;

/// The app, launched with Arabic saved, and taken from the menu into an
/// Arabic session.
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
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    // Learn is highlighted at launch: one hold opens the lessons.
    await _holdToConfirm(tester);
    expect(find.byType(TouchSurface), findsOneWidget);
    expect(isTeachingRunning(tester), isTrue);
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  SessionState session(WidgetTester tester) =>
      container(tester).read(sessionNotifierProvider);

  bool isTeachingRunning(WidgetTester tester) =>
      container(tester).read(teachingOrchestratorProvider).isRunning;

  /// Double shakes and waits for the menu to finish appearing.
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
  testWidgets('a double shake stops the session and opens the menu', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);

    app.shake.addEvent(const ChangeLanguage());
    await tester.pump();

    // Stopped at once, before the route transition ends.
    expect(app.isTeachingRunning(tester), isFalse);

    await tester.pumpAndSettle();
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(find.byType(TouchSurface), findsNothing);
    expect(find.byType(LanguagePickerSurface), findsNothing);
    expect(app.isTeachingRunning(tester), isFalse);
    // The menu listens for shakes now that the lessons have stopped.
    expect(app.shake.isPaused, isFalse);

    await app.close(tester);
  });

  testWidgets('the menu highlights Learn and says so', (tester) async {
    final app = _App();
    await app.launch(tester);
    app.vibration.reset();

    await app.doubleShake(tester);

    // The first shake went home; the menu then played the identifier of
    // the mode the user came from, Learn.
    expect(app.vibration.patterns.last, _learn);
    expect(_isHighlighted(tester, 'Learn'), isTrue);
    expect(_isHighlighted(tester, 'Settings'), isFalse);

    await app.close(tester);
  });

  testWidgets('a new language chosen without sight through Settings starts '
      'and is saved', (tester) async {
    final app = _App();
    await app.launch(tester);
    await app.doubleShake(tester);

    // Swipe to Settings and hold: the picker opens on the current language.
    app.vibration.reset();
    await _swipeRight(tester);
    expect(app.vibration.patterns, [_settings]);
    await _holdToConfirm(tester);
    expect(find.byType(LanguagePickerSurface), findsOneWidget);
    expect(app.vibration.patterns, [_settings, _settings, _arabic]);

    // Swipe right: Arabic -> Russian, then hold anywhere to choose it.
    app.vibration.reset();
    await _swipeRight(tester);
    expect(app.vibration.patterns, [_russian]);
    await _holdToConfirm(tester);

    // Back on the menu, on Settings.
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(find.byType(LanguagePickerSurface), findsNothing);
    expect(_isHighlighted(tester, 'Settings'), isTrue);
    expect(app.vibration.patterns, [_russian, _russian, _settings]);
    expect(app.store.read(), MorseLanguage.russian);
    expect(app.session(tester).language, MorseLanguage.russian);

    // Swipe to Learn and hold: the lessons start in Russian.
    await _swipeRight(tester);
    await _holdToConfirm(tester);
    expect(find.byType(TouchSurface), findsOneWidget);
    expect(app.session(tester).language, MorseLanguage.russian);
    expect(app.isTeachingRunning(tester), isTrue);
    expect(app.shake.isPaused, isFalse);

    // And the way back still works from the new session.
    await app.doubleShake(tester);
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(app.vibration.patterns.last, _learn);

    await app.close(tester);
  });

  testWidgets('a single shake only goes home', (tester) async {
    final app = _App();
    await app.launch(tester);
    app.container(tester).read(sessionNotifierProvider.notifier).nextLevel();

    app.shake.addEvent(const Home());
    await tester.pumpAndSettle();

    expect(find.byType(TouchSurface), findsOneWidget);
    expect(find.byType(HomeMenuSurface), findsNothing);
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
    expect(find.byType(HomeMenuSurface), findsNothing);

    await _bringToForeground(tester);
    expect(app.isTeachingRunning(tester), isTrue);

    await app.close(tester);
  });

  testWidgets('shakes during the transition do not restart the loop', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);
    app.vibration.reset();

    app.shake.addEvent(const ChangeLanguage());
    await tester.pump();

    // The rest of the second shake arrives while the menu slides in.
    app.shake.addEvent(const Home());
    await tester.pumpAndSettle();

    expect(app.isTeachingRunning(tester), isFalse);
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    // Only the menu's identifier played, not a lesson pattern.
    expect(app.vibration.patterns, [_learn]);

    await app.close(tester);
  });
}
