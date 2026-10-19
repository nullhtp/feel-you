import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// The double shake end to end (`shake-gesture`, `touch-surface`): the app's
// real shake detector, with the default ShakeConfig, fed accelerometer
// readings in real time.
//
// A double shake is: shake, pause for 0.7 to 1.5 s, shake again. The pauses
// below keep well clear of both ends.

/// Inside the double-shake window.
const _pauseInsideWindow = Duration(milliseconds: 900);

/// Outside the double-shake window.
const _pauseOutsideWindow = Duration(milliseconds: 1800);

/// The Russian identifier in the picker: Morse Р.
const _russianIdentifier = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RecordingVibrationService vibration;
  late E2EApp app;

  /// Launches a Russian lesson, moves it to digit "1" so that going home
  /// can be seen, and waits until "1" plays.
  Future<void> launchLessonOnOne(WidgetTester tester) async {
    FakeVibrationPlatform().install(tester);
    vibration = RecordingVibrationService();
    app = E2EApp(savedLanguage: MorseLanguage.russian, vibration: vibration);
    await app.launch(tester);
    await waitUntil(
      tester,
      () => vibration.hasPattern(digitZero),
      reason: 'the loop plays digit 0',
    );

    await tester.dragFrom(surfacePoint(tester, 0.3, 0.4), const Offset(200, 0));
    await tester.pump();
    await waitUntil(
      tester,
      () => app.session(tester).currentCharacter == '1',
      reason: 'a swipe right moves to digit 1',
    );
    vibration.reset();
  }

  testWidgets('two shakes 0.9 s apart open the language picker', (
    tester,
  ) async {
    await launchLessonOnOne(tester);

    await app.shake();
    await Future<void>.delayed(_pauseInsideWindow);
    await app.shake();
    await waitUntil(
      tester,
      () => find.byType(LanguagePickerSurface).evaluate().isNotEmpty,
      reason: 'the picker opens',
    );
    await tester.pumpAndSettle();

    expect(find.byType(TouchSurface), findsNothing);
    expect(app.isTeachingRunning(tester), isFalse);
    // The first shake went home before the second opened the picker.
    expect(app.session(tester).currentCharacter, '0');
    // The picker says where the user is: Russian, the current language.
    await waitUntil(
      tester,
      () => vibration.hasPattern(_russianIdentifier),
      reason: 'the picker plays Morse Р',
    );

    await app.close(tester);
  });

  testWidgets('two shakes 1.8 s apart only go home, twice', (tester) async {
    await launchLessonOnOne(tester);

    await app.shake();
    await waitUntil(
      tester,
      () => app.session(tester).currentCharacter == '0',
      reason: 'the first shake goes home',
    );
    await Future<void>.delayed(_pauseOutsideWindow);
    vibration.reset();
    await app.shake();
    await waitFor(tester, const Duration(milliseconds: 500));

    expect(find.byType(LanguagePickerSurface), findsNothing);
    expect(find.byType(TouchSurface), findsOneWidget);
    expect(app.isTeachingRunning(tester), isTrue);
    expect(app.session(tester).currentCharacter, '0');
    // The second shake went home again: the loop restarted on "0".
    expect(vibration.callTypes, contains(VibrationCallType.cancel));
    expect(vibration.hasPattern(digitZero), isTrue);

    await app.close(tester);
  });
}
