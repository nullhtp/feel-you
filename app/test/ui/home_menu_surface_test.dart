import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
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
import '../test_doubles/held_vibration_service.dart';
import '../test_doubles/mock_wakelock.dart';

// The home menu is used without sight (#41): every gesture is answered with
// the highlighted mode's Morse letter, a hold enters the mode, a double
// shake says where the user is.

/// Long repeat pause so the teaching loop never repeats during a test.
const _testRepeatPause = Duration(seconds: 5);

/// Mode identifiers: Morse L and S.
const _learn = [
  MorseSignal.dot,
  MorseSignal.dash,
  MorseSignal.dot,
  MorseSignal.dot,
];
const _settings = [MorseSignal.dot, MorseSignal.dot, MorseSignal.dot];

/// Language identifiers the picker plays: Morse E and Р.
const _english = [MorseSignal.dot];
const _russian = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

/// Digit 0, the first item of the lessons.
const _zero = [
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
];

/// Visible hint for the sighted helper.
const _helperHint =
    'Tap or swipe to a mode, then hold anywhere for 1 second to open it';

/// Silence between an entered mode's identifier and its screen: the default
/// post-feedback pause (the harness only overrides the repeat pause).
final _enterPause = const TeachingTimingConfig().postFeedbackPause;

/// The menu, its collaborators and the test doubles behind it.
class _Harness {
  _Harness({
    MorseLanguage? saved,
    this.highlighted = HomeMenuMode.learn,
    this.probe,
  }) : store = InMemoryLanguagePreferenceStore(saved);

  final InMemoryLanguagePreferenceStore store;
  final HomeMenuMode highlighted;
  final VibrationCapabilityProbe? probe;
  final classifier = FakeGestureClassifier();
  final vibration = HeldVibrationService();
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
      home: HomeMenuSurface(highlighted: highlighted),
    ),
  );

  /// Shows the menu and lets it play its first identifier.
  Future<void> pump(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(build());
    await tester.pump();
  }

  /// Identifiers (and lesson patterns) played so far.
  List<List<MorseSignal>> get patterns => vibration.patterns;

  /// A double shake: the first shake emits Home, the second ChangeLanguage.
  Future<void> doubleShake(WidgetTester tester) async {
    shake
      ..addEvent(const Home())
      ..addEvent(const ChangeLanguage());
    await tester.pump();
  }

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
  Duration duration = HomeMenuSurface.confirmHoldDuration,
}) async {
  final gesture = await tester.startGesture(at ?? const Offset(400, 300));
  await tester.pump(duration);
  await gesture.up();
  await tester.pump();
}

