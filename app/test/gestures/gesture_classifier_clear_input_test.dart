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

void main() {
  // A shortened silence timeout.
  const silenceTimeout = Duration(milliseconds: 50);

  // Well past the silence timeout.
  const afterSilence = Duration(milliseconds: 150);

  // Screen width 800, midpoint 400.
  const leftX = 100.0; // dot
  const rightX = 600.0; // dash

  late GestureClassifier classifier;
  late List<GestureEvent> events;
  late StreamSubscription<GestureEvent> subscription;

  setUp(() {
    classifier = GestureClassifier(
      screenWidth: 800,
      config: GestureTimingConfig(
        silenceTimeout: silenceTimeout.inMilliseconds,
      ),
    );
    events = [];
    subscription = classifier.events.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    classifier.dispose();
  });

  void tap(double x) {
    classifier
      ..handleTouch(TouchDown(timestamp: Duration.zero, position: x))
      ..handleTouch(
        TouchUp(timestamp: const Duration(milliseconds: 50), position: x),
      );
  }

  // Allow microtask queue to drain so stream events are delivered.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('clearInput', () {
    test('empties the buffer and notifies listeners', () async {
      tap(leftX);
      tap(rightX);
      expect(classifier.inputBufferNotifier.value, const [
        Signal(MorseSignal.dot),
        Signal(MorseSignal.dash),
      ]);
      var notifications = 0;
      classifier.inputBufferNotifier.addListener(() => notifications++);

      classifier.clearInput();

      expect(classifier.inputBufferNotifier.value, isEmpty);
      expect(notifications, 1);
    });

    test('emits no event', () async {
      tap(leftX);
      await pump();
      events.clear();

      classifier.clearInput();
      await pump();

      expect(events, isEmpty);
    });

    test('cancels the silence timer, so InputComplete never fires', () async {
      tap(leftX);
      await pump();

      classifier.clearInput();
      await Future<void>.delayed(afterSilence);

      expect(events.whereType<InputComplete>(), isEmpty);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('also discards a trailing charGap', () async {
      tap(leftX);
      classifier
        ..insertCharGap()
        ..clearInput();
      await Future<void>.delayed(afterSilence);

      expect(events.whereType<InputComplete>(), isEmpty);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('later input starts a fresh pattern', () async {
      tap(leftX);
      classifier.clearInput();

      tap(rightX);
      await Future<void>.delayed(afterSilence);

      expect(events.whereType<InputComplete>().toList(), const [
        InputComplete([Signal(MorseSignal.dash)]),
      ]);
    });

    test('submitInput after clearInput emits nothing', () async {
      tap(leftX);
      classifier
        ..clearInput()
        ..submitInput();
      await pump();

      expect(events.whereType<InputComplete>(), isEmpty);
    });

    test('is harmless on an empty buffer', () async {
      classifier.clearInput();
      await Future<void>.delayed(afterSilence);

      expect(events, isEmpty);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });
  });
}
