import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
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

// The whole app around the home menu (#41): launch, Learn, Settings, the
// language picker and the double shake back, with the vibrations in order.

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

/// Silence between a confirmed identifier and the next screen: the default
/// post-feedback pause (only the repeat pause is overridden here).
final _confirmPause = const TeachingTimingConfig().postFeedbackPause;

/// The menu's identifiers, Morse L and S, and the picker's E, ع and Р.
const _learn = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dot,
];
const _settings = [MorseSignal.dot, MorseSignal.dot, MorseSignal.dot];
const _english = [MorseSignal.dot];
const _arabic = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dash,
];
const _russian = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

/// Digit 0, `− − − − −`, the same in every language.
final _zero = encodeLetter('0', MorseLanguage.english)!;

/// The app with test doubles, launched with the given language saved (none
/// by default).
class _App {
  _App([MorseLanguage? saved]) : store = InMemoryLanguagePreferenceStore(saved);

  final InMemoryLanguagePreferenceStore store;
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
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  SessionState session(WidgetTester tester) =>
      container(tester).read(sessionNotifierProvider);

  bool isTeachingRunning(WidgetTester tester) =>
      container(tester).read(teachingOrchestratorProvider).isRunning;

  /// The vibrations played so far, as Morse patterns.
  List<List<MorseSignal>> get patterns => vibration.patterns;

  /// Holds anywhere for 1 second and lets the next screen open.
  Future<void> hold(WidgetTester tester) async {
    final gesture = await tester.startGesture(const Offset(400, 300));
    await tester.pump(HomeMenuSurface.confirmHoldDuration);
    await gesture.up();
    await tester.pump(_confirmPause);
    await tester.pumpAndSettle();
  }

  /// Swipes across the middle of the screen: right for a positive [dx].
  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.dragFrom(const Offset(400, 300), Offset(dx, 0));
    await tester.pump();
  }

  /// A double shake: Home for the first shake, ChangeLanguage for the
  /// second, as the detector emits them.
  Future<void> doubleShake(WidgetTester tester) async {
    shake.addEvent(const Home());
    await tester.pump();
    shake.addEvent(const ChangeLanguage());
    await tester.pumpAndSettle();
  }

  /// The mode the menu shown highlights.
  HomeMenuMode menuHighlight(WidgetTester tester) =>
      tester.widget<HomeMenuSurface>(find.byType(HomeMenuSurface)).highlighted;

  Future<void> close(WidgetTester tester) async {
    await container(tester).read(teachingOrchestratorProvider.notifier).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);
    classifier.dispose();
    shake.dispose();
  }
}

