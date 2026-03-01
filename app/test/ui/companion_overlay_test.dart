import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/session/session.dart';
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

        // Position 0 in words = "IT"
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
        expect(find.text('IT'), findsOneWidget);

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
        final fakeClassifier = FakeGestureClassifier();
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
  });
}