/// Lets an entered mode's identifier and the silence after it pass, so the
/// mode's screen replaces the menu.
Future<void> _waitForMode(WidgetTester tester) async {
  await tester.pump(_enterPause);
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
  group('when the menu appears', () {
    testWidgets('Learn is highlighted and Morse L is played once', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      await tester.pump(const Duration(seconds: 3));

      expect(t.patterns, [_learn]);
      expect(_isHighlighted(tester, 'Learn'), isTrue);
      expect(_isHighlighted(tester, 'Settings'), isFalse);

      await t.dispose(tester);
    });

    testWidgets('the mode the user came back from is highlighted and played', (
      tester,
    ) async {
      final t = _Harness(highlighted: HomeMenuMode.settings);
      await t.pump(tester);

      expect(t.patterns, [_settings]);
      expect(_isHighlighted(tester, 'Settings'), isTrue);
      expect(_isHighlighted(tester, 'Learn'), isFalse);

      await t.dispose(tester);
    });

    testWidgets('nothing is played before detection finds a motor', (
      tester,
    ) async {
      final gate = Completer<void>();
      final t = _Harness(probe: FakeVibrationCapabilityProbe(gate: gate));
      await t.pump(tester);
      expect(t.patterns, isEmpty);

      gate.complete();
      await tester.pump();
      expect(t.patterns, [_learn]);

      await t.dispose(tester);
    });
  });

  group('tap', () {
    testWidgets('highlights the tapped mode and plays it', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(t.patterns, [_settings]);
      expect(_isHighlighted(tester, 'Settings'), isTrue);
      expect(_isHighlighted(tester, 'Learn'), isFalse);

      await tester.tap(find.text('Learn'));
      await tester.pump();
      expect(t.patterns, [_settings, _learn]);
      expect(_isHighlighted(tester, 'Learn'), isTrue);

      // Tapping does not open a mode.
      expect(find.byType(TouchSurface), findsNothing);
      expect(find.byType(LanguagePickerSurface), findsNothing);

      await t.dispose(tester);
    });

    testWidgets('anywhere in a column counts, including under the hint', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      // Top-right corner: the Settings column.
      await tester.tapAt(const Offset(790, 10));
      await tester.pump();
      // Bottom-left corner, under the hint line: the Learn column.
      await tester.tapAt(const Offset(10, 590));
      await tester.pump();
      // Again on the highlighted column: plays it again.
      await tester.tapAt(const Offset(200, 100));
      await tester.pump();

      expect(t.patterns, [_settings, _learn, _learn]);
      expect(find.byType(TouchSurface), findsNothing);

      await t.dispose(tester);
    });

    testWidgets('a press shorter than the hold is a tap', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _hold(
        tester,
        at: tester.getCenter(find.text('Settings')),
        duration: const Duration(milliseconds: 900),
      );

      expect(find.byType(LanguagePickerSurface), findsNothing);
      expect(t.patterns, [_settings]);
      expect(_isHighlighted(tester, 'Settings'), isTrue);

      await t.dispose(tester);
    });
  });

  group('swipe', () {
    testWidgets('right moves to the next mode and plays it, wrapping', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _swipe(tester, 200);
      expect(_isHighlighted(tester, 'Settings'), isTrue);
      await _swipe(tester, 200);
      expect(_isHighlighted(tester, 'Learn'), isTrue);

      expect(t.patterns, [_settings, _learn]);
      expect(find.byType(TouchSurface), findsNothing);

      await t.dispose(tester);
    });

    testWidgets('left moves to the previous mode, wrapping', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _swipe(tester, -200);
      expect(_isHighlighted(tester, 'Settings'), isTrue);
      await _swipe(tester, -200);
      expect(_isHighlighted(tester, 'Learn'), isTrue);

      expect(t.patterns, [_settings, _learn]);

      await t.dispose(tester);
    });

    testWidgets('a swipe is measured from where it starts, not by column', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      // Starts on the Settings column and ends on the Learn one, but is one
      // swipe left: Learn -> Settings.
      await tester.dragFrom(const Offset(700, 300), const Offset(-600, 0));
      await tester.pump();

      expect(t.patterns, [_settings]);
      expect(_isHighlighted(tester, 'Settings'), isTrue);

      await t.dispose(tester);
    });

    testWidgets('a short drag replays the highlighted mode', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _swipe(tester, 30);

      expect(t.patterns, [_learn]);
      expect(_isHighlighted(tester, 'Learn'), isTrue);

      await t.dispose(tester);
    });
  });

  group('hold', () {
    testWidgets('on Learn opens the lessons, which start on digit 0', (
      tester,
    ) async {
      final t = _Harness(saved: MorseLanguage.russian);
      await t.pump(tester);
      t.vibration.reset();

      await _hold(tester);
      await _waitForMode(tester);

      expect(find.byType(TouchSurface), findsOneWidget);
      final session = ProviderScope.containerOf(
        tester.element(find.byType(TouchSurface)),
      ).read(sessionNotifierProvider);
      expect(session.language, MorseLanguage.russian);
      expect(session.levelIndex, 0);
      expect(session.positionIndex, 0);
      // The identifier, then the lesson's first item.
      expect(t.patterns, [_learn, _zero]);

      await t.dispose(tester);
    });

    testWidgets('on Settings opens the language picker as a setting', (
      tester,
    ) async {
      final t = _Harness(saved: MorseLanguage.russian);
      await t.pump(tester);
      await _swipe(tester, 200);
      t.vibration.reset();

      await _hold(tester);
      await _waitForMode(tester);
      await tester.pumpAndSettle();

      expect(find.byType(HomeMenuSurface), findsNothing);
      final picker = tester.widget<LanguagePickerSurface>(
        find.byType(LanguagePickerSurface),
      );
      expect(picker.fromMenu, isTrue);
      // The identifier, then the picker announcing the saved language.
      expect(t.patterns, [_settings, _russian]);
      expect(find.byType(TouchSurface), findsNothing);

      await t.dispose(tester);
    });

    testWidgets('enters the mode last felt, wherever the finger is', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      await _swipe(tester, 200);
      t.vibration.reset();

      // Settings is highlighted; the hold is on the Learn column.
      await _hold(tester, at: tester.getCenter(find.text('Learn')));
      await _waitForMode(tester);

      expect(find.byType(LanguagePickerSurface), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.patterns, [_settings, _english]);

      await t.dispose(tester);
    });

    testWidgets('the mode waits for the identifier and a silence after it', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration
        ..reset()
        ..holdNextPattern = true;

      await _hold(tester);
      // However long the identifier plays, the menu stays.
      await tester.pump(_testRepeatPause);
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.patterns, [_learn]);

      // Once it has finished, a short silence still comes first.
      t.vibration.release();
      await tester.pump(_enterPause - const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.patterns, [_learn]);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(t.patterns, [_learn, _zero]);

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
      await tester.tapAt(tester.getCenter(find.text('Settings')));
      await tester.pump();
      await _swipe(tester, 200);
      await _swipe(tester, 20);
      await _hold(tester);
      await t.doubleShake(tester);

      expect(t.patterns, [_learn]);
      expect(_isHighlighted(tester, 'Learn'), isTrue);

      t.vibration.release();
      await _waitForMode(tester);
      expect(find.byType(TouchSurface), findsOneWidget);
      expect(find.byType(LanguagePickerSurface), findsNothing);

      await t.dispose(tester);
    });
  });

  group('shakes', () {
    testWidgets('detection runs while the menu is shown', (tester) async {
      final t = _Harness();
      // The lessons pause detection when they stop.
      t.shake.pause();
      await t.pump(tester);

      expect(t.shake.isPaused, isFalse);

      await t.dispose(tester);
    });

    testWidgets('a double shake replays the highlighted mode once', (
      tester,
    ) async {
      final t = _Harness(highlighted: HomeMenuMode.settings);
      await t.pump(tester);
      t.vibration.reset();

      await t.doubleShake(tester);

      expect(t.patterns, [_settings]);
      expect(_isHighlighted(tester, 'Settings'), isTrue);
      expect(find.byType(HomeMenuSurface), findsOneWidget);

      await t.dispose(tester);
    });

    testWidgets('a single shake does nothing', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      t.shake.addEvent(const Home());
      await tester.pump(const Duration(seconds: 2));

      expect(t.vibration.calls, isEmpty);
      expect(_isHighlighted(tester, 'Learn'), isTrue);

      await t.dispose(tester);
    });

    testWidgets('the mode opened from the menu owns detection', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      await _swipe(tester, 200);

      await _hold(tester);
      await _waitForMode(tester);
      // The menu is gone once the transition ends; detection still runs
      // for the picker's double shake back.
      await tester.pumpAndSettle();
      expect(find.byType(HomeMenuSurface), findsNothing);
      expect(t.shake.isPaused, isFalse);

      await t.dispose(tester);
    });
  });

  group('background', () {
    testWidgets('leaving the foreground cancels the vibration and pauses '
        'shake detection', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      await _sendToBackground(tester);

      expect(t.vibration.callLog, ['cancel']);
      expect(t.shake.isPaused, isTrue);

      // A double shake on its way is ignored.
      await t.doubleShake(tester);
      expect(t.vibration.callLog, ['cancel']);

      await _bringToForeground(tester);
      await t.dispose(tester);
    });

    testWidgets('coming back replays the highlighted mode and resumes shake '
        'detection', (tester) async {
      final t = _Harness();
      await t.pump(tester);
      await _swipe(tester, 200);
      await _sendToBackground(tester);
      t.vibration.reset();

      await _bringToForeground(tester);

      expect(t.patterns, [_settings]);
      expect(t.shake.isPaused, isFalse);
      await t.doubleShake(tester);
      expect(t.patterns, [_settings, _settings]);

      await t.dispose(tester);
    });

    testWidgets('coming back while a mode opens plays nothing more', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);
      t.vibration
        ..reset()
        ..holdNextPattern = true;

      await _hold(tester);
      await _sendToBackground(tester);
      await _bringToForeground(tester);

      expect(t.patterns, [_learn]);

      t.vibration.release();
      await _waitForMode(tester);
      expect(find.byType(TouchSurface), findsOneWidget);

      await t.dispose(tester);
    });

    testWidgets('the menu does not keep the screen on', (tester) async {
      final wakelock = mockWakelock(tester);
      final t = _Harness();
      await t.pump(tester);
      await _swipe(tester, 200);
      await _sendToBackground(tester);
      await _bringToForeground(tester);

      expect(wakelock, isEmpty);

      await t.dispose(tester);
    });
  });

  group('sighted helper', () {
    testWidgets('sees each mode with its letter, name and pattern', (
      tester,
    ) async {
      final t = _Harness();
      await t.pump(tester);

      for (final text in ['L', 'Learn', '· — · ·', 'S', 'Settings', '· · ·']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }

      await t.dispose(tester);
    });

    testWidgets('sees the hint and which mode is highlighted', (tester) async {
      final t = _Harness();
      await t.pump(tester);

      expect(find.text(_helperHint), findsOneWidget);
      expect(_isHighlighted(tester, 'L'), isTrue);
      expect(_isHighlighted(tester, '· — · ·'), isTrue);
      expect(_isHighlighted(tester, 'S'), isFalse);
      expect(_isHighlighted(tester, '· · ·'), isFalse);

      await t.dispose(tester);
    });
  });

  group('screen readers', () {
    testWidgets('see one button per mode, with its name and hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final t = _Harness();
      await t.pump(tester);

      for (final mode in HomeMenuMode.values) {
        // Exactly one node carries the name: the visible texts are
        // excluded, so they are not announced a second time.
        final finder = find.bySemanticsLabel(mode.label);
        expect(finder, findsOneWidget, reason: mode.label);
        final node = tester.getSemantics(finder);
        expect(
          node,
          isSemantics(
            label: mode.label,
            hint: mode.hint,
            isButton: true,
            hasTapAction: true,
          ),
          reason: mode.label,
        );
        expect(node.childrenCount, 0, reason: mode.label);
      }
      expect(find.bySemanticsLabel('L'), findsNothing);
      expect(find.bySemanticsLabel(_helperHint), findsNothing);

      await t.dispose(tester);
      handle.dispose();
    });

    testWidgets('hear the route named "Home menu"', (tester) async {
      final handle = tester.ensureSemantics();
      final t = _Harness();
      await t.pump(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Home menu')),
        isSemantics(label: 'Home menu', namesRoute: true),
      );

      await t.dispose(tester);
      handle.dispose();
    });

    testWidgets('find the highlighted mode selected', (tester) async {
      final handle = tester.ensureSemantics();
      final t = _Harness();
      await t.pump(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Learn')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Settings')),
        isSemantics(isSelected: false),
      );

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Settings')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Learn')),
        isSemantics(isSelected: false),
      );

      await t.dispose(tester);
      handle.dispose();
    });

    testWidgets('open a mode directly, after its identifier', (tester) async {
      final handle = tester.ensureSemantics();
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      tester.semantics.tap(find.semantics.byLabel('Settings'));
      await tester.pump();
      expect(t.patterns, [_settings]);
      expect(find.byType(LanguagePickerSurface), findsNothing);

      await _waitForMode(tester);
      expect(find.byType(LanguagePickerSurface), findsOneWidget);

      await t.dispose(tester);
      handle.dispose();
    });

    testWidgets('a second activation before the route changes is ignored', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final t = _Harness();
      await t.pump(tester);
      t.vibration.reset();

      tester.semantics
        ..tap(find.semantics.byLabel('Settings'))
        ..tap(find.semantics.byLabel('Learn'));
      await _waitForMode(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LanguagePickerSurface), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.patterns.first, _settings);

      await t.dispose(tester);
      handle.dispose();
    });
  });

  group('vibration gate', () {
    testWidgets('no motor shows the no-vibration screen and plays nothing', (
      tester,
    ) async {
      final t = _Harness(probe: FakeVibrationCapabilityProbe(vibrator: false));
      await t.pump(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.text('Learn'), findsNothing);
      expect(t.vibration.calls, isEmpty);
      // The menu is gone without handing over: detection is off.
      expect(t.shake.isPaused, isTrue);

      await t.dispose(tester);
    });

    testWidgets('a mode entered before detection finds no motor is not '
        'opened', (tester) async {
      final gate = Completer<void>();
      final t = _Harness(
        probe: FakeVibrationCapabilityProbe(vibrator: false, gate: gate),
      );
      await t.pump(tester);

      // Detection is slower than the hold.
      t.vibration.holdNextPattern = true;
      await _hold(tester);
      expect(t.patterns, [_learn]);

      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(NoVibrationScreen), findsOneWidget);

      t.vibration.release();
      await _waitForMode(tester);
      await tester.pump(_testRepeatPause);

      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(find.byType(TouchSurface), findsNothing);
      expect(t.patterns, [_learn]);

      await t.dispose(tester);
    });

    testWidgets('a screen-reader activation that lands before the switch to '
        'the no-vibration screen is ignored', (tester) async {
      final handle = tester.ensureSemantics();
      final gate = Completer<void>();
      final t = _Harness(
        probe: FakeVibrationCapabilityProbe(vibrator: false, gate: gate),
      );
      await t.pump(tester);
      expect(find.text('Learn'), findsOneWidget);

      // Detection finishes, but the menu has not been rebuilt yet.
      gate.complete();
      await ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      ).read(vibrationCapabilitiesProvider.future);
      tester.semantics.tap(find.semantics.byLabel('Learn'));
      await tester.pumpAndSettle();

      expect(find.byType(TouchSurface), findsNothing);
      expect(find.byType(NoVibrationScreen), findsOneWidget);
      expect(t.vibration.calls, isEmpty);

      await t.dispose(tester);
      handle.dispose();
    });
  });
}
