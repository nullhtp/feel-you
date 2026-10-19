import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// Background suspension end to end (`app-lifecycle`): the real app, the
// real wakelock plugin, vibrations recorded.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RecordingVibrationService vibration;
  late E2EApp app;

  /// Launches the app with English saved, opens the lessons from the home
  /// menu, on digit "0", and waits until the loop has played it.
  Future<void> launchLesson(WidgetTester tester) async {
    FakeVibrationPlatform().install(tester);
    vibration = RecordingVibrationService();
    app = E2EApp(savedLanguage: MorseLanguage.english, vibration: vibration);
    await app.launch(tester);
    await app.openLessons(tester);
    expect(find.byType(TouchSurface), findsOneWidget);
    await waitUntil(
      tester,
      () => vibration.hasPattern(digitZero),
      reason: 'the loop plays digit 0',
    );
  }

  testWidgets('the background stops the loop and releases the wakelock; the '
      'foreground replays the item from its start', (tester) async {
    await launchLesson(tester);
    expect(app.isTeachingRunning(tester), isTrue);
    await expectWakelock(enabled: true);

    vibration.reset();
    sendToBackground(tester);

    expect(app.isTeachingRunning(tester), isFalse);
    expect(vibration.callTypes, [VibrationCallType.cancel]);
    await expectWakelock(enabled: false);

    // Several repeat pauses: nothing vibrates while in the background.
    vibration.reset();
    await waitFor(tester, e2eTeachingConfig.repeatPause * 4);
    expect(vibration.calls, isEmpty);

    await bringToForeground(tester);
    await waitUntil(
      tester,
      () => vibration.patterns.isNotEmpty,
      reason: 'the loop starts again',
    );

    expect(app.isTeachingRunning(tester), isTrue);
    await expectWakelock(enabled: true);
    expect(app.session(tester).currentCharacter, '0');
    expect(app.session(tester).phase, SessionPhase.playing);
    // From its first element: the whole pattern of "0".
    expect(vibration.patterns.first, digitZero);

    // It keeps repeating after the resume.
    await waitUntil(
      tester,
      () => vibration.patterns.length >= 2,
      reason: 'the item repeats',
    );

    await app.close(tester);
  });

  testWidgets('a finger held across the trip makes no dot and no reset', (
    tester,
  ) async {
    await launchLesson(tester);
    final events = <GestureEvent>[];
    final subscription = app
        .container(tester)
        .read(gestureClassifierProvider)
        .events
        .listen(events.add);

    final finger = await tester.startGesture(dotPoint(tester));
    sendToBackground(tester);

    // Longer than the long hold, which would emit a Reset.
    await waitFor(
      tester,
      Duration(milliseconds: e2eGestureConfig.resetMinDuration * 2),
    );
    await bringToForeground(tester);
    await finger.up();
    await waitFor(tester, const Duration(milliseconds: 300));

    expect(events, isNot(contains(isA<Reset>())));
    expect(events, isNot(contains(isA<MorseInput>())));
    expect(app.inputBuffer(tester), isEmpty);
    expect(app.session(tester).currentCharacter, '0');
    expect(app.session(tester).phase, SessionPhase.playing);
    expect(app.isTeachingRunning(tester), isTrue);

    await subscription.cancel();
    await app.close(tester);
  });

  testWidgets('a half-entered answer is never judged', (tester) async {
    await launchLesson(tester);

    await tapAt(tester, dashPoint(tester));
    expect(app.session(tester).phase, SessionPhase.listening);
    expect(app.inputBuffer(tester), hasLength(1));

    sendToBackground(tester);
    expect(app.inputBuffer(tester), isEmpty);

    // Past the silence timeout, in the background and after the return.
    final silence = Duration(milliseconds: e2eGestureConfig.silenceTimeout);
    await waitFor(tester, silence * 1.5);
    await bringToForeground(tester);
    await waitFor(tester, silence * 1.5);

    expect(vibration.callTypes, isNot(contains(VibrationCallType.playSuccess)));
    expect(vibration.callTypes, isNot(contains(VibrationCallType.playError)));
    expect(app.session(tester).phase, SessionPhase.playing);

    await app.close(tester);
  });
}
