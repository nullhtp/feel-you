import 'dart:async';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/shake_config.dart';
import 'package:feel_you/gestures/shake_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Default config: threshold 15, cooldown 1000 ms, settle 700 ms,
/// double-shake window 1500 ms.
const _config = ShakeConfig();

/// Interval of the default sensors_plus accelerometer stream.
const _sampleInterval = Duration(milliseconds: 200);

void main() {
  late StreamController<AccelerometerEvent> accelController;
  late ShakeDetector detector;
  late List<GestureEvent> events;
  late StreamSubscription<GestureEvent> subscription;

  /// The detector's clock, moved forward by the tests.
  late DateTime now;

  setUp(() {
    now = DateTime(2026);
    accelController = StreamController<AccelerometerEvent>();
    detector = ShakeDetector(
      accelerometerStream: accelController.stream,
      clock: () => now,
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

  /// Feeds one reading at the current time: strong (magnitude 30 - 9.81,
  /// above the threshold) or quiet (resting, gravity only).
  Future<void> reading({bool strong = true}) async {
    accelController.add(AccelerometerEvent(strong ? 30 : 9.81, 0, 0, now));
    await pump();
  }

  /// A short, deliberate shake: three strong readings at the sensor
  /// interval, starting now. Leaves the clock at its last reading.
  Future<void> shake() async {
    for (var i = 0; i < 3; i++) {
      if (i > 0) now = now.add(_sampleInterval);
      await reading();
    }
  }

  test('a single shake emits Home immediately', () async {
    await reading();
    expect(events, [const Home()]);

    // The rest of the shake adds nothing.
    for (var i = 0; i < 2; i++) {
      now = now.add(_sampleInterval);
      await reading();
    }
    expect(events, [const Home()]);
  });

  test('two shakes within the window emit Home, then ChangeLanguage', () async {
    await shake();
    expect(events, [const Home()]);

    // Pause well inside the window, then shake again.
    now = now.add(const Duration(milliseconds: 800));
    await shake();

    expect(events, [const Home(), const ChangeLanguage()]);
  });

  test('a second shake at the edge of the window still counts', () async {
    await shake();
    now = now.add(_config.doubleShakeWindow);
    await shake();

    expect(events, [const Home(), const ChangeLanguage()]);
  });

  test('two shakes outside the window are two Homes', () async {
    await shake();
    now = now.add(
      _config.doubleShakeWindow + const Duration(milliseconds: 100),
    );
    await shake();

    expect(events, [const Home(), const Home()]);
  });

  test('quiet readings between the shakes do not break the pair', () async {
    await shake();
    for (var i = 0; i < 4; i++) {
      now = now.add(_sampleInterval);
      await reading(strong: false);
    }
    now = now.add(_sampleInterval);
    await shake();

    expect(events, [const Home(), const ChangeLanguage()]);
  });

  test('one long vigorous shake never counts as two', () async {
    // Three seconds of shaking. Some readings miss the peak, as happens
    // when the 200 ms sensor interval falls between reversals.
    for (var i = 0; i < 15; i++) {
      if (i > 0) now = now.add(_sampleInterval);
      await reading(strong: i.isEven || i % 3 == 0);
    }

    expect(events, isNot(contains(const ChangeLanguage())));
    // The cooldown still lets a long shake go home more than once.
    expect(events, everyElement(const Home()));
  });

  test('a shake that misses two peaks in a row is still one shake', () async {
    await reading();
    // Two missed peaks: 600 ms without a strong reading is still shorter
    // than the settle time.
    for (var i = 0; i < 2; i++) {
      now = now.add(_sampleInterval);
      await reading(strong: false);
    }
    now = now.add(_sampleInterval);
    await reading();

    expect(events, [const Home()]);
  });

  test('a third shake starts a new pair', () async {
    await shake();
    now = now.add(const Duration(milliseconds: 800));
    await shake();
    expect(events, [const Home(), const ChangeLanguage()]);

    // A third shake soon after is the first of a new pair: it goes home
    // rather than emitting another ChangeLanguage.
    now = now.add(const Duration(milliseconds: 800));
    await shake();
    expect(events, [const Home(), const ChangeLanguage(), const Home()]);

    // A fourth shake completes the new pair.
    now = now.add(const Duration(milliseconds: 800));
    await shake();
    expect(events, [
      const Home(),
      const ChangeLanguage(),
      const Home(),
      const ChangeLanguage(),
    ]);
  });

  test('a shake before a pause never pairs with one after it', () async {
    await shake();
    detector
      ..pause()
      ..resume();
    now = now.add(const Duration(milliseconds: 800));
    await shake();

    // The second shake is a fresh first shake: it goes home again.
    expect(events, [const Home(), const Home()]);

    // ...and it can still be the first of a pair.
    now = now.add(const Duration(milliseconds: 800));
    await shake();
    expect(events, [const Home(), const Home(), const ChangeLanguage()]);
  });

  test('a shorter window and settle time can be configured', () async {
    await subscription.cancel();
    detector.dispose();
    await accelController.close();

    accelController = StreamController<AccelerometerEvent>();
    detector = ShakeDetector(
      config: const ShakeConfig(
        shakeSettle: Duration(milliseconds: 100),
        doubleShakeWindow: Duration(milliseconds: 300),
      ),
      accelerometerStream: accelController.stream,
      clock: () => now,
    );
    events = [];
    subscription = detector.events.listen(events.add);

    await reading();
    now = now.add(const Duration(milliseconds: 200));
    await reading();
    expect(events, [const Home(), const ChangeLanguage()]);
  });
}
