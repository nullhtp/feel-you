import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// Background suspension end to end (`app-lifecycle`): the real app, the
// real wakelock plugin, vibrations recorded. Then the same trip on the
// screens built on the touch chooser, the language picker and the home
// menu (`language-selection`, `home-menu`): nothing vibrates in the
// background, and the return says where the user is.

/// Records like [RecordingVibrationService], but each playback lasts
/// [playFor] unless it is cancelled or replaced first, as on a motor, so a
/// test can leave the foreground while an identifier is still playing.
class _MotorVibrationService extends RecordingVibrationService {
  _MotorVibrationService({required this.playFor});

  /// How long each playback lasts when nothing stops it.
  final Duration playFor;

  Completer<void>? _playback;

  /// Whether a playback has started and neither ended nor been cancelled.
  bool get isPlaying {
    final playback = _playback;
    return playback != null && !playback.isCompleted;
  }

  void _stop() {
    final playback = _playback;
    if (playback != null && !playback.isCompleted) playback.complete();
  }

  @override
  Future<void> playTokens(List<TactileToken> tokens) async {
    await super.playTokens(tokens);
    // A new vibration replaces the one in progress.
    _stop();
    final playback = _playback = Completer<void>();
    final end = Timer(playFor, _stop);
    await playback.future;
    end.cancel();
  }

  @override
  Future<void> cancel() {
    // At once, as the motor stops.
    _stop();
    return super.cancel();
  }
}

/// Morse Р, the Russian identifier in the picker.
const _russian = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

/// Morse E, the English identifier in the picker.
const _english = [MorseSignal.dot];

/// A screen built on the touch chooser, how the test moves its highlight,
/// and what a hold opens.
enum _ChooserScreen {
  firstLaunchPicker(
    'the first-launch picker',
    shows: LanguagePickerSurface,
    moved: _russian,
    opens: HomeMenuSurface,
    opensWith: menuLearn,
  ),
  pickerFromSettings(
    'the picker opened from Settings',
    shows: LanguagePickerSurface,
    moved: _russian,
    opens: HomeMenuSurface,
    opensWith: menuSettings,
  ),
  menu(
    'the home menu',
    shows: HomeMenuSurface,
    moved: menuSettings,
    opens: LanguagePickerSurface,
    opensWith: _english,
  );

  const _ChooserScreen(
    this.description, {
    required this.shows,
    required this.moved,
    required this.opens,
    required this.opensWith,
  });

  final String description;

  /// The screen's widget.
  final Type shows;

  /// The identifier of the option the test moves the highlight to: Russian
  /// in the pickers (a tap), Settings on the menu (a swipe).
  final List<MorseSignal> moved;

  /// The screen a hold on that option opens.
  final Type opens;

  /// The identifier that screen announces itself with.
  final List<MorseSignal> opensWith;

