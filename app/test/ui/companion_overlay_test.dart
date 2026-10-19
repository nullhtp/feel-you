import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fixed_levels_session.dart';
import '../test_doubles/mock_vibration_service.dart';

/// Long repeat pause to prevent orchestrator from interfering.
const _testRepeatPause = Duration(seconds: 5);

/// Builds a [TouchSurface] (which includes the [CompanionOverlay]) with
/// the given session state.
Widget buildTestWidget({
  required FakeGestureClassifier classifier,
  required MockVibrationService vibration,
  SessionState? initialState,
}) {
  return ProviderScope(
    overrides: [
      gestureClassifierProvider.overrideWithValue(classifier),
      vibrationServiceProvider.overrideWithValue(vibration),
      shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
      teachingTimingConfigProvider.overrideWithValue(
        const TeachingTimingConfig(repeatPause: _testRepeatPause),
      ),
      if (initialState != null)
        sessionNotifierProvider.overrideWith(
          (ref) => _PresetSessionNotifier(initialState),
        ),
    ],
    child: const MaterialApp(home: TouchSurface()),
  );
}

/// A [SessionNotifier] that starts with a custom initial state.
class _PresetSessionNotifier extends SessionNotifier {
  _PresetSessionNotifier(SessionState initial) : super(initial.language) {
    state = initial;
  }
}

/// Cleanly tears down the widget tree.
Future<void> cleanUp(WidgetTester tester) async {
  final finder = find.byType(TouchSurface);
  if (finder.evaluate().isNotEmpty) {
    final element = tester.element(finder);
    final container = ProviderScope.containerOf(element);
    await container.read(teachingOrchestratorProvider.notifier).stop();
  }
  await tester.pumpWidget(const SizedBox());
  await tester.pump(_testRepeatPause);
}

