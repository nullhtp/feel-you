import 'dart:async';

import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
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

// The language picker must be usable without sight (issue #9): every
// gesture answers with the highlighted language's identifier vibration.

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

/// Identifier vibrations: Morse E, ع and Р.
const _english = [MorseSignal.dot];
const _arabic = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dash,
];
const _russian = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

/// Visible hint for the sighted helper.
const _helperHint = 'Tap a language, then hold anywhere for 1 second to start';

/// The picker, its collaborators and the test doubles behind it.
class _Harness {
  _Harness({MorseLanguage? saved, this.probe})
    : store = InMemoryLanguagePreferenceStore(saved);

  final InMemoryLanguagePreferenceStore store;
  final VibrationCapabilityProbe? probe;
  final classifier = FakeGestureClassifier();
  final vibration = MockVibrationService();
  final shake = FakeShakeDetector();

  Widget build() => ProviderScope(
    overrides: [
      languagePreferenceStoreProvider.overrideWithValue(store),
      gestureClassifierProvider.overrideWithValue(classifier),
      vibrationServiceProvider.overrideWithValue(vibration),
      shakeDetectorProvider.overrideWithValue(shake),
      teachingTimingConfigProvider.overrideWithValue(
        const TeachingTimingConfig(repeatPause: _testRepeatPause),
      ),
      vibrationCapabilityProbeProvider.overrideWithValue(
        probe ?? FakeVibrationCapabilityProbe(),
      ),
    ],
    child: MaterialApp(
      builder: (_, navigator) => VibrationGate(child: navigator!),
      home: const LanguagePickerSurface(),
    ),
  );

  /// Shows the picker and lets it play its first identifier.
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(build());
    await tester.pump();
  }

  /// Identifiers played so far.
  List<List<MorseSignal>> get identifiers => vibration.patterns;

  Future<void> dispose(WidgetTester tester) async {
    final surface = find.byType(TouchSurface);
    if (surface.evaluate().isNotEmpty) {
      await ProviderScope.containerOf(
        tester.element(surface),
      ).read(teachingOrchestratorProvider.notifier).stop();
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);
    classifier.dispose();
    shake.dispose();
  }
}

/// Holds a finger at [at] (the screen centre by default) for [duration],
/// then lifts it.
Future<void> _hold(
  WidgetTester tester, {
  Offset? at,
  Duration duration = LanguagePickerSurface.confirmHoldDuration,
}) async {
  final gesture = await tester.startGesture(
    at ?? tester.getCenter(find.byType(Scaffold).first),
  );
  await tester.pump(duration);
  await gesture.up();
  await tester.pump();
}

/// Swipes horizontally across the middle of the screen by [dx].
Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.dragFrom(const Offset(400, 300), Offset(dx, 0));
  await tester.pump();
}

