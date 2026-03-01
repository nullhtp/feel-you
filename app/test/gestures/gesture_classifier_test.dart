import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Screen width used for all tests. Midpoint = 400.
  const testScreenWidth = 800.0;

  // Positions for left (dot) and right (dash) halves.
  const leftX = 100.0; // < 400 → dot
  const rightX = 600.0; // >= 400 → dash
  const midpointX = 400.0; // exactly midpoint → dash

  late GestureClassifier classifier;
  late List<GestureEvent> events;
  late StreamSubscription<GestureEvent> subscription;

  setUp(() {
    classifier = GestureClassifier(screenWidth: testScreenWidth);
    events = [];
    subscription = classifier.events.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    classifier.dispose();
  });

  // Helper: simulate tap at given position with given duration in ms.
  void tap(int durationMs, {double startX = leftX, double? endX}) {
    endX ??= startX;
    const start = Duration(milliseconds: 100);
    final end = start + Duration(milliseconds: durationMs);
    classifier
      ..handleTouch(TouchDown(timestamp: start, position: startX))
      ..handleTouch(TouchUp(timestamp: end, position: endX));
  }

  // Allow microtask queue to drain so stream events are delivered.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('position-based tap classification', () {
    test('tap on left half produces dot', () async {
      tap(100, startX: leftX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);
    });

    test('tap on right half produces dash', () async {
      tap(100, startX: rightX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dash)]);
    });

    test('tap at exact midpoint produces dash (inclusive to right)', () async {
      tap(100, startX: midpointX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dash)]);
    });

    test('tap near left edge produces dot', () async {
      tap(100, startX: 10);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);
    });

    test('tap near right edge produces dash', () async {
      tap(100, startX: 790);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dash)]);
    });

    test('tap duration does not affect classification', () async {
      // Short tap on left = dot
      tap(50, startX: leftX);
      await pump();
      expect(events.last, const MorseInput(MorseSignal.dot));

      // Long tap on left = still dot
      tap(400, startX: leftX);
      await pump();
      expect(events.last, const MorseInput(MorseSignal.dot));

      // Short tap on right = dash
      tap(50, startX: rightX);
      await pump();
      expect(events.last, const MorseInput(MorseSignal.dash));
    });

    test('different screen width changes midpoint', () async {
      await subscription.cancel();
      classifier.dispose();

      classifier = GestureClassifier(screenWidth: 1000);
      events = [];
      subscription = classifier.events.listen(events.add);

      // Midpoint is now 500. Position 450 is left half (dot).
      tap(100, startX: 450);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);

      // Position 550 is right half (dash).
      tap(100, startX: 550);
      await pump();
      expect(events.last, const MorseInput(MorseSignal.dash));
    });
  });

  group('previously dead-zone taps now classified by position', () {
    test('tap at 800ms on left half produces dot', () async {
      tap(800, startX: leftX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);
    });

    test('tap at 800ms on right half produces dash', () async {
      tap(800, startX: rightX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dash)]);
    });

    test('tap at 1500ms on left half produces dot', () async {
      tap(1500, startX: leftX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);
    });

    test('tap at 1500ms on right half produces dash', () async {
      tap(1500, startX: rightX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dash)]);
    });
  });

  group('reset via long hold', () {
    test('hold > 2000ms emits Reset', () async {
      const start = Duration(milliseconds: 100);
      classifier.handleTouch(
        const TouchDown(timestamp: start, position: leftX),
      );

      // Wait for the reset timer to fire.
      await Future<void>.delayed(const Duration(milliseconds: 2100));

      expect(events, [const Reset()]);

      // Release should not produce additional events.
      classifier.handleTouch(
        TouchUp(
          timestamp: start + const Duration(milliseconds: 2500),
          position: leftX,
        ),
      );
      await pump();
      expect(events, [const Reset()]);
    });

    test('release before 2000ms classifies by position (not reset)', () async {
      // 1900ms tap on left half — should produce dot, not reset.
      tap(1900, startX: leftX);
      // Allow time for any timer to fire that shouldn't.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(events, [const MorseInput(MorseSignal.dot)]);
    });
  });

  group('silence timeout and input completion', () {
    test('silence after input triggers InputComplete', () async {
      tap(100, startX: leftX); // dot
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);

      // Wait for silence timeout.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(events, [
        const MorseInput(MorseSignal.dot),
        InputComplete([Signal(MorseSignal.dot)]),
      ]);
    });

    test('multiple inputs accumulate before completion', () async {
      tap(100, startX: leftX); // dot
      await Future<void>.delayed(const Duration(milliseconds: 200));
      tap(100, startX: rightX); // dash

      // Wait for silence timeout from last input.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(events, [
        const MorseInput(MorseSignal.dot),
        const MorseInput(MorseSignal.dash),
        InputComplete([Signal(MorseSignal.dot), Signal(MorseSignal.dash)]),
      ]);
    });

    test('continued tapping resets the timer', () async {
      tap(100, startX: leftX); // dot
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // Timer hasn't fired yet. Tap again to reset it.
      tap(100, startX: rightX); // dash

      // Wait less than the full timeout from the second tap.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      // Should not have InputComplete yet.
      expect(events.whereType<InputComplete>().toList(), isEmpty);

      // Now wait for full timeout to elapse.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([Signal(MorseSignal.dot), Signal(MorseSignal.dash)]),
      ]);
    });

    test('no completion without prior input', () async {
      // Just wait — no taps.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(events, isEmpty);
    });
  });

  group('insertCharGap', () {
    test('inserts charGap when buffer is non-empty', () async {
      tap(100, startX: leftX); // dot
      await pump();

      classifier.insertCharGap();
      // Now add another symbol after the charGap.
      tap(100, startX: rightX); // dash

      // Wait for silence timeout to get InputComplete.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([
          Signal(MorseSignal.dot),
          const CharGap(),
          Signal(MorseSignal.dash),
        ]),
      ]);
    });

    test('does nothing when buffer is empty', () async {
      classifier.insertCharGap();
      await pump();

      // No events should be emitted.
      expect(events, isEmpty);

      // Wait for silence timeout — nothing should happen.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(events, isEmpty);
    });

    test('restarts silence timer', () async {
      tap(100, startX: leftX); // dot
      await pump();

      // Wait 800ms (close to 1000ms timeout).
      await Future<void>.delayed(const Duration(milliseconds: 800));

      // Insert charGap — this should restart the timer.
      classifier.insertCharGap();

      // Wait 800ms more — should NOT have InputComplete yet (timer restarted).
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(events.whereType<InputComplete>().toList(), isEmpty);

      // Wait for full timeout from the insertCharGap call.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      // Trailing charGap should be stripped by the silence timer.
      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([Signal(MorseSignal.dot)]),
      ]);
    });
  });

  group('submitInput', () {
    test('emits InputComplete with buffer contents', () async {
      tap(100, startX: leftX); // dot
      await Future<void>.delayed(const Duration(milliseconds: 100));
      tap(100, startX: rightX); // dash
      await pump();

      classifier.submitInput();
      await pump();

      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([Signal(MorseSignal.dot), Signal(MorseSignal.dash)]),
      ]);
    });

    test('clears buffer after submit', () async {
      tap(100, startX: leftX); // dot
      await pump();

      classifier.submitInput();
      await pump();

      // Wait for silence timeout — should not emit another InputComplete.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(events.whereType<InputComplete>().toList(), hasLength(1));
    });

    test('does nothing when buffer is empty', () async {
      classifier.submitInput();
      await pump();

      expect(events, isEmpty);
    });

    test('includes charGap in submitted buffer', () async {
      tap(100, startX: leftX); // dot
      await Future<void>.delayed(const Duration(milliseconds: 50));
      tap(100, startX: leftX); // dot
      await pump();

      classifier.insertCharGap();
      tap(100, startX: rightX); // dash
      await pump();

      classifier.submitInput();
      await pump();

      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([
          Signal(MorseSignal.dot),
          Signal(MorseSignal.dot),
          const CharGap(),
          Signal(MorseSignal.dash),
        ]),
      ]);
    });
  });

  group('emitEvent', () {
    test('emits provided event on the stream', () async {
      classifier.emitEvent(const BottomZoneAction());
      await pump();
      expect(events, [const BottomZoneAction()]);
    });

    test('emits multiple events in order', () async {
      classifier.emitEvent(const BottomZoneAction());
      classifier.emitEvent(const NavigateNext());
      await pump();
      expect(events, [const BottomZoneAction(), const NavigateNext()]);
    });
  });

  group('silence timeout fallback', () {
    test('silence timeout still works as InputComplete fallback', () async {
      tap(100, startX: leftX); // dot
      await pump();

      // Wait for silence timeout (1000ms).
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([Signal(MorseSignal.dot)]),
      ]);
    });

    test('no auto charGap inserted during silence', () async {
      tap(100, startX: leftX); // dot
      // Wait 600ms (would have triggered charGap in old behavior).
      await Future<void>.delayed(const Duration(milliseconds: 600));
      tap(100, startX: rightX); // dash

      // Wait for silence timeout.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // Should be [dot, dash] with NO charGap (auto-insertion removed).
      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([Signal(MorseSignal.dot), Signal(MorseSignal.dash)]),
      ]);
    });

    test('trailing charGap stripped on silence timeout', () async {
      tap(100, startX: leftX); // dot
      await pump();
      classifier.insertCharGap();

      // Wait for silence timeout — trailing charGap should be stripped.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(events.whereType<InputComplete>().toList(), [
        InputComplete([Signal(MorseSignal.dot)]),
      ]);
    });
  });

  group('swipe detection', () {
    test('swipe right emits NavigateNext', () async {
      // Fast swipe: 100ms across 100px = 1000px/s.
      tap(100, startX: 0, endX: 100);
      await pump();
      expect(events, contains(const NavigateNext()));
    });

    test('swipe left emits NavigatePrevious', () async {
      tap(100, startX: 100, endX: 0);
      await pump();
      expect(events, contains(const NavigatePrevious()));
    });

    test('slow swipe is ignored', () async {
      // Slow swipe: 1000ms across 60px = 60px/s (below 200px/s threshold).
      tap(1000, startX: 0, endX: 60);
      await pump();
      // Not a swipe due to low velocity; classified by position (left = dot).
      expect(events.whereType<NavigateNext>().toList(), isEmpty);
      expect(events.whereType<NavigatePrevious>().toList(), isEmpty);
    });

    test('short swipe is ignored', () async {
      // Short swipe: 50ms across 30px (below 50px threshold).
      tap(50, startX: 0, endX: 30);
      await pump();
      // Should be classified by position (left half = dot), not a swipe.
      expect(events, [const MorseInput(MorseSignal.dot)]);
    });

    test('swipe is not also classified as morse input', () async {
      tap(100, startX: 0, endX: 100);
      await pump();
      // Should only have NavigateNext, no MorseInput.
      expect(events.whereType<MorseInput>().toList(), isEmpty);
    });

    test('swipe takes priority over position classification', () async {
      // Swipe starting from right half — should be NavigateNext, not dash.
      tap(100, startX: rightX, endX: rightX + 100);
      await pump();
      expect(events, [const NavigateNext()]);
      expect(events.whereType<MorseInput>().toList(), isEmpty);
    });
  });

  group('input buffer reset', () {
    test('swipe clears accumulated input', () async {
      tap(100, startX: leftX); // dot
      await pump();
      expect(events.last, const MorseInput(MorseSignal.dot));

      // Swipe right before silence timeout.
      tap(100, startX: 0, endX: 100);
      await pump();
      expect(events.last, const NavigateNext());

      // Wait for silence timeout — should not emit InputComplete.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(events.whereType<InputComplete>().toList(), isEmpty);
    });

    test('reset clears accumulated input', () async {
      tap(100, startX: leftX); // dot
      await pump();
      expect(events.last, const MorseInput(MorseSignal.dot));

      // Long hold to trigger reset.
      const start = Duration(milliseconds: 5000);
      classifier.handleTouch(
        const TouchDown(timestamp: start, position: leftX),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(events.last, const Reset());

      // Release.
      classifier.handleTouch(
        TouchUp(
          timestamp: start + const Duration(milliseconds: 2500),
          position: leftX,
        ),
      );
      await pump();

      // Wait for silence timeout — should not emit InputComplete.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(events.whereType<InputComplete>().toList(), isEmpty);
    });
  });

  group('stream behavior', () {
    test('multiple subscribers receive events', () async {
      final events2 = <GestureEvent>[];
      final sub2 = classifier.events.listen(events2.add);

      tap(100, startX: leftX); // dot
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);
      expect(events2, [const MorseInput(MorseSignal.dot)]);

      await sub2.cancel();
    });

    test('events arrive in order', () async {
      tap(100, startX: leftX); // dot
      tap(100, startX: rightX); // dash
      await pump();
      expect(events, [
        const MorseInput(MorseSignal.dot),
        const MorseInput(MorseSignal.dash),
      ]);
    });
  });

  group('vertical swipe detection', () {
    // Helper for vertical swipe: short duration, large vertical displacement.
    void verticalSwipe({
      required double startY,
      required double endY,
      int durationMs = 100,
    }) {
      const start = Duration(milliseconds: 100);
      final end = start + Duration(milliseconds: durationMs);
      classifier
        ..handleTouch(TouchDown(timestamp: start, position: leftX, y: startY))
        ..handleTouch(TouchUp(timestamp: end, position: leftX, y: endY));
    }

    test('swipe up emits NavigateUp', () async {
      // Upward swipe: startY=300, endY=100 → dy=-200, distance=200 > 50
      verticalSwipe(startY: 300, endY: 100);
      await pump();
      expect(events, [const NavigateUp()]);
    });

    test('swipe down emits NavigateDown', () async {
      // Downward swipe: startY=100, endY=300 → dy=200
      verticalSwipe(startY: 100, endY: 300);
      await pump();
      expect(events, [const NavigateDown()]);
    });

    test('slow vertical swipe is ignored', () async {
      // Distance=200 but duration=2000ms → velocity=100px/s < 200
      verticalSwipe(startY: 100, endY: 300, durationMs: 2000);
      // Will be classified as a tap (not a swipe), so should emit MorseInput
      await pump();
      expect(events.whereType<NavigateDown>(), isEmpty);
    });

    test('short vertical swipe is ignored', () async {
      // Distance=30 < 50px threshold
      verticalSwipe(startY: 100, endY: 130);
      await pump();
      expect(events.whereType<NavigateUp>(), isEmpty);
      expect(events.whereType<NavigateDown>(), isEmpty);
    });

    test(
      'diagonal swipe favoring horizontal emits horizontal navigation',
      () async {
        // dx=200 (horizontal dominant), dy=30 (small vertical)
        const start = Duration(milliseconds: 100);
        const end = Duration(milliseconds: 200);
        classifier
          ..handleTouch(TouchDown(timestamp: start, position: 100, y: 100))
          ..handleTouch(TouchUp(timestamp: end, position: 300, y: 130));
        await pump();
        expect(events, [const NavigateNext()]);
      },
    );

    test(
      'diagonal swipe favoring vertical emits vertical navigation',
      () async {
        // dx=30 (small horizontal), dy=-200 (vertical dominant)
        const start = Duration(milliseconds: 100);
        const end = Duration(milliseconds: 200);
        classifier
          ..handleTouch(TouchDown(timestamp: start, position: 100, y: 300))
          ..handleTouch(TouchUp(timestamp: end, position: 130, y: 100));
        await pump();
        expect(events, [const NavigateUp()]);
      },
    );

    test('equal displacement favors horizontal', () async {
      // dx=100, dy=-100 → equal, should be horizontal (NavigateNext)
      const start = Duration(milliseconds: 100);
      const end = Duration(milliseconds: 200);
      classifier
        ..handleTouch(TouchDown(timestamp: start, position: 100, y: 200))
        ..handleTouch(TouchUp(timestamp: end, position: 200, y: 100));
      await pump();
      expect(events, [const NavigateNext()]);
    });

    test('vertical swipe clears input buffer', () async {
      // Start typing, then vertical swipe should clear buffer
      tap(100, startX: leftX); // dot
      await pump();
      events.clear();

      verticalSwipe(startY: 300, endY: 100); // swipe up
      // Wait for silence timeout — should NOT get InputComplete
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await pump();

      expect(events.whereType<InputComplete>(), isEmpty);
      expect(events, [const NavigateUp()]);
    });
  });

  group('inputBufferNotifier', () {
    test('starts empty', () {
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('updates on dot input', () async {
      tap(100, startX: leftX);
      await pump();
      expect(classifier.inputBufferNotifier.value, [
        const Signal(MorseSignal.dot),
      ]);
    });

    test('updates on dash input', () async {
      tap(100, startX: rightX);
      await pump();
      expect(classifier.inputBufferNotifier.value, [
        const Signal(MorseSignal.dash),
      ]);
    });

    test('accumulates multiple symbols', () async {
      tap(100, startX: leftX); // dot
      tap(100, startX: rightX); // dash
      tap(100, startX: leftX); // dot
      await pump();
      expect(classifier.inputBufferNotifier.value, [
        const Signal(MorseSignal.dot),
        const Signal(MorseSignal.dash),
        const Signal(MorseSignal.dot),
      ]);
    });

    test('updates on charGap insertion', () async {
      tap(100, startX: leftX); // dot
      await pump();
      classifier.insertCharGap();
      expect(classifier.inputBufferNotifier.value, [
        const Signal(MorseSignal.dot),
        const CharGap(),
      ]);
    });

    test('clears on submitInput', () async {
      tap(100, startX: leftX); // dot
      await pump();
      expect(classifier.inputBufferNotifier.value, isNotEmpty);

      classifier.submitInput();
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('clears on navigation (swipe clears buffer)', () async {
      tap(100, startX: leftX); // dot
      await pump();
      expect(classifier.inputBufferNotifier.value, isNotEmpty);

      // Horizontal swipe right → NavigateNext → clears buffer
      const start = Duration(milliseconds: 100);
      const end = Duration(milliseconds: 200);
      classifier
        ..handleTouch(const TouchDown(timestamp: start, position: 100, y: 200))
        ..handleTouch(const TouchUp(timestamp: end, position: 300, y: 200));
      await pump();
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('clears on silence timeout', () async {
      tap(100, startX: leftX); // dot
      await pump();
      expect(classifier.inputBufferNotifier.value, isNotEmpty);

      // Wait for silence timeout (default 1000ms)
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await pump();
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('emits unmodifiable list', () async {
      tap(100, startX: leftX);
      await pump();
      final buffer = classifier.inputBufferNotifier.value;
      expect(
        () => buffer.add(const Signal(MorseSignal.dot)),
        throwsUnsupportedError,
      );
    });
  });
}