void main() {
  testWidgets('launch, Learn, and a double shake back to the menu', (
    tester,
  ) async {
    final app = _App(MorseLanguage.english);
    await app.launch(tester);
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(app.menuHighlight(tester), HomeMenuMode.learn);

    await app.hold(tester);
    expect(find.byType(TouchSurface), findsOneWidget);
    expect(app.isTeachingRunning(tester), isTrue);

    await app.doubleShake(tester);
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(find.byType(TouchSurface), findsNothing);
    expect(app.menuHighlight(tester), HomeMenuMode.learn);
    expect(app.isTeachingRunning(tester), isFalse);

    expect(app.patterns, [
      _learn, // the menu appears
      _learn, // the hold on Learn
      _zero, // the lessons start
      _zero, // the first shake: home, digit 0 again
      _learn, // the second shake: back on the menu
    ]);

    await app.close(tester);
  });

  testWidgets('Settings chooses a language and returns to the menu, whose '
      'Learn opens it at digit 0', (tester) async {
    final app = _App(MorseLanguage.english);
    await app.launch(tester);

    // Swipe to Settings and hold: the picker opens on English.
    await app.swipe(tester, 200);
    await app.hold(tester);
    final picker = tester.widget<LanguagePickerSurface>(
      find.byType(LanguagePickerSurface),
    );
    expect(picker.fromMenu, isTrue);

    // Tap Russian and hold: saved, and back on the menu.
    await tester.tap(find.text('Русский'));
    await tester.pump();
    await app.hold(tester);
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(app.menuHighlight(tester), HomeMenuMode.settings);
    expect(app.store.read(), MorseLanguage.russian);

    // Swipe to Learn and hold: the lessons start in Russian, on digit 0.
    await app.swipe(tester, 200);
    await app.hold(tester);
    expect(find.byType(TouchSurface), findsOneWidget);
    final session = app.session(tester);
    expect(session.language, MorseLanguage.russian);
    expect(session.levelIndex, 0);
    expect(session.positionIndex, 0);

    expect(app.patterns, [
      _learn, // the menu appears
      _settings, // swipe
      _settings, // hold
      _english, // the picker appears on the saved language
      _russian, // tap Russian
      _russian, // hold
      _settings, // the menu appears on Settings
      _learn, // swipe
      _learn, // hold
      _zero, // the lessons start
    ]);

    await app.close(tester);
  });

  testWidgets('a double shake leaves Settings without changing the language', (
    tester,
  ) async {
    final app = _App(MorseLanguage.arabic);
    await app.launch(tester);
    await app.swipe(tester, 200);
    await app.hold(tester);
    expect(find.byType(LanguagePickerSurface), findsOneWidget);

    // Moving the highlight to Russian is not choosing it.
    await app.swipe(tester, 200);
    await app.doubleShake(tester);

    expect(find.byType(LanguagePickerSurface), findsNothing);
    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(app.menuHighlight(tester), HomeMenuMode.settings);
    expect(app.store.read(), MorseLanguage.arabic);
    expect(app.session(tester).language, MorseLanguage.arabic);
    expect(app.patterns, [
      _learn,
      _settings,
      _settings,
      _arabic,
      _russian,
      _settings, // back on the menu; the first shake did nothing
    ]);

    await app.close(tester);
  });

  testWidgets('the first launch goes from the picker to the menu on Learn', (
    tester,
  ) async {
    final app = _App();
    await app.launch(tester);
    expect(find.byType(LanguagePickerSurface), findsOneWidget);
    expect(
      tester
          .widget<LanguagePickerSurface>(find.byType(LanguagePickerSurface))
          .fromMenu,
      isFalse,
    );

    await app.hold(tester);

    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(app.menuHighlight(tester), HomeMenuMode.learn);
    expect(app.store.read(), MorseLanguage.english);
    expect(app.patterns, [_english, _english, _learn]);

    // The menu answers a double shake with where the user is.
    await app.doubleShake(tester);
    expect(app.patterns, [_english, _english, _learn, _learn]);

    await app.close(tester);
  });

  testWidgets('the lessons open on digit 0 after a double shake from another '
      'level', (tester) async {
    final app = _App(MorseLanguage.english);
    await app.launch(tester);
    await app.hold(tester);
    app.container(tester).read(sessionNotifierProvider.notifier).nextLevel();

    // The first shake goes home before the second leaves for the menu.
    await app.doubleShake(tester);
    await app.hold(tester);

    final session = app.session(tester);
    expect(session.levelIndex, 0);
    expect(session.positionIndex, 0);

    await app.close(tester);
  });

  testWidgets('shake detection runs on every screen', (tester) async {
    final app = _App(MorseLanguage.english);
    await app.launch(tester);
    expect(app.shake.isPaused, isFalse, reason: 'menu');

    await app.hold(tester);
    expect(app.shake.isPaused, isFalse, reason: 'lessons');

    await app.doubleShake(tester);
    expect(app.shake.isPaused, isFalse, reason: 'menu after the lessons');

    await app.swipe(tester, 200);
    await app.hold(tester);
    expect(app.shake.isPaused, isFalse, reason: 'picker from Settings');

    await app.doubleShake(tester);
    expect(app.shake.isPaused, isFalse, reason: 'menu after Settings');

    await app.close(tester);
  });
}
