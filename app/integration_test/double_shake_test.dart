import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// The double shake end to end (`shake-gesture`, `touch-surface`,
// `home-menu`): the app's real shake detector, with the default
// ShakeConfig, fed accelerometer readings in real time.
//
// A double shake is: shake, pause for 0.7 to 1.5 s, shake again. The pauses
// below keep well clear of both ends.

/// Inside the double-shake window.
const _pauseInsideWindow = doubleShakePause;

/// Outside the double-shake window.
const _pauseOutsideWindow = Duration(milliseconds: 1800);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RecordingVibrationService vibration;
  late E2EApp app;

  /// Launches the app with Russian saved, opens a Russian lesson from the
  /// home menu, moves it to digit "1" so that going home can be seen, and
  /// waits until "1" plays.
  Future<void> launchLessonOnOne(WidgetTester tester) async {
    FakeVibrationPlatform().install(tester);
    vibration = RecordingVibrationService();
    app = E2EApp(savedLanguage: MorseLanguage.russian, vibration: vibration);
    await app.launch(tester);
    await app.openLessons(tester);
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

  testWidgets('two shakes 0.9 s apart open the home menu', (tester) async {
    await launchLessonOnOne(tester);

    await app.shake();
    await Future<void>.delayed(_pauseInsideWindow);
    await app.shake();
    await waitUntil(
      tester,
      () => find.byType(HomeMenuSurface).evaluate().isNotEmpty,
      reason: 'the menu opens',
    );
    await tester.pumpAndSettle();

    expect(find.byType(TouchSurface), findsNothing);
    expect(find.byType(LanguagePickerSurface), findsNothing);
    expect(app.isTeachingRunning(tester), isFalse);
    // The first shake went home before the second opened the menu.
    expect(app.session(tester).currentCharacter, '0');
    // The language is untouched.
    expect(app.session(tester).language, MorseLanguage.russian);
    // The menu is on the mode the user came from, and says so: Morse L.
    expect(
      tester.widget<HomeMenuSurface>(find.byType(HomeMenuSurface)).highlighted,
      HomeMenuMode.learn,
    );
    await waitUntil(
      tester,
      () => vibration.hasPattern(menuLearn),
      reason: 'the menu plays Morse L',
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

    expect(find.byType(HomeMenuSurface), findsNothing);
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
