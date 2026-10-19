import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// The home menu end to end (`home-menu`, `integration-testing`): the whole
// app from launch, real pointer events, the real shake detector fed
// accelerometer readings, vibrations recorded. The walk goes through the
// menu, Settings, the language picker, Learn, the lesson and the double
// shake back, and checks every vibration call in order.

/// The e2e timing, but a lesson that never repeats its item during a test,
/// so the order of the calls is exact.
const _teaching = TeachingTimingConfig(
  repeatPause: Duration(minutes: 1),
  postFeedbackPause: Duration(milliseconds: 100),
  spellingLetterGap: Duration(milliseconds: 50),
  quizMarkerGap: Duration(milliseconds: 50),
);

/// Names for the vibrations a walk through the menu plays.
const Map<String, List<MorseSignal>> _names = {
  'L': menuLearn,
  'S': menuSettings,
  'E': [MorseSignal.dot],
  'Р': [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot],
  '0': digitZero,
};

/// [call] as a short name: the Morse letter or digit it plays, or its type.
String _describe(VibrationCall call) {
  if (call.type == VibrationCallType.cancel) return 'cancel';
  final signals = call.signals;
  if (signals != null) {
    for (final MapEntry(key: name, value: pattern) in _names.entries) {
      if (listEquals(signals, pattern)) return name;
    }
  }
  return call.toString();
}

/// Every vibration call [vibration] recorded, by name, in order.
List<String> _calls(RecordingVibrationService vibration) =>
    vibration.calls.map(_describe).toList();

/// Whether a screen of type [screen] is shown.
bool _shown(Type screen) => find.byType(screen).evaluate().isNotEmpty;

/// The middle of the screen shown, whatever the simulator's orientation.
Offset _center(WidgetTester tester) =>
    tester.getCenter(find.byType(Scaffold).last);

/// A horizontal swipe a quarter of the screen long: right for [right].
Future<void> _swipe(WidgetTester tester, {required bool right}) async {
  final width = tester.getSize(find.byType(Scaffold).last).width;
  await tester.dragFrom(
    _center(tester),
    Offset((right ? 1 : -1) * width / 4, 0),
  );
  await tester.pump();
}

/// Waits until [vibration] has recorded [count] calls.
Future<void> _waitForCalls(
  WidgetTester tester,
  RecordingVibrationService vibration,
  int count,
) => waitUntil(
  tester,
  () => vibration.calls.length >= count,
  reason: '$count vibration calls, got ${_calls(vibration)}',
);