/// Whether [label]'s column is drawn highlighted (inverted: black text).
bool _isHighlighted(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color == Colors.black;

/// The language the session behind the picker is in.
MorseLanguage _sessionLanguage(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(sessionNotifierProvider).language;

void main() {
  group('when the picker appears', () {
    testWidgets('English is highlighted and played once when nothing is '
        'saved', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      await tester.pump(const Duration(seconds: 3));

      expect(t.identifiers, [_english]);
      expect(_isHighlighted(tester, 'English'), isTrue);
      expect(_isHighlighted(tester, 'Русский'), isFalse);

      await t.dispose(tester);
    });

    testWidgets('the saved language is highlighted and played', (tester) async {
      final t = _Harness(saved: MorseLanguage.arabic);
      await t.pump(tester);

      expect(t.identifiers, [_arabic]);
      expect(_isHighlighted(tester, 'العربية'), isTrue);
      expect(_isHighlighted(tester, 'English'), isFalse);

      await t.dispose(tester);
    });

    testWidgets('nothing is played before detection finds a motor', (
      tester,
    ) async {
      final gate = Completer<void>();
      final t = _Harness(probe: FakeVibrationCapabilityProbe(gate: gate));
      await t.pump(tester);
      expect(t.identifiers, isEmpty);

      gate.complete();
      await tester.pump();
      expect(t.identifiers, [_english]);

      await t.dispose(tester);
    });
  });

  group('tap', () {
    testWidgets('highlights the tapped language and plays it', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await tester.tap(find.text('Русский'));
      await tester.pump();
      expect(t.identifiers, [_russian]);
      expect(_isHighlighted(tester, 'Русский'), isTrue);
      expect(_isHighlighted(tester, 'English'), isFalse);

      await tester.tap(find.text('العربية'));
      await tester.pump();
      expect(t.identifiers, [_russian, _arabic]);
      expect(_isHighlighted(tester, 'العربية'), isTrue);

      // Tapping does not start a session or save anything.
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.store.read(), isNull);

      await t.dispose(tester);
    });

    testWidgets('anywhere in a column counts, including under the hint', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      // Top-right corner: the Russian column.
      await tester.tapAt(const Offset(790, 10));
      await tester.pump();
      // Bottom centre, under the hint line: the Arabic column.
      await tester.tapAt(const Offset(400, 590));
      await tester.pump();
      // Again on the highlighted column: plays it again.
      await tester.tapAt(const Offset(400, 100));
      await tester.pump();

      expect(t.identifiers, [_russian, _arabic, _arabic]);
      expect(find.byType(TouchSurface), findsNothing);

      await t.dispose(tester);
    });

    testWidgets('a press shorter than the hold is a tap', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _hold(
        tester,
        at: tester.getCenter(find.text('Русский')),
        duration: const Duration(milliseconds: 900),
      );

      expect(find.byType(TouchSurface), findsNothing);
      expect(t.identifiers, [_russian]);
      expect(_isHighlighted(tester, 'Русский'), isTrue);

      await t.dispose(tester);
    });
  });

  group('swipe', () {
    testWidgets('right moves to the next language and plays it, wrapping', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _swipe(tester, 200);
      expect(t.identifiers.last, _arabic);
      expect(_isHighlighted(tester, 'العربية'), isTrue);

      await _swipe(tester, 200);
      expect(t.identifiers.last, _russian);
      expect(_isHighlighted(tester, 'Русский'), isTrue);

      await _swipe(tester, 200);
      expect(t.identifiers.last, _english);
      expect(_isHighlighted(tester, 'English'), isTrue);

      expect(t.identifiers, [_arabic, _russian, _english]);
      expect(find.byType(TouchSurface), findsNothing);

      await t.dispose(tester);
    });

    testWidgets('left moves to the previous language, wrapping', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _swipe(tester, -200);
      expect(_isHighlighted(tester, 'Русский'), isTrue);
      await _swipe(tester, -200);
      expect(_isHighlighted(tester, 'العربية'), isTrue);

      expect(t.identifiers, [_russian, _arabic]);

      await t.dispose(tester);
    });

    testWidgets('a swipe is measured from where it starts, not by column', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      // Starts on the English column and ends on the Russian one, but is
      // one swipe right: English -> Arabic.
      await tester.dragFrom(const Offset(100, 300), const Offset(600, 0));
      await tester.pump();

      expect(t.identifiers, [_arabic]);
      expect(_isHighlighted(tester, 'العربية'), isTrue);

      await t.dispose(tester);
    });

    testWidgets('a short drag replays the highlighted language', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _swipe(tester, 30);

      expect(t.identifiers, [_english]);
      expect(_isHighlighted(tester, 'English'), isTrue);

      await t.dispose(tester);
    });
  });

  group('hold', () {
    testWidgets('starts the highlighted language', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _hold(tester);
      await tester.pump();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_sessionLanguage(tester), MorseLanguage.english);
      expect(t.store.read(), MorseLanguage.english);
      // The confirmation plays the identifier before the lesson starts.
      expect(t.identifiers.first, _english);

      await t.dispose(tester);
    });

    testWidgets('starts the language last felt, wherever the finger is', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);

      // Swipe to Russian, then hold on the English column.
      await _swipe(tester, -200);
      t.vibration.reset();
      await _hold(tester, at: tester.getCenter(find.text('English')));
      await tester.pump();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_sessionLanguage(tester), MorseLanguage.russian);
      expect(t.store.read(), MorseLanguage.russian);
      expect(t.identifiers.first, _russian);

      await t.dispose(tester);
    });

    testWidgets('starts a saved language straight away', (tester) async {
      final t = _Harness(saved: MorseLanguage.arabic);
      await t.pump(tester);

      await _hold(tester);
      await tester.pump();

      expect(_sessionLanguage(tester), MorseLanguage.arabic);
      expect(t.store.read(), MorseLanguage.arabic);

      await t.dispose(tester);
    });

    testWidgets('a second confirmation before the route changes is ignored', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final t = _Harness();
      await t.pump(tester);

      // Two activations before the picker is rebuilt: only the first one
      // starts a session.
      tester.semantics
        ..tap(find.semantics.byLabel('Русский'))
        ..tap(find.semantics.byLabel('English'));
      await tester.pumpAndSettle();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(find.byType(LanguagePickerSurface), findsNothing);
      expect(_sessionLanguage(tester), MorseLanguage.russian);
      expect(t.store.read(), MorseLanguage.russian);

      await t.dispose(tester);
      handle.dispose();
    });
  });

  group('sighted helper', () {
    testWidgets('sees how to start and which language is highlighted', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);

      expect(find.text(_helperHint), findsOneWidget);
      for (final label in ['English', 'العربية', 'Русский']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(_isHighlighted(tester, 'English'), isTrue);

      await t.dispose(tester);
    });

    testWidgets('taps a language, then holds it to start', (tester) async {
      final t = _Harness();
      await t.pump(tester);

      final russian = tester.getCenter(find.text('Русский'));
      await tester.tapAt(russian);
      await tester.pump();
      expect(_isHighlighted(tester, 'Русский'), isTrue);

      await _hold(tester, at: russian);
      await tester.pump();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_sessionLanguage(tester), MorseLanguage.russian);
      expect(t.store.read(), MorseLanguage.russian);

      await t.dispose(tester);
    });
  });

  group('vibration gate', () {
    testWidgets('a screen-reader activation that lands before the switch to '
        'the no-vibration screen is ignored', (tester) async {
      final handle = tester.ensureSemantics();
      final gate = Completer<void>();
      final t = _Harness(
        probe: FakeVibrationCapabilityProbe(vibrator: false, gate: gate),
      );
      await t.pump(tester);
      expect(find.text('English'), findsOneWidget);

      // Detection finishes, but the picker has not been rebuilt yet.
      gate.complete();
      await ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).read(vibrationCapabilitiesProvider.future);
      tester.semantics.tap(find.semantics.byLabel('English'));
      await tester.pumpAndSettle();

      expect(find.byType(TouchSurface), findsNothing);
      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(t.store.read(), isNull);
      expect(t.vibration.calls, isEmpty);

      await t.dispose(tester);
      handle.dispose();
    });
  });
}
