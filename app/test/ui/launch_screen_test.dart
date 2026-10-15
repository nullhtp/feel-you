import 'dart:async';

import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_vibration_capability_probe.dart';
import '../test_doubles/mock_vibration_service.dart';

// A saved language skips the picker on launch (issue #9).

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

const _key = SharedPreferencesLanguagePreferenceStore.storageKey;

/// Loads the persistent store from [stored] (mock platform storage), as
/// `main` does before the first frame.
Future<LanguagePreferenceStore> _loadStore(Map<String, Object> stored) {
  SharedPreferences.setMockInitialValues(stored);
  return loadLanguagePreferenceStore();
}

/// The whole app with test doubles, launched with [store].
class _App {
  _App(this.store, {VibrationCapabilityProbe? probe})
    : probe = probe ?? FakeVibrationCapabilityProbe();

  final LanguagePreferenceStore store;
  final VibrationCapabilityProbe probe;
  final classifier = FakeGestureClassifier();
  final vibration = MockVibrationService();
  final shake = FakeShakeDetector();

  /// Launches the app and lets the first frame's callbacks run.
  Future<void> launch(WidgetTester tester) async {
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
          vibrationCapabilityProbeProvider.overrideWithValue(probe),
        ],
        child: const FeelYouApp(),
      ),
    );
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  SessionState session(WidgetTester tester) =>
      container(tester).read(sessionNotifierProvider);

  bool isTeachingRunning(WidgetTester tester) =>
      container(tester).read(teachingOrchestratorProvider).isRunning;

  /// Stops the teaching loop, removes the app and flushes its timers.
  Future<void> close(WidgetTester tester) async {
    if (find.byType(MaterialApp).evaluate().isNotEmpty) {
      await container(
        tester,
      ).read(teachingOrchestratorProvider.notifier).stop();
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);
    classifier.dispose();
    shake.dispose();
  }
}

void main() {
  group('launch without a saved language', () {
    testWidgets('shows the picker', (tester) async {
      final app = _App(await _loadStore({}));
      await app.launch(tester);
      await tester.pump();

      expect(find.byType(LanguagePickerSurface), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(app.isTeachingRunning(tester), isFalse);

      await app.close(tester);
    });

    for (final garbage in <Object>['klingon', '', 42, true]) {
      testWidgets('shows the picker when the stored value is $garbage', (
        tester,
      ) async {
        final app = _App(await _loadStore({_key: garbage}));
        await app.launch(tester);
        await tester.pump();

        expect(find.byType(LanguagePickerSurface), findsOneWidget);
        expect(find.byType(TouchSurface), findsNothing);

        await app.close(tester);
      });
    }

    testWidgets('a language chosen in the picker is used on the next launch', (
      tester,
    ) async {
      final first = _App(await _loadStore({}));
      await first.launch(tester);
      await tester.pump();

      // Pick Arabic: swipe right from English, then hold.
      await tester.dragFrom(const Offset(400, 300), const Offset(200, 0));
      await tester.pump();
      final hold = await tester.startGesture(const Offset(400, 300));
      await tester.pump(LanguagePickerSurface.confirmHoldDuration);
      await hold.up();
      await tester.pumpAndSettle();
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(first.session(tester).language, MorseLanguage.arabic);
      await first.close(tester);

      // Relaunch: storage is read again from the platform.
      SharedPreferences.resetStatic();
      final second = _App(await loadLanguagePreferenceStore());
      await second.launch(tester);
      await tester.pump();

      expect(find.byType(LanguagePickerSurface), findsNothing);
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(second.session(tester).language, MorseLanguage.arabic);

      await second.close(tester);
    });
  });

  group('launch with a saved language', () {
    testWidgets('goes straight to the lessons in that language', (
      tester,
    ) async {
      final app = _App(await _loadStore({_key: 'russian'}));
      await app.launch(tester);

      // No picker, not even for the first frame.
      expect(find.byType(LanguagePickerSurface), findsNothing);
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(app.session(tester).language, MorseLanguage.russian);

      await tester.pump();
      expect(app.isTeachingRunning(tester), isTrue);

      // The loop plays the first Russian character.
      final session = app.session(tester);
      expect(session.levelIndex, 0);
      expect(session.positionIndex, 0);
      expect(app.vibration.patterns, [
        session.currentLevel.patterns[session.currentCharacter],
      ]);
      // No language identifier was played.
      expect(app.vibration.patterns, isNot(contains([MorseSignal.dot])));

      await app.close(tester);
    });

    for (final language in MorseLanguage.values) {
      testWidgets('starts in ${language.name}', (tester) async {
        final app = _App(InMemoryLanguagePreferenceStore(language));
        await app.launch(tester);
        await tester.pump();

        expect(find.byType(TouchSurface), findsOneWidget);
        expect(app.session(tester).language, language);
        expect(app.isTeachingRunning(tester), isTrue);

        await app.close(tester);
      });
    }
  });

  group('vibration gate', () {
    testWidgets('no motor shows the no-vibration screen instead of the '
        'picker', (tester) async {
      final app = _App(
        await _loadStore({}),
        probe: FakeVibrationCapabilityProbe(vibrator: false),
      );
      await app.launch(tester);
      await tester.pump();

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.text('English'), findsNothing);
      expect(app.vibration.calls, isEmpty);

      await app.close(tester);
    });

    testWidgets('no motor shows the no-vibration screen instead of the '
        'lessons', (tester) async {
      final app = _App(
        await _loadStore({_key: 'russian'}),
        probe: FakeVibrationCapabilityProbe(vibrator: false),
      );
      await app.launch(tester);
      await tester.pump();

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(app.isTeachingRunning(tester), isFalse);

      // Nothing is played from now on.
      app.vibration.reset();
      await tester.pump(_testRepeatPause * 2);
      expect(app.vibration.patterns, isEmpty);

      await app.close(tester);
    });

    testWidgets('a session stops when detection later finds no motor', (
      tester,
    ) async {
      final gate = Completer<void>();
      final app = _App(
        InMemoryLanguagePreferenceStore(MorseLanguage.english),
        probe: FakeVibrationCapabilityProbe(vibrator: false, gate: gate),
      );
      await app.launch(tester);
      await tester.pump();

      // Detection is still running: the session starts.
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(app.isTeachingRunning(tester), isTrue);

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(app.isTeachingRunning(tester), isFalse);

      await app.close(tester);
    });

    testWidgets('a motor found later keeps the session running', (
      tester,
    ) async {
      final gate = Completer<void>();
      final app = _App(
        InMemoryLanguagePreferenceStore(MorseLanguage.english),
        probe: FakeVibrationCapabilityProbe(gate: gate),
      );
      await app.launch(tester);
      await tester.pump();

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(find.byType(NoVibrationScreen), findsNothing);
      expect(app.isTeachingRunning(tester), isTrue);

      await app.close(tester);
    });
  });
}
