import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

/// Long enough not to fire during the test; flushed explicitly at the end.
const _testRepeatPause = Duration(seconds: 5);

/// Classifier thresholds (production defaults).
const _timing = GestureTimingConfig();

/// Safely past the classifier's silence timeout.
final _pastSilence = Duration(milliseconds: _timing.silenceTimeout + 100);

/// A post-feedback pause longer than the silence timeout, so input tapped
/// during feedback is completed by the silence timeout before the loop
/// resumes (resuming discards it as well).
final _longFeedbackPause = Duration(milliseconds: _timing.silenceTimeout * 3);

/// The English levels, in order: digits, letters, words.
const _lettersLevel = 1;
const _wordsLevel = 2;

// The default test surface is 800x600: x < 400 is a dot and the bottom zone
// starts at y = 510.
const _dotPoint = Offset(100, 300);
const _dashPoint = Offset(700, 300);
const _bottomStrip = Offset(100, 560);

/// A [SessionNotifier] that starts with a custom initial state.
class _PresetSessionNotifier extends SessionNotifier {
  _PresetSessionNotifier(SessionState initial) : super(initial.language) {
    state = initial;
  }
}

/// Pumps a [TouchSurface] backed by the real [GestureClassifier] and
/// teaching orchestrator, starting at [levelIndex] of the English levels,
/// and returns every [GestureEvent] the classifier emits.
Future<List<GestureEvent>> pumpSurface(
  WidgetTester tester, {
  required MockVibrationService vibration,
  int levelIndex = _lettersLevel,
  TeachingTimingConfig timing = const TeachingTimingConfig(
    repeatPause: _testRepeatPause,
  ),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        screenWidthProvider.overrideWithValue(800),
        vibrationServiceProvider.overrideWithValue(vibration),
        shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
        teachingTimingConfigProvider.overrideWithValue(timing),
        sessionNotifierProvider.overrideWith(
          (ref) => _PresetSessionNotifier(
            SessionState(
              language: MorseLanguage.english,
              levelIndex: levelIndex,
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: TouchSurface()),
    ),
  );
  await tester.pump();

  final events = <GestureEvent>[];
  // Cancelled in tear-down: awaiting cancel() inside the fake-async test
  // body stalls the next await.
  final subscription = _container(
    tester,
  ).read(gestureClassifierProvider).events.listen(events.add);
  addTearDown(subscription.cancel);
  return events;
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TouchSurface)));

SessionState _session(WidgetTester tester) =>
    _container(tester).read(sessionNotifierProvider);

List<MorseToken> _inputBuffer(WidgetTester tester) =>
    _container(tester).read(inputBufferProvider).value;

/// Stops the orchestrator, disposes the tree (and with it the classifier)
/// and flushes the orchestrator's pending repeat pause.
Future<void> cleanUp(WidgetTester tester) async {
  await _container(tester).read(teachingOrchestratorProvider.notifier).stop();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(_testRepeatPause);
}

