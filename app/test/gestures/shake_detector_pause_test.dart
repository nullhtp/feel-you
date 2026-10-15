import 'dart:async';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/shake_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  // magnitude = 25 - 9.81 = 15.19, above the default threshold of 15.0.
  AccelerometerEvent shakeEvent() =>
      AccelerometerEvent(25, 0, 0, DateTime.now());

  // Allow microtask queue to drain so stream events are delivered.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('with a broadcast accelerometer stream', () {
    late StreamController<AccelerometerEvent> accelController;
    late ShakeDetector detector;
    late List<GestureEvent> events;
    late StreamSubscription<GestureEvent> subscription;

    setUp(() {
      accelController = StreamController<AccelerometerEvent>.broadcast();
      detector = ShakeDetector(accelerometerStream: accelController.stream);
      events = [];
      subscription = detector.events.listen(events.add);
    });

    tearDown(() async {
      await subscription.cancel();
      detector.dispose();
      await accelController.close();
    });

    test('is not paused initially', () {
      expect(detector.isPaused, isFalse);
      expect(accelController.hasListener, isTrue);
    });

    test('pause() unsubscribes from the accelerometer', () async {
      detector.pause();
      await pump();

      expect(detector.isPaused, isTrue);
      expect(accelController.hasListener, isFalse);
    });

    test('no Home is emitted while paused', () async {
      detector.pause();
      accelController.add(shakeEvent());
      await pump();

      expect(events, isEmpty);
    });

    test('resume() subscribes again and detects shakes', () async {
      detector.pause();
      await pump();
      detector.resume();

      expect(detector.isPaused, isFalse);
      expect(accelController.hasListener, isTrue);

      accelController.add(shakeEvent());
      await pump();
      expect(events, [const Home()]);
    });

    test('pause() and resume() are idempotent', () async {
      detector
        ..pause()
        ..pause();
      await pump();
      expect(accelController.hasListener, isFalse);

      detector
        ..resume()
        ..resume();
      accelController.add(shakeEvent());
      await pump();
      expect(events, [const Home()]);
    });

    test('resume() after dispose does not subscribe again', () async {
      detector
        ..pause()
        ..dispose()
        ..resume();
      await pump();

      expect(accelController.hasListener, isFalse);
    });
  });

  group('with a single-subscription accelerometer stream', () {
    late StreamController<AccelerometerEvent> accelController;
    late ShakeDetector detector;
    late List<GestureEvent> events;
    late StreamSubscription<GestureEvent> subscription;

    setUp(() {
      accelController = StreamController<AccelerometerEvent>();
      detector = ShakeDetector(accelerometerStream: accelController.stream);
      events = [];
      subscription = detector.events.listen(events.add);
    });

    tearDown(() async {
      await subscription.cancel();
      detector.dispose();
      await accelController.close();
    });

    test('shakes while paused are dropped, not replayed on resume', () async {
      detector.pause();
      accelController.add(shakeEvent());
      await pump();
      expect(events, isEmpty);

      detector.resume();
      await pump();
      expect(events, isEmpty);
    });

    test('resume() detects shakes again', () async {
      detector
        ..pause()
        ..resume();
      accelController.add(shakeEvent());
      await pump();

      expect(events, [const Home()]);
    });
  });
}