  bool get isPicker => shows == LanguagePickerSurface;
}

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

  // The language picker and the home menu share the touch chooser, so they
  // share its lifecycle (#98). The menu runs the same checks as the two
  // pickers, as the reference they must match.
  group('screens built on the chooser', () {
    late _MotorVibrationService motor;

    bool shown(Type screen) => find.byType(screen).evaluate().isNotEmpty;

    /// The middle of the screen shown, whatever the simulator's
    /// orientation.
    Offset center(WidgetTester tester) =>
        tester.getCenter(find.byType(Scaffold).last);

    /// Waits until no identifier is playing.
    Future<void> waitForSilence(WidgetTester tester) => waitUntil(
      tester,
      () => !motor.isPlaying,
      reason: 'the identifier ends',
    );

    /// Launches the app and opens [screen], with [postFeedbackPause] after
    /// a hold's identifier, then waits until it has announced itself.
    Future<void> open(
      WidgetTester tester,
      _ChooserScreen screen, {
      Duration? postFeedbackPause,
    }) async {
      FakeVibrationPlatform().install(tester);
      motor = _MotorVibrationService(
        playFor: const Duration(milliseconds: 800),
      );
      app = E2EApp(
        savedLanguage: screen == _ChooserScreen.firstLaunchPicker
            ? null
            : MorseLanguage.english,
        vibration: motor,
        overrides: [
          if (postFeedbackPause != null)
            teachingTimingConfigProvider.overrideWithValue(
              TeachingTimingConfig(
                repeatPause: e2eTeachingConfig.repeatPause,
                postFeedbackPause: postFeedbackPause,
                spellingLetterGap: e2eTeachingConfig.spellingLetterGap,
                quizMarkerGap: e2eTeachingConfig.quizMarkerGap,
              ),
            ),
        ],
      );
      await app.launch(tester);
      if (screen == _ChooserScreen.pickerFromSettings) {
        // Settings, on the menu the launch lands on.
        await waitUntil(
          tester,
          () => shown(HomeMenuSurface),
          reason: 'the home menu is shown',
        );
        await tester.pumpAndSettle();
        await tester.dragFrom(center(tester), const Offset(200, 0));
        await tester.pump();
        await holdToConfirm(tester, find.byType(HomeMenuSurface));
      }
      await waitUntil(
        tester,
        () =>
            shown(screen.shows) &&
            !shown(screen.opens) &&
            motor.patterns.isNotEmpty,
        reason: '${screen.description} is shown',
      );
      // Let the route transition end, so touches land on this screen.
      await tester.pumpAndSettle();
      await waitUntil(
        tester,
        () =>
            motor.patterns.isNotEmpty &&
            listEquals(
              motor.patterns.last,
              screen == _ChooserScreen.menu ? menuLearn : _english,
            ),
        reason: '${screen.description} announces itself',
      );
      await waitForSilence(tester);
    }

    /// Moves the highlight as a user would: a tap on Русский in the
    /// pickers, a swipe right to Settings on the menu. Its identifier
    /// starts playing.
    Future<void> moveHighlight(WidgetTester tester, _ChooserScreen screen) {
      if (screen.isPicker) {
        return tapAt(tester, tester.getCenter(find.text('Русский')));
      }
      return tester
          .dragFrom(center(tester), const Offset(200, 0))
          .then((_) => tester.pump());
    }

    for (final screen in _ChooserScreen.values) {
      testWidgets('${screen.description}: leaving while an identifier plays '
          'cancels it, nothing vibrates in the background, and the return '
          'plays it again', (tester) async {
        await open(tester, screen);
        motor.reset();

        await moveHighlight(tester, screen);
        expect(motor.patterns, [screen.moved]);
        expect(motor.isPlaying, isTrue, reason: 'the identifier still plays');

        sendToBackground(tester);
        expect(motor.callTypes, [
          VibrationCallType.playMorsePattern,
          VibrationCallType.cancel,
        ]);
        expect(motor.isPlaying, isFalse);

        // Longer than any identifier: nothing vibrates while away.
        motor.reset();
        await waitFor(tester, const Duration(milliseconds: 1500));
        expect(motor.calls, isEmpty);

        await bringToForeground(tester);
        await waitUntil(
          tester,
          () => motor.patterns.isNotEmpty,
          reason: 'the return plays the highlighted identifier',
        );
        await waitForSilence(tester);
        expect(motor.patterns, [screen.moved]);
        expect(shown(screen.shows), isTrue);
        expect(shown(screen.opens), isFalse);

        await app.close(tester);
      });

      testWidgets('${screen.description}: leaving during the silence after '
          'a hold plays nothing more there, and the next screen opens on the '
          'return', (tester) async {
        // A long silence after the hold's identifier, to leave in.
        await open(
          tester,
          screen,
          postFeedbackPause: const Duration(milliseconds: 1500),
        );
        await moveHighlight(tester, screen);
        await waitForSilence(tester);
        motor.reset();

        await holdToConfirm(tester, find.byType(screen.shows));
        await waitUntil(
          tester,
          () => motor.patterns.isNotEmpty && !motor.isPlaying,
          reason: "the hold's identifier ends",
        );
        expect(motor.patterns, [screen.moved]);
        expect(shown(screen.opens), isFalse);

        sendToBackground(tester);
        // Past the silence: the choice completes while away, silently.
        await waitFor(tester, const Duration(milliseconds: 2500));
        expect(motor.callTypes, [
          VibrationCallType.playMorsePattern,
          VibrationCallType.cancel,
        ]);

        await bringToForeground(tester);
        await waitUntil(
          tester,
          () => shown(screen.opens) && motor.patterns.length >= 2,
          reason: 'the next screen opens and announces itself',
        );
        await tester.pumpAndSettle();
        await waitForSilence(tester);
        expect(shown(screen.shows), isFalse);
        // The next screen's identifier only: no replay of the hold's.
        expect(motor.patterns, [screen.moved, screen.opensWith]);
        if (screen.isPicker) {
          expect(
            app.container(tester).read(languagePreferenceStoreProvider).read(),
            MorseLanguage.russian,
          );
          expect(app.session(tester).language, MorseLanguage.russian);
        }

        await app.close(tester);
      });
    }
  });
}