void main() {
  group('the bottom strip', () {
    testWidgets('a tap emits BottomZoneAction, not a dot', (tester) async {
      final events = await pumpSurface(
        tester,
        vibration: MockVibrationService(),
      );

      await tester.tapAt(_bottomStrip);
      await tester.pump();

      expect(events, [const BottomZoneAction()]);

      await cleanUp(tester);
    });

    testWidgets('a tap submits the input on a characters level', (
      tester,
    ) async {
      final vibration = MockVibrationService();
      final events = await pumpSurface(tester, vibration: vibration);

      // "A" is dot dash.
      await tester.tapAt(_dotPoint);
      await tester.tapAt(_dashPoint);
      await tester.pump();
      await tester.tapAt(_bottomStrip);
      await tester.pump();

      expect(events, [
        const MorseInput(MorseSignal.dot),
        const MorseInput(MorseSignal.dash),
        const BottomZoneAction(),
        const InputComplete([
          Signal(MorseSignal.dot),
          Signal(MorseSignal.dash),
        ]),
      ]);
      expect(vibration.callLog, contains('playSuccess'));

      // Submitted once: the silence timer adds no second completion.
      await tester.pump(_pastSilence);
      expect(events.whereType<InputComplete>(), hasLength(1));

      await cleanUp(tester);
    });

    testWidgets('a swipe that starts there still navigates', (tester) async {
      final events = await pumpSurface(
        tester,
        vibration: MockVibrationService(),
      );

      final right = await tester.startGesture(const Offset(10, 560));
      await right.moveBy(const Offset(300, 0));
      await right.up();
      await tester.pump();

      final up = await tester.startGesture(const Offset(100, 590));
      await up.moveBy(const Offset(0, -300));
      await up.up();
      await tester.pump();

      expect(events, [const NavigateNext(), const NavigateUp()]);

      await cleanUp(tester);
    });

    testWidgets('follows a surface height change', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(800, 1000);
      addTearDown(tester.view.reset);

      final events = await pumpSurface(
        tester,
        vibration: MockVibrationService(),
      );

      // 1000 px tall: the zone starts at y = 850, so y = 560 is now a dot.
      await tester.tapAt(_bottomStrip);
      await tester.tapAt(const Offset(100, 900));
      await tester.pump();

      expect(
        _container(tester).read(gestureClassifierProvider).screenHeight,
        1000,
      );
      expect(events.take(2), [
        const MorseInput(MorseSignal.dot),
        const BottomZoneAction(),
      ]);

      await cleanUp(tester);
    });
  });

  // Issue #18: a long hold in the bottom strip emitted Reset and then, on
  // release, a BottomZoneAction as well.
  group('a 2.5 s hold in the bottom strip', () {
    for (final (name, levelIndex) in [
      ('characters', _lettersLevel),
      ('words', _wordsLevel),
    ]) {
      testWidgets('emits exactly one Reset and no BottomZoneAction on a '
          '$name level', (tester) async {
        final vibration = MockVibrationService();
        final events = await pumpSurface(
          tester,
          vibration: vibration,
          levelIndex: levelIndex,
        );

        final hold = await tester.startGesture(_bottomStrip);
        await tester.pump(const Duration(milliseconds: 2500));
        vibration.reset();
        await hold.up();
        await tester.pump(_pastSilence);

        expect(events, [const Reset()]);

        // The replay the Reset started is not interrupted, and no letter
        // gap or submit happens.
        expect(_session(tester).phase, SessionPhase.playing);
        expect(vibration.callLog, isNot(contains('cancel')));
        expect(vibration.callLog, isNot(contains('playTapFeedback')));
        expect(_inputBuffer(tester), isEmpty);

        await cleanUp(tester);
      });
    }
  });

  // Issue #19: a bottom-strip tap the orchestrator ignores left input that
  // was buffered before it without a silence timer.
  //
  // Resuming the loop after feedback discards such input too (#21), so the
  // feedback pause is longer than the silence timeout here: the silence
  // timeout has to clear the dot while the feedback is still on.
  testWidgets('a dot tapped during feedback, then an ignored bottom-strip '
      'tap, is cleared by the silence timeout', (tester) async {
    final vibration = MockVibrationService();
    final events = await pumpSurface(
      tester,
      vibration: vibration,
      timing: TeachingTimingConfig(
        repeatPause: _testRepeatPause,
        postFeedbackPause: _longFeedbackPause,
      ),
    );

    // Answer "A" (dot dash) correctly; the success feedback starts.
    await tester.tapAt(_dotPoint);
    await tester.tapAt(_dashPoint);
    await tester.pump(_pastSilence);
    expect(_session(tester).phase, SessionPhase.feedback);
    expect(vibration.callLog, contains('playSuccess'));
    events.clear();
    vibration.reset();

    // During the feedback, a dot is buffered (and ignored by the
    // orchestrator), then the bottom strip is tapped (also ignored).
    await tester.tapAt(_dotPoint);
    await tester.pump();
    await tester.tapAt(_bottomStrip);
    await tester.pump();
    expect(_session(tester).phase, SessionPhase.feedback);
    expect(vibration.callLog, isNot(contains('playTapFeedback')));
    expect(_inputBuffer(tester), [const Signal(MorseSignal.dot)]);

    // The silence timeout still completes the stale dot, so it is not left
    // in the buffer. The orchestrator is no longer listening and ignores it.
    await tester.pump(_pastSilence);
    expect(events, [
      const MorseInput(MorseSignal.dot),
      const BottomZoneAction(),
      const InputComplete([Signal(MorseSignal.dot)]),
    ]);
    expect(_inputBuffer(tester), isEmpty);
    expect(_session(tester).phase, SessionPhase.feedback);
    expect(vibration.callLog, isNot(contains('playError')));

    // The loop resumes once the feedback pause is over.
    await tester.pump(_longFeedbackPause);
    expect(_session(tester).phase, SessionPhase.playing);

    // The next correct answer is judged correct: no stale dot in front.
    vibration.reset();
    await tester.tapAt(_dotPoint);
    await tester.tapAt(_dashPoint);
    await tester.pump(_pastSilence);
    expect(
      events.last,
      const InputComplete([Signal(MorseSignal.dot), Signal(MorseSignal.dash)]),
    );
    expect(vibration.callLog, contains('playSuccess'));
    expect(vibration.callLog, isNot(contains('playError')));

    await cleanUp(tester);
  });
}
