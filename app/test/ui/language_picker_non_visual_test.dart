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

/// Identifier vibrations: Morse E, ع, Р and Ñ.
const _english = [MorseSignal.dot];
const _arabic = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dash,
];
const _russian = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];
const _spanish = [
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dash,
];

/// Each language's column label, identifier letter and identifier
/// vibration, in picker order.
const _options = {
  MorseLanguage.english: (label: 'English', letter: 'E', identifier: _english),
  MorseLanguage.arabic: (label: 'العربية', letter: 'ع', identifier: _arabic),
  MorseLanguage.russian: (label: 'Русский', letter: 'Р', identifier: _russian),
  MorseLanguage.spanish: (label: 'Español', letter: 'Ñ', identifier: _spanish),
};

/// The language of the rightmost column, where a swipe left from English
/// lands.
final _last = MorseLanguage.values.last;

/// The identifier vibration of [language].
List<MorseSignal> _identifierOf(MorseLanguage language) =>
    _options[language]!.identifier;

/// The column label of [language].
String _labelOf(MorseLanguage language) => _options[language]!.label;

/// Visible hint for the sighted helper.
const _helperHint = 'Tap a language, then hold anywhere for 1 second to start';

/// Silence between a started language's identifier and its session: the
/// default post-feedback pause (the harness only overrides the repeat pause).
final _startPause = const TeachingTimingConfig().postFeedbackPause;

/// A [MockVibrationService] that can hold the next [playMorsePattern] call
/// open until [release] is called, as a long identifier plays on a device.
class _HeldVibration extends MockVibrationService {
  Completer<void>? _held;

  /// Whether the next [playMorsePattern] call is held open.
  bool holdNextPattern = false;

  /// Lets the held call complete.
  void release() => _held?.complete();

  @override
  Future<void> playMorsePattern(List<MorseSignal> signals) async {
    await super.playMorsePattern(signals);
    if (!holdNextPattern) return;
    holdNextPattern = false;
    _held = Completer<void>();
    await _held!.future;
  }
}

/// The picker, its collaborators and the test doubles behind it.
class _Harness {
  _Harness({MorseLanguage? saved, this.probe})
    : store = InMemoryLanguagePreferenceStore(saved);

