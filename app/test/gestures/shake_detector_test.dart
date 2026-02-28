import 'dart:async';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/shake_config.dart';
import 'package:feel_you/gestures/shake_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  // Helper to create an AccelerometerEvent from x, y, z values.
  AccelerometerEvent accelEvent(double x, double y, double z) =>
      AccelerometerEvent(x, y, z, DateTime.now());

  // Default config: threshold = 15.0, cooldown = 1000ms.
  const defaultConfig = ShakeConfig();

  late StreamController<AccelerometerEvent> accelController;
  late ShakeDetector detector;
  late List<GestureEvent> events;
  late StreamSubscription<GestureEvent> subscription;

  setUp(() {
    accelController = StreamController<AccelerometerEvent>();
    detector = ShakeDetector(
      config: defaultConfig,
      accelerometerStream: accelController.stream,
    );
    events = [];
    subscription = detector.events.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    detector.dispose();
    await accelController.close();
  });

  // Allow microtask queue to drain so stream events are delivered.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('threshold detection', () {
    test('acceleration above threshold emits Home', () async {
      // magnitude = sqrt(25^2 + 0 + 0) - 9.81 = 25 - 9.81 = 15.19 > 15.0
      accelController.add(accelEvent(25, 0, 0));
      await pump();
      expect(events, [const Home()]);
    });

    test('acceleration below threshold does not emit', () async {
      // magnitude = sqrt(10^2 + 0 + 0) - 9.81 = 10 - 9.81 = 0.19 < 15.0
      accelController.add(accelEvent(10, 0, 0));
      await pump();
      expect(events, isEmpty);
    });

    test('acceleration exactly at threshold does not emit', () async {
      // We need magnitude = sqrt(x^2) - 9.81 = exactly 15.0
      // So x = 24.81. But floating point means this may be very close.
      // Use a value that gives magnitude just below threshold.
      // sqrt(24.8^2) - 9.81 = 24.8 - 9.81 = 14.99 < 15.0
      accelController.add(accelEvent(24.8, 0, 0));
      await pump();
      expect(events, isEmpty);
    });

    test('combined axes contribute to magnitude', () async {
      // magnitude = sqrt(15^2 + 15^2 + 15^2) - 9.81
      //           = sqrt(675) - 9.81 ≈ 25.98 - 9.81 ≈ 16.17 > 15.0
      accelController.add(accelEvent(15, 15, 15));
      await pump();
      expect(events, [const Home()]);
    });
  });

  group('cooldown enforcement', () {
    test('rapid shakes within cooldown only emit once', () async {
      accelController.add(accelEvent(30, 0, 0));
      await pump();
      expect(events, hasLength(1));

      // Second shake immediately — within cooldown.
      accelController.add(accelEvent(30, 0, 0));
      await pump();
      expect(events, hasLength(1)); // Still only 1 event.
    });

    test('shake after cooldown emits again', () async {
      // Use a short cooldown for this test.
      await subscription.cancel();
      detector.dispose();
      await accelController.close();

      accelController = StreamController<AccelerometerEvent>();
      detector = ShakeDetector(
        config: const ShakeConfig(shakeCooldown: Duration(milliseconds: 100)),
        accelerometerStream: accelController.stream,
      );
      events = [];
      subscription = detector.events.listen(events.add);

      accelController.add(accelEvent(30, 0, 0));
      await pump();
      expect(events, hasLength(1));

      // Wait for cooldown to elapse.
      await Future<void>.delayed(const Duration(milliseconds: 150));

      accelController.add(accelEvent(30, 0, 0));
      await pump();
      expect(events, hasLength(2));
    });
  });

  group('error handling', () {
    test('stream error does not crash', () async {
      // Add an error to the accelerometer stream.
      accelController.addError(Exception('sensor failure'));
      await pump();

      // Detector should still be functional.
      accelController.add(accelEvent(30, 0, 0));
      await pump();
      expect(events, [const Home()]);
    });
  });

  group('dispose', () {
    test('dispose cancels subscription and closes stream', () async {
      detector.dispose();

      // Adding events after dispose should not cause errors.
      accelController.add(accelEvent(30, 0, 0));
      await pump();
      expect(events, isEmpty);
    });

    test('events stream is done after dispose', () async {
      detector.dispose();

      // The events stream should complete.
      await expectLater(detector.events, emitsDone);
    });
  });
}