void main() {
  group('CompanionOverlay', () {
    // -----------------------------------------------------------------------
    // The quiz and the learned count
    // -----------------------------------------------------------------------
    group('quiz', () {
      /// The quiz of the digits level, playing "4".
      const inQuiz = SessionState(
        language: MorseLanguage.english,
        positionIndex: 9,
        quizItem: '4',
      );

      ProviderContainer containerOf(WidgetTester tester) =>
          ProviderScope.containerOf(tester.element(find.byType(TouchSurface)));

      Future<void> setPhase(WidgetTester tester, SessionPhase phase) async {
        containerOf(
          tester,
        ).read(sessionNotifierProvider.notifier).setPhase(phase);
        await tester.pump();
      }

      testWidgets('hides the item and its pattern while it plays and while '
          'the user answers', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            classifier: FakeGestureClassifier(),
            vibration: MockVibrationService(),
            initialState: inQuiz,
          ),
        );
        await tester.pump();

        for (final phase in [SessionPhase.playing, SessionPhase.listening]) {
          await setPhase(tester, phase);
          expect(find.text('?'), findsOneWidget, reason: '$phase');
          expect(find.text('4'), findsNothing, reason: '$phase');
          expect(find.text('· · · · —'), findsNothing, reason: '$phase');
        }

        await cleanUp(tester);
      });

      testWidgets('shows the item and its pattern during feedback', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            classifier: FakeGestureClassifier(),
            vibration: MockVibrationService(),
            initialState: inQuiz,
          ),
        );
        await tester.pump();

        await setPhase(tester, SessionPhase.feedback);

        expect(find.text('4'), findsOneWidget);
        expect(find.text('· · · · —'), findsOneWidget);
        expect(find.text('?'), findsNothing);

        await cleanUp(tester);
      });

      testWidgets('shows QUIZ instead of the position', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            classifier: FakeGestureClassifier(),
            vibration: MockVibrationService(),
            initialState: inQuiz,
          ),
        );
        await tester.pump();

        expect(find.text('QUIZ'), findsOneWidget);
        expect(find.text('10/10'), findsNothing);

        await cleanUp(tester);
      });

      testWidgets('shows the learned count of the level', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            classifier: FakeGestureClassifier(),
            vibration: MockVibrationService(),
            initialState: inQuiz,
          ),
        );
        await tester.pump();
        expect(find.text('learned 0/10'), findsOneWidget);

        final digits = containerOf(
          tester,
        ).read(sessionNotifierProvider).currentLevel;
        containerOf(tester).read(learnedItemsProvider.notifier)
          ..add(MorseLanguage.english, digits, '1')
          ..add(MorseLanguage.english, digits, '2');
        await tester.pump();

        expect(find.text('learned 2/10'), findsOneWidget);

        await cleanUp(tester);
      });

      testWidgets('the learned count rises after a correct lesson answer', (
        tester,
      ) async {
        final classifier = FakeGestureClassifier();
        await tester.pumpWidget(
          buildTestWidget(
            classifier: classifier,
            vibration: MockVibrationService(),
            initialState: const SessionState(
              language: MorseLanguage.english,
              positionIndex: 3,
            ),
          ),
        );
        await tester.pump();
        expect(find.text('4/10'), findsOneWidget);
        expect(find.text('learned 0/10'), findsOneWidget);

        // "3" is · · · − −.
        classifier
          ..addEvent(const MorseInput(MorseSignal.dot))
          ..addEvent(
            const InputComplete([
              Signal(MorseSignal.dot),
              Signal(MorseSignal.dot),
              Signal(MorseSignal.dot),
              Signal(MorseSignal.dash),
              Signal(MorseSignal.dash),
            ]),
          );
        await tester.pump();
        // The answer is judged during that frame; the overlay shows it in
        // the next one.
        await tester.pump();

        expect(find.text('learned 1/10'), findsOneWidget);

        await cleanUp(tester);
      });
    });

    // -----------------------------------------------------------------------
    // 4.1 Verify text elements for known session state
    // -----------------------------------------------------------------------
    group('displays correct elements for digits level', () {
      testWidgets(
        'shows current digit, morse pattern, level, progress, phase',
        (tester) async {
          final classifier = FakeGestureClassifier();
          final vibration = MockVibrationService();

          // Position 4 in digits = "4" (index is 0-based)
          await tester.pumpWidget(
            buildTestWidget(
              classifier: classifier,
              vibration: vibration,
              initialState: const SessionState(
                language: MorseLanguage.english,
                levelIndex: 0,
                positionIndex: 4,
                phase: SessionPhase.playing,
              ),
            ),
          );
          await tester.pump();

          // Current symbol — the digit "4"
          expect(find.text('4'), findsOneWidget);

          // Level indicator
          expect(find.text('DIGITS'), findsOneWidget);

          // Position progress (1-indexed: 5/10)
          expect(find.text('5/10'), findsOneWidget);

          // Phase
          expect(find.text('PLAYING'), findsOneWidget);

          // Zone labels
          expect(find.text('DOT'), findsOneWidget);
          expect(find.text('DASH'), findsOneWidget);
          expect(find.text('SUBMIT'), findsOneWidget);

          await cleanUp(tester);
          classifier.dispose();
        },
      );
    });

    group('displays correct elements for letters level', () {
      testWidgets('shows current letter and correct progress', (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        // Position 2 in letters = "C" (A=0, B=1, C=2)
        await tester.pumpWidget(
          buildTestWidget(
            classifier: classifier,
            vibration: vibration,
            initialState: const SessionState(
              language: MorseLanguage.english,
              levelIndex: 1,
              positionIndex: 2,
              phase: SessionPhase.listening,
            ),
          ),
        );
        // Don't pump — that would trigger post-frame callback starting
        // the orchestrator which resets phase to playing.

        // Current letter
        expect(find.text('C'), findsOneWidget);

        // Level
        expect(find.text('LETTERS'), findsOneWidget);

        // Progress (1-indexed: 3/26)
        expect(find.text('3/26'), findsOneWidget);

        // Phase — still listening since orchestrator hasn't started
        expect(find.text('LISTENING'), findsOneWidget);

        await cleanUp(tester);
        classifier.dispose();
      });
    });

    group('displays correct elements for words level', () {
      testWidgets('shows current word and GAP label', (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        // Position 0 in words = "HI"
        await tester.pumpWidget(
          buildTestWidget(
            classifier: classifier,
            vibration: vibration,
            initialState: const SessionState(
              language: MorseLanguage.english,
              levelIndex: 2,
              positionIndex: 0,
              phase: SessionPhase.feedback,
            ),
          ),
        );
        // Don't pump to avoid orchestrator resetting phase.

        // Current word
        expect(find.text('HI'), findsOneWidget);

        // Level
        expect(find.text('WORDS'), findsOneWidget);

        // Progress (1-indexed: 1/20)
        expect(find.text('1/20'), findsOneWidget);

        // Phase — still feedback since orchestrator hasn't started
        expect(find.text('FEEDBACK'), findsOneWidget);

        await cleanUp(tester);
        classifier.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // 4.2 Zone label switches between SUBMIT and GAP
    // -----------------------------------------------------------------------
    group('zone label switching', () {
      testWidgets('shows SUBMIT on digits level', (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(
            classifier: classifier,
            vibration: vibration,
            initialState: const SessionState(
              language: MorseLanguage.english,
              levelIndex: 0,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('SUBMIT'), findsOneWidget);
        expect(find.text('GAP'), findsNothing);

        await cleanUp(tester);
        classifier.dispose();
      });

      testWidgets('shows SUBMIT on letters level', (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(
            classifier: classifier,
            vibration: vibration,
            initialState: const SessionState(
              language: MorseLanguage.english,
              levelIndex: 1,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('SUBMIT'), findsOneWidget);
        expect(find.text('GAP'), findsNothing);

        await cleanUp(tester);
        classifier.dispose();
      });

      testWidgets('shows GAP on words level', (tester) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(
            classifier: classifier,
            vibration: vibration,
            initialState: const SessionState(
              language: MorseLanguage.english,
              levelIndex: 2,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('GAP'), findsOneWidget);
        expect(find.text('SUBMIT'), findsNothing);

        await cleanUp(tester);
        classifier.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // 4.3 Input buffer display
    // -----------------------------------------------------------------------
    group('input buffer display', () {
      testWidgets('shows accumulated symbols', (tester) async {
        // Use a real GestureClassifier to get real buffer behavior.
        final classifier = GestureClassifier(screenWidth: 800);
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gestureClassifierProvider.overrideWithValue(classifier),
              vibrationServiceProvider.overrideWithValue(vibration),
              shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
              teachingTimingConfigProvider.overrideWithValue(
                const TeachingTimingConfig(repeatPause: _testRepeatPause),
              ),
            ],
            child: const MaterialApp(home: TouchSurface()),
          ),
        );
        await tester.pump();

        // Simulate tapping: dot (left, x=100), dash (right, x=600)
        classifier
          ..handleTouch(
            const TouchDown(
              timestamp: Duration(milliseconds: 100),
              position: 100,
            ),
          )
          ..handleTouch(
            const TouchUp(
              timestamp: Duration(milliseconds: 200),
              position: 100,
            ),
          );
        await tester.pump();

        // Should show one dot
        expect(find.text('\u00B7'), findsOneWidget);

        // Add a dash
        classifier
          ..handleTouch(
            const TouchDown(
              timestamp: Duration(milliseconds: 300),
              position: 600,
            ),
          )
          ..handleTouch(
            const TouchUp(
              timestamp: Duration(milliseconds: 400),
              position: 600,
            ),
          );
        await tester.pump();

        // Should show dot space dash
        expect(find.text('\u00B7 \u2014'), findsOneWidget);

        // Stop orchestrator and clean up
        final element = tester.element(find.byType(TouchSurface));
        final container = ProviderScope.containerOf(element);
        await container.read(teachingOrchestratorProvider.notifier).stop();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(_testRepeatPause);
        classifier.dispose();
      });

      testWidgets('clears after submission', (tester) async {
        final classifier = GestureClassifier(screenWidth: 800);
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gestureClassifierProvider.overrideWithValue(classifier),
              vibrationServiceProvider.overrideWithValue(vibration),
              shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
              teachingTimingConfigProvider.overrideWithValue(
                const TeachingTimingConfig(repeatPause: _testRepeatPause),
              ),
            ],
            child: const MaterialApp(home: TouchSurface()),
          ),
        );
        await tester.pump();

        // Add a symbol
        classifier
          ..handleTouch(
            const TouchDown(
              timestamp: Duration(milliseconds: 100),
              position: 100,
            ),
          )
          ..handleTouch(
            const TouchUp(
              timestamp: Duration(milliseconds: 200),
              position: 100,
            ),
          );
        await tester.pump();
        expect(find.text('\u00B7'), findsOneWidget);

        // Submit
        classifier.submitInput();
        await tester.pump();

        // Buffer should be cleared — no dot text in the input buffer area
        // (the main symbol "0" for first digit is still visible)
        expect(classifier.inputBufferNotifier.value, isEmpty);

        // Stop orchestrator and clean up
        final element = tester.element(find.byType(TouchSurface));
        final container = ProviderScope.containerOf(element);
        await container.read(teachingOrchestratorProvider.notifier).stop();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(_testRepeatPause);
        classifier.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // 4.4 Overlay does not intercept touch events
    // -----------------------------------------------------------------------
    group('touch pass-through', () {
      testWidgets('taps pass through IgnorePointer to Listener', (
        tester,
      ) async {
        final classifier = FakeGestureClassifier();
        final vibration = MockVibrationService();

        await tester.pumpWidget(
          buildTestWidget(classifier: classifier, vibration: vibration),
        );
        await tester.pump();

        // Verify CompanionOverlay renders inside the widget tree
        expect(find.byType(CompanionOverlay), findsOneWidget);

        // Tap on the screen — should reach the underlying Listener
        final center = tester.getCenter(find.byType(TouchSurface));
        final gesture = await tester.startGesture(center);
        await gesture.up();

        // The fake classifier should have received the touch events
        expect(classifier.touchEvents, hasLength(2));
        expect(classifier.touchEvents[0], isA<TouchDown>());
        expect(classifier.touchEvents[1], isA<TouchUp>());

        await cleanUp(tester);
        classifier.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // Words display follows Level.kind, not the level index
    // -----------------------------------------------------------------------
    group('words display follows level kind, not level index', () {
      // Order: words (0), letters (1), digits (2).
      final levels = reorderedEnglishLevels();

      // Renders only the overlay, with the session at levelIndex.
      Widget buildOverlay(FakeGestureClassifier classifier, int levelIndex) {
        return ProviderScope(
          overrides: [
            gestureClassifierProvider.overrideWithValue(classifier),
            sessionNotifierProvider.overrideWith(
              (ref) => FixedLevelsSessionNotifier(
                FixedLevelsSessionState(
                  levels: levels,
                  language: MorseLanguage.english,
                  levelIndex: levelIndex,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CompanionOverlay()),
        );
      }

      testWidgets('words level at index 0 shows GAP and letter boundaries', (
        tester,
      ) async {
        final classifier = FakeGestureClassifier();

        await tester.pumpWidget(buildOverlay(classifier, 0));

        expect(find.text('WORDS'), findsOneWidget);
        expect(find.text('HI'), findsOneWidget);
        // H (····) / I (··)
        expect(
          find.text('\u00B7 \u00B7 \u00B7 \u00B7 / \u00B7 \u00B7'),
          findsOneWidget,
        );
        expect(find.text('GAP'), findsOneWidget);
        expect(find.text('SUBMIT'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        classifier.dispose();
      });

      testWidgets('characters level at index 2 shows SUBMIT and signals', (
        tester,
      ) async {
        final classifier = FakeGestureClassifier();

        await tester.pumpWidget(buildOverlay(classifier, 2));

        expect(find.text('DIGITS'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('\u2014 \u2014 \u2014 \u2014 \u2014'), findsOneWidget);
        expect(find.text('SUBMIT'), findsOneWidget);
        expect(find.text('GAP'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        classifier.dispose();
      });
    });
  });
}