  final InMemoryLanguagePreferenceStore store;
  final VibrationCapabilityProbe? probe;
  final classifier = FakeGestureClassifier();
  final vibration = _HeldVibration();
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

/// Lets a started language's identifier and the silence after it pass, so
/// the session replaces the picker.
Future<void> _waitForSession(WidgetTester tester) async {
  await tester.pump(_startPause);
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

      // Top-right corner: the last column.
      await tester.tapAt(const Offset(790, 10));
      await tester.pump();
      // Bottom of the screen, under the hint line: the Arabic column.
      final arabicX = tester.getCenter(find.text('العربية')).dx;
      await tester.tapAt(Offset(arabicX, 590));
      await tester.pump();
      // Again on the highlighted column: plays it again.
      await tester.tapAt(Offset(arabicX, 100));
      await tester.pump();

      expect(t.identifiers, [_identifierOf(_last), _arabic, _arabic]);
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

  group('languages', () {
    test('the table covers every language', () {
      expect(_options.keys, MorseLanguage.values);
    });

    test('identifiers are the registry patterns of their letters, and '
        'distinct', () {
      for (final MapEntry(key: language, value: option) in _options.entries) {
        expect(
          encodeLetter(option.letter, language),
          option.identifier,
          reason: '$language',
        );
      }
      final distinct = {for (final o in _options.values) o.identifier.join()};
      expect(distinct, hasLength(_options.length));
    });

    testWidgets('one column per language, left to right in enum order', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);

      final xs = [
        for (final language in MorseLanguage.values)
          tester.getCenter(find.text(_labelOf(language))).dx,
      ];
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]));
      }

      await t.dispose(tester);
    });

    testWidgets('tapping each language plays its own identifier', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      for (final language in MorseLanguage.values) {
        await tester.tap(find.text(_labelOf(language)));
        await tester.pump();
        expect(_isHighlighted(tester, _labelOf(language)), isTrue);
      }

      expect(t.identifiers, [
        for (final language in MorseLanguage.values) _identifierOf(language),
      ]);

      await t.dispose(tester);
    });

    testWidgets('Español plays Ñ and starts Spanish', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      final spanish = tester.getCenter(find.text('Español'));
      await tester.tapAt(spanish);
      await tester.pump();
      expect(t.identifiers, [_spanish]);

      await _hold(tester, at: spanish);
      await _waitForSession(tester);

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_sessionLanguage(tester), MorseLanguage.spanish);
      expect(t.store.read(), MorseLanguage.spanish);
      expect(t.identifiers.take(2), [_spanish, _spanish]);

      await t.dispose(tester);
    });

    testWidgets('a saved Spanish is highlighted and played', (tester) async {
      final t = _Harness(saved: MorseLanguage.spanish);
      await t.pump(tester);

      expect(t.identifiers, [_spanish]);
      expect(_isHighlighted(tester, 'Español'), isTrue);

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

      // Every language after English in turn, then back to English.
      final order = [...MorseLanguage.values.skip(1), MorseLanguage.english];
      for (final language in order) {
        await _swipe(tester, 200);
        expect(
          t.identifiers.last,
          _identifierOf(language),
          reason: '$language',
        );
        expect(_isHighlighted(tester, _labelOf(language)), isTrue);
      }

      expect(t.identifiers, [for (final l in order) _identifierOf(l)]);
      expect(find.byType(TouchSurface), findsNothing);

      await t.dispose(tester);
    });

    testWidgets('left moves to the previous language, wrapping', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      const languages = MorseLanguage.values;
      final beforeLast = languages[languages.length - 2];
      await _swipe(tester, -200);
      expect(_isHighlighted(tester, _labelOf(_last)), isTrue);
      await _swipe(tester, -200);
      expect(_isHighlighted(tester, _labelOf(beforeLast)), isTrue);

      expect(t.identifiers, [_identifierOf(_last), _identifierOf(beforeLast)]);

      await t.dispose(tester);
    });

    testWidgets('a swipe is measured from where it starts, not by column', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      // Starts on the English column and ends several columns further, but
      // is one swipe right: English -> Arabic.
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
      await _waitForSession(tester);

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

      // Swipe left to the last language, then hold on the English column.
      await _swipe(tester, -200);
      t.vibration.reset();
      await _hold(tester, at: tester.getCenter(find.text('English')));
      await _waitForSession(tester);

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_sessionLanguage(tester), _last);
      expect(t.store.read(), _last);
      expect(t.identifiers.first, _identifierOf(_last));

      await t.dispose(tester);
    });

    testWidgets('starts a saved language straight away', (tester) async {
      final t = _Harness(saved: MorseLanguage.arabic);
      await t.pump(tester);

      await _hold(tester);
      await _waitForSession(tester);

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
      await _waitForSession(tester);
      await tester.pumpAndSettle();

      expect(find.byType(TouchSurface), findsOneWidget);
      expect(find.byType(LanguagePickerSurface), findsNothing);
      expect(_sessionLanguage(tester), MorseLanguage.russian);
      expect(t.store.read(), MorseLanguage.russian);

      await t.dispose(tester);
      handle.dispose();
    });
  });

  // Issue #28: on Android a new vibration replaces the one in progress, so
  // the session's first pattern must not start while the identifier plays.
  group('starting a language', () {
    testWidgets('the lesson waits for the identifier and a silence after it', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      await _swipe(tester, 200);
      t.vibration
        ..reset()
        ..holdNextPattern = true;

      await _hold(tester);
      // However long the identifier plays, the picker stays.
      await tester.pump(_testRepeatPause);
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.identifiers, [_arabic]);

      // Once it has finished, a short silence still comes first.
      t.vibration.release();
      await tester.pump(_startPause - const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.identifiers, [_arabic]);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_sessionLanguage(tester), MorseLanguage.arabic);
      final session = ProviderScope.containerOf(
        tester.element(find.byType(TouchSurface)),
      ).read(sessionNotifierProvider);
      expect(t.identifiers, [
        _arabic,
        session.currentLevel.patterns[session.currentCharacter],
      ]);

      await t.dispose(tester);
    });

    testWidgets('gestures are ignored while the identifier plays', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration
        ..reset()
        ..holdNextPattern = true;

      await _hold(tester);
      await tester.tapAt(tester.getCenter(find.text('Русский')));
      await tester.pump();
      await _swipe(tester, 200);
      await _hold(tester);

      expect(t.identifiers, [_english]);
      expect(_isHighlighted(tester, 'English'), isTrue);

      t.vibration.release();
      await _waitForSession(tester);
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(_sessionLanguage(tester), MorseLanguage.english);
      expect(t.store.read(), MorseLanguage.english);

      await t.dispose(tester);
    });

    testWidgets('nothing is saved or started when detection finds no motor '
        'while the identifier plays', (tester) async {
      final gate = Completer<void>();
      final t = _Harness(
        probe: FakeVibrationCapabilityProbe(vibrator: false, gate: gate),
      );
      await t.pump(tester);

      // Detection is slower than choosing the last language and holding to
      // start it.
      await _swipe(tester, -200);
      t.vibration.holdNextPattern = true;
      await _hold(tester);
      final identifier = _identifierOf(_last);
      expect(t.identifiers, [identifier, identifier]);

      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(NoVibrationScreen), findsOneWidget);

      t.vibration.release();
      await _waitForSession(tester);
      await tester.pump(_testRepeatPause);

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.store.read(), isNull);
      expect(_sessionLanguage(tester), MorseLanguage.english);
      expect(t.identifiers, [identifier, identifier]);

      await t.dispose(tester);
    });
  });

  group('sighted helper', () {
    testWidgets('sees how to start and which language is highlighted', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);

      expect(find.text(_helperHint), findsOneWidget);
      for (final (:label, letter: _, identifier: _) in _options.values) {
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
      await _waitForSession(tester);

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
