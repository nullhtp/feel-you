import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GestureClassifier classifier;
  late List<GestureEvent> events;
  late StreamSubscription<GestureEvent> subscription;

  setUp(() {
    classifier = GestureClassifier();
    events = [];
    subscription = classifier.events.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    classifier.dispose();
  });

  // Helper: simulate tap at x=0 with given duration in ms.
  void tap(int durationMs, {double startX = 0, double endX = 0}) {
    const start = Duration(milliseconds: 100);
    final end = start + Duration(milliseconds: durationMs);
    classifier
      ..handleTouch(TouchDown(timestamp: start, position: startX))
      ..handleTouch(TouchUp(timestamp: end, position: endX));
  }

  // Allow microtask queue to drain so stream events are delivered.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('tap classification', () {
    test('quick tap (100ms) produces dot', () async {
      tap(100);
      await pump();
      expect(events, [const MorseInput(MorseSymbol.dot)]);
    });

    test('tap at 50ms produces dot', () async {
      tap(50);
      await pump();
      expect(events, [const MorseInput(MorseSymbol.dot)]);
    });

    test(
      'tap at exactly 150ms produces dash (boundary exclusive for dot)',
      () async {
        tap(150);
        await pump();
        expect(events, [const MorseInput(MorseSymbol.dash)]);
      },
    );

    test('tap at 300ms produces dash', () async {
      tap(300);
      await pump();
      expect(events, [const MorseInput(MorseSymbol.dash)]);
    });

    test('tap at exactly 500ms produces dash (boundary inclusive)', () async {
      tap(500);
      await pump();
      expect(events, [const MorseInput(MorseSymbol.dash)]);
    });

    test('tap at 800ms (dead zone) produces no event', () async {
      tap(800);
      await pump();
      expect(events, isEmpty);
    });

    test('tap at 1500ms (dead zone) produces no event', () async {
      tap(1500);
      await pump();
      expect(events, isEmpty);
    });

    test('custom config changes thresholds', () async {
      await subscription.cancel();
      classifier.dispose();

      classifier = GestureClassifier(
        config: const GestureTimingConfig(dotMaxDuration: 200),
      );
      events = [];
      subscription = classifier.events.listen(events.add);

      // 150ms is now a dot with custom config (was dash with default).
      tap(150);
      await pump();
      expect(events, [const MorseInput(MorseSymbol.dot)]);
    });
  });

  group('reset via long hold', () {
    test('hold > 2000ms emits Reset', () async {
      const start = Duration(milliseconds: 100);
      classifier.handleTouch(const TouchDown(timestamp: start, position: 0));

      // Wait for the reset timer to fire.
      await Future<void>.delayed(const Duration(milliseconds: 2100));

      expect(events, [const Reset()]);

      // Release should not produce additional events.
      classifier.handleTouch(
        TouchUp(
          timestamp: start + const Duration(milliseconds: 2500),
          position: 0,
        ),
      );
      await pump();
      expect(events, [const Reset()]);
    });

    test('release before 2000ms does not emit reset', () async {
      tap(1900);
      // Allow time for any timer to fire that shouldn't.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      // Dead zone: no MorseInput, no Reset.
      expect(events, isEmpty);
    });
  });

  group('silence timeout and input completion', () {
    test('silence after input triggers InputComplete', () async {
      tap(100); // dot
      await pump();
      expect(events, [const MorseInput(MorseSymbol.dot)]);

      // Wait for silence timeout.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(events, [
        const MorseInput(MorseSymbol.dot),
        const InputComplete([MorseSymbol.dot]),
      ]);
    });

    test('multiple inputs accumulate before completion', () async {
      tap(100); // dot
      await Future<void>.delayed(const Duration(milliseconds: 200));
      tap(300); // dash

      // Wait for silence timeout from last input.
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      expect(events, [
        const MorseInput(MorseSymbol.dot),
        const MorseInput(MorseSymbol.dash),
        const InputComplete([MorseSymbol.dot, MorseSymbol.dash]),
      ]);
    });

    test('continued tapping resets the timer', () async {
      tap(100); // dot
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // Timer hasn't fired yet. Tap again to reset it.
      tap(300); // dash

      // Wait less than the full timeout from the second tap.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      // Should not have InputComplete yet.
      expect(events.whereType<InputComplete>().toList(), isEmpty);

      // Now wait for full timeout to elapse.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(events.whereType<InputComplete>().toList(), [
        const InputComplete([MorseSymbol.dot, MorseSymbol.dash]),
      ]);
    });

    test('no completion without prior input', () async {
      // Just wait — no taps.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(events, isEmpty);
    });
  });

  group('swipe detection', () {
    test('swipe right emits NavigateNext', () async {
      // Fast swipe: 100ms across 100px = 1000px/s.
      tap(100, endX: 100);
      await pump();
      expect(events, contains(const NavigateNext()));
    });

    test('swipe left emits NavigatePrevious', () async {
      tap(100, startX: 100);
      await pump();
      expect(events, contains(const NavigatePrevious()));
    });

    test('slow swipe is ignored', () async {
      // Slow swipe: 1000ms across 60px = 60px/s (below 200px/s threshold).
      tap(1000, endX: 60);
      await pump();
      // Falls in dead zone for duration, no swipe due to low velocity.
      expect(events.whereType<NavigateNext>().toList(), isEmpty);
      expect(events.whereType<NavigatePrevious>().toList(), isEmpty);
    });

    test('short swipe is ignored', () async {
      // Short swipe: 50ms across 30px (below 50px threshold).
      tap(50, endX: 30);
      await pump();
      // Should be classified as a dot, not a swipe.
      expect(events, [const MorseInput(MorseSymbol.dot)]);
    });

    test('swipe is not also classified as morse input', () async {
      tap(100, endX: 100);
      await pump();
      // Should only have NavigateNext, no MorseInput.
      expect(events.whereType<MorseInput>().toList(), isEmpty);
    });
  });

  group('input buffer reset', () {
    test('swipe clears accumulated input', () async {
      tap(100); // dot
      await pump();
      expect(events.last, const MorseInput(MorseSymbol.dot));

      // Swipe right before silence timeout.
      tap(100, endX: 100);
      await pump();
      expect(events.last, const NavigateNext());

      // Wait for silence timeout — should not emit InputComplete.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(events.whereType<InputComplete>().toList(), isEmpty);
    });

    test('reset clears accumulated input', () async {
      tap(100); // dot
      await pump();
      expect(events.last, const MorseInput(MorseSymbol.dot));

      // Long hold to trigger reset.
      const start = Duration(milliseconds: 5000);
      classifier.handleTouch(const TouchDown(timestamp: start, position: 0));
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(events.last, const Reset());

      // Release.
      classifier.handleTouch(
        TouchUp(
          timestamp: start + const Duration(milliseconds: 2500),
          position: 0,
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

      tap(100); // dot
      await pump();
      expect(events, [const MorseInput(MorseSymbol.dot)]);
      expect(events2, [const MorseInput(MorseSymbol.dot)]);

      await sub2.cancel();
    });

    test('events arrive in order', () async {
      tap(100); // dot
      tap(300); // dash
      await pump();
      expect(events, [
        const MorseInput(MorseSymbol.dot),
        const MorseInput(MorseSymbol.dash),
      ]);
    });
  });
}