/// The mode the menu shown highlights.
HomeMenuMode _menuHighlight(WidgetTester tester) =>
    tester.widget<HomeMenuSurface>(find.byType(HomeMenuSurface)).highlighted;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('with a saved language: menu, Settings, picker, menu, Learn, '
      'lesson, and a double shake back to the menu', (tester) async {
    FakeVibrationPlatform().install(tester);
    final vibration = RecordingVibrationService();
    final app = E2EApp(
      savedLanguage: MorseLanguage.english,
      vibration: vibration,
      overrides: [teachingTimingConfigProvider.overrideWithValue(_teaching)],
    );
    await app.launch(tester);

    // The menu says where the user is: L, Learn.
    await _waitForCalls(tester, vibration, 1);
    expect(_shown(HomeMenuSurface), isTrue);
    expect(_menuHighlight(tester), HomeMenuMode.learn);
    expect(_calls(vibration), ['L']);

    // Swipe to Settings, hold: the picker opens on the saved English.
    await _swipe(tester, right: true);
    expect(_calls(vibration), ['L', 'S']);
    await holdToConfirm(tester, find.byType(HomeMenuSurface));
    await waitUntil(
      tester,
      () => _shown(LanguagePickerSurface) && !_shown(HomeMenuSurface),
      reason: 'Settings opens the picker',
    );
    await _waitForCalls(tester, vibration, 4);
    expect(_calls(vibration), ['L', 'S', 'S', 'E']);

    // Tap Russian and hold: saved, and back on the menu, on Settings.
    await tester.tap(find.text('Русский'));
    await tester.pump();
    await holdToConfirm(tester, find.byType(LanguagePickerSurface));
    await waitUntil(
      tester,
      () => _shown(HomeMenuSurface) && !_shown(LanguagePickerSurface),
      reason: 'choosing a language returns to the menu',
    );
    await _waitForCalls(tester, vibration, 7);
    expect(_menuHighlight(tester), HomeMenuMode.settings);
    expect(
      app.container(tester).read(languagePreferenceStoreProvider).read(),
      MorseLanguage.russian,
    );
    expect(_calls(vibration), ['L', 'S', 'S', 'E', 'Р', 'Р', 'S']);

    // Swipe to Learn, hold: the lesson plays digit 0, in Russian.
    await tester.pumpAndSettle();
    await _swipe(tester, right: true);
    await app.openLessons(tester);
    await _waitForCalls(tester, vibration, 10);
    expect(app.session(tester).language, MorseLanguage.russian);
    expect(app.session(tester).currentCharacter, '0');
    expect(app.isTeachingRunning(tester), isTrue);
    expect(_calls(vibration), [
      'L',
      'S',
      'S',
      'E',
      'Р',
      'Р',
      'S',
      'L',
      'L',
      '0',
    ]);

    // Double shake: the first shake goes home (digit 0 again), the second
    // stops the lesson and the menu says L.
    await app.doubleShake();
    await waitUntil(
      tester,
      () => _shown(HomeMenuSurface) && !_shown(TouchSurface),
      reason: 'the double shake opens the menu',
    );
    await _waitForCalls(tester, vibration, 14);
    expect(_menuHighlight(tester), HomeMenuMode.learn);
    expect(app.isTeachingRunning(tester), isFalse);

    expect(_calls(vibration), [
      'L', // the menu appears
      'S', // swipe to Settings
      'S', // hold
      'E', // the picker appears on the saved language
      'Р', // tap Russian
      'Р', // hold
      'S', // the menu appears on Settings
      'L', // swipe to Learn
      'L', // hold
      '0', // the lesson starts
      'cancel', // first shake: home
      '0', // digit 0 again
      'cancel', // second shake: the lesson stops
      'L', // the menu appears on Learn
    ]);

    // On the menu a double shake says where the user is, once.
    await app.doubleShake();
    await _waitForCalls(tester, vibration, 15);
    await waitFor(tester, const Duration(milliseconds: 300));
    expect(_calls(vibration).skip(14), ['L']);
    expect(_shown(HomeMenuSurface), isTrue);

    await app.close(tester);
  });

  testWidgets('first launch: the picker, then the menu on Learn', (
    tester,
  ) async {
    FakeVibrationPlatform().install(tester);
    final vibration = RecordingVibrationService();
    final app = E2EApp(
      vibration: vibration,
      overrides: [teachingTimingConfigProvider.overrideWithValue(_teaching)],
    );
    await app.launch(tester);

    await _waitForCalls(tester, vibration, 1);
    expect(_shown(LanguagePickerSurface), isTrue);
    expect(_shown(HomeMenuSurface), isFalse);
    expect(_calls(vibration), ['E']);

    // Hold: English is chosen and the menu opens on Learn.
    await holdToConfirm(tester, find.byType(LanguagePickerSurface));
    await waitUntil(
      tester,
      () => _shown(HomeMenuSurface) && !_shown(LanguagePickerSurface),
      reason: 'the menu replaces the picker',
    );
    await _waitForCalls(tester, vibration, 3);
    expect(_menuHighlight(tester), HomeMenuMode.learn);
    expect(
      app.container(tester).read(languagePreferenceStoreProvider).read(),
      MorseLanguage.english,
    );
    expect(_calls(vibration), ['E', 'E', 'L']);

    await app.close(tester);
  });
}
