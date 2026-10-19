import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_time.dart';

// The tests run in fake time: `test` is the one from fake_time.dart. A wait
// for the classifier's timers then always ends after the timer and the
// event it emits.

/// Tests for [TouchCancel]: a press the OS took over (edge back/home
/// gesture, notification shade, Control Center, incoming call) or the UI
/// abandoned must never be classified.
void main() {
  // Screen width used for all tests. Midpoint = 400.
  const testScreenWidth = 800.0;
  const leftX = 100.0; // < 400 → dot
  const rightX = 600.0; // >= 400 → dash

  // Shortened long-hold and silence thresholds. The swipe thresholds
  // keep their defaults (50 px, 200 px/s).
  const config = GestureTimingConfig(
    resetMinDuration: 500,
    silenceTimeout: 100,
  );

  // Waits that are safely past each threshold.
  const pastSilence = Duration(milliseconds: 200);
  const pastReset = Duration(milliseconds: 600);

  late GestureClassifier classifier;
  late List<GestureEvent> events;
  late StreamSubscription<GestureEvent> subscription;

  setUp(() {
    classifier = GestureClassifier(
      screenWidth: testScreenWidth,
      config: config,
    );
    events = [];
    subscription = classifier.events.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    classifier.dispose();
  });

  // Every press starts at the same timestamp; only the classifier's timers
  // (fake time) and the release position/timestamp matter.
  const start = Duration(milliseconds: 100);

  void down({double x = leftX, double y = 300}) {
    classifier.handleTouch(TouchDown(timestamp: start, position: x, y: y));
  }

  void up({double x = leftX, double y = 300, int afterMs = 100}) {
    classifier.handleTouch(
      TouchUp(
        timestamp: start + Duration(milliseconds: afterMs),
        position: x,
        y: y,
      ),
    );
  }

  void cancel() => classifier.handleTouch(const TouchCancel());

  // Allow microtask queue to drain so stream events are delivered.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('a cancelled press is not classified', () {
    test('short press on the left half emits no dot', () async {
      down();
      cancel();
      await Future<void>.delayed(pastReset);
      expect(events, isEmpty);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('short press on the right half emits no dash', () async {
      down(x: rightX);
      cancel();
      await Future<void>.delayed(pastReset);
      expect(events, isEmpty);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('press that would have been a horizontal swipe emits no '
        'navigation, and a stray release afterwards is ignored', () async {
      // An edge back gesture: the finger travels far before the OS takes
      // over the pointer.
      down(x: 0);
      cancel();
      up(x: 300);
      await Future<void>.delayed(pastReset);
      expect(events, isEmpty);
    });

    test('press that would have been a vertical swipe emits no '
        'navigation, and a stray release afterwards is ignored', () async {
      // Pulling down the notification shade from the top edge.
      down(y: 0);
      cancel();
      up(y: 400);
      await Future<void>.delayed(pastReset);
      expect(events, isEmpty);
    });

    test('cancel with no press in progress emits nothing', () async {
      cancel();
      cancel();
      await Future<void>.delayed(pastReset);
      expect(events, isEmpty);
    });
  });

  group('long hold', () {
    test('cancel before the reset threshold means no Reset fires', () async {
      down();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      cancel();

      // Well past the moment the reset would have fired.
      await Future<void>.delayed(pastReset);
      expect(events, isEmpty);
    });

    test('cancel after Reset already fired emits nothing extra', () async {
      down();
      await Future<void>.delayed(pastReset);
      expect(events, [const Reset()]);

      cancel();
      await Future<void>.delayed(pastReset);
      expect(events, [const Reset()]);
    });

    test('Reset that already fired still cleared the buffer; the cancel does '
        'not bring back an InputComplete', () async {
      down();
      up();
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);

      down();
      await Future<void>.delayed(pastReset);
      expect(events.last, const Reset());

      cancel();
      await Future<void>.delayed(pastReset);
      expect(events, [const MorseInput(MorseSignal.dot), const Reset()]);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });
  });

  group('input entered before the cancelled press', () {
    test(
      'survives the cancel and completes after the silence timeout',
      () async {
        down();
        up();
        down(x: rightX);
        up(x: rightX);
        await pump();

        // Next press is cancelled by the OS.
        down();
        cancel();
        await pump();
        expect(classifier.inputBufferNotifier.value, const [
          Signal(MorseSignal.dot),
          Signal(MorseSignal.dash),
        ]);

        await Future<void>.delayed(pastSilence);
        expect(events, [
          const MorseInput(MorseSignal.dot),
          const MorseInput(MorseSignal.dash),
          const InputComplete([
            Signal(MorseSignal.dot),
            Signal(MorseSignal.dash),
          ]),
        ]);
        expect(classifier.inputBufferNotifier.value, isEmpty);
      },
    );

    test('is not completed while the press is held, but is once it is '
        'cancelled', () async {
      down();
      up();
      await pump();

      // Holding a finger down pauses completion, even past the timeout.
      down();
      await Future<void>.delayed(pastSilence);
      expect(events, [const MorseInput(MorseSignal.dot)]);

      cancel();
      await Future<void>.delayed(pastSilence);
      expect(events, [
        const MorseInput(MorseSignal.dot),
        const InputComplete([Signal(MorseSignal.dot)]),
      ]);
    });
  });

  group('a new press after a cancel', () {
    test('tap classifies normally', () async {
      down();
      cancel();

      down(x: rightX);
      up(x: rightX);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dash)]);

      await Future<void>.delayed(pastSilence);
      expect(events, [
        const MorseInput(MorseSignal.dash),
        const InputComplete([Signal(MorseSignal.dash)]),
      ]);
    });

    test('swipe classifies normally', () async {
      down();
      cancel();

      down(x: 0);
      up(x: 300);
      await pump();
      expect(events, [const NavigateNext()]);
    });

    test('long hold still fires Reset', () async {
      down();
      cancel();

      down();
      await Future<void>.delayed(pastReset);
      expect(events, [const Reset()]);
    });

    test('tap after a cancel that followed a Reset classifies '
        'normally', () async {
      down();
      await Future<void>.delayed(pastReset);
      cancel();

      down();
      up();
      await pump();
      expect(events, [const Reset(), const MorseInput(MorseSignal.dot)]);
    });
  });
}
