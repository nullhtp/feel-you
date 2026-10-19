import 'dart:async';
import 'dart:ui' show Size;

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/gestures/zone_layout.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_time.dart';

// The tests run in fake time: `test` is the one from fake_time.dart. A wait
// for the classifier's timers then always ends after the timer and the
// event it emits.

/// Tests for the bottom input zone: a tap that starts in the lower
/// [GestureTimingConfig.bottomZoneFraction] of the screen is a
/// [BottomZoneAction], not a dot or dash.
void main() {
  // 800x600 screen: midpoint x = 400, bottom zone from y = 510.
  const screenWidth = 800.0;
  const screenHeight = 600.0;
  const leftX = 100.0; // < 400 → dot
  const rightX = 600.0; // >= 400 → dash
  const upperY = 300.0; // above the bottom zone
  const zoneY = 560.0; // in the bottom zone

  // Shortened long-hold and silence thresholds. The swipe thresholds
  // and the zone fraction keep their defaults (50 px, 200 px/s, 15 %).
  const config = GestureTimingConfig(
    resetMinDuration: 500,
    silenceTimeout: 100,
  );

  // Waits that are safely past each threshold.
  const pastSilence = Duration(milliseconds: 200);
  const pastReset = Duration(milliseconds: 600);

  final zoneTop = ZoneLayout(
    const Size(screenWidth, screenHeight),
    config,
  ).bottomZoneTop;

  late GestureClassifier classifier;
  late List<GestureEvent> events;
  late StreamSubscription<GestureEvent> subscription;

  setUp(() {
    classifier = GestureClassifier(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
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

  void down({double x = leftX, double y = upperY}) {
    classifier.handleTouch(TouchDown(timestamp: start, position: x, y: y));
  }

  void up({required double x, required double y, int afterMs = 100}) {
    classifier.handleTouch(
      TouchUp(
        timestamp: start + Duration(milliseconds: afterMs),
        position: x,
        y: y,
      ),
    );
  }

  // A short press released where it started.
  void tap({double x = leftX, double y = upperY}) {
    down(x: x, y: y);
    up(x: x, y: y);
  }

  // A fast press moved by (dx, dy) before release.
  void swipe({
    required double x,
    required double y,
    double dx = 0,
    double dy = 0,
  }) {
    down(x: x, y: y);
    up(x: x + dx, y: y + dy);
  }

  // Allow microtask queue to drain so stream events are delivered.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('a tap in the bottom zone', () {
    test('on the left half emits BottomZoneAction, not a dot', () async {
      tap(y: zoneY);
      await pump();
      expect(events, [const BottomZoneAction()]);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('on the right half emits BottomZoneAction, not a dash', () async {
      tap(x: rightX, y: zoneY);
      await pump();
      expect(events, [const BottomZoneAction()]);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test(
      'starts at the zone top (inclusive); just above it is a dot',
      () async {
        expect(zoneTop, 510);

        tap(y: zoneTop);
        tap(y: zoneTop - 0.5);
        await pump();
        expect(events, [
          const BottomZoneAction(),
          const MorseInput(MorseSignal.dot),
        ]);
      },
    );

    test('is decided by where the press started, not released', () async {
      // Starts in the zone, released above it (too short to be a swipe).
      down(y: zoneTop + 10);
      up(x: leftX, y: zoneTop - 20);
      // Starts above the zone, released in it.
      down(y: zoneTop - 10);
      up(x: leftX, y: zoneTop + 20);
      await pump();

      expect(events, [
        const BottomZoneAction(),
        const MorseInput(MorseSignal.dot),
      ]);
    });

    test('leaves input already in the buffer as it is', () async {
      tap(); // dot
      tap(y: zoneY);
      await pump();

      expect(events, [
        const MorseInput(MorseSignal.dot),
        const BottomZoneAction(),
      ]);
      expect(classifier.inputBufferNotifier.value, [
        const Signal(MorseSignal.dot),
      ]);
    });

    test('follows a live height change', () async {
      // Taller surface: the zone now starts at y = 850, so y = 560 is a dot.
      classifier.screenHeight = 1000;
      tap(y: zoneY);
      tap(y: 900);
      await pump();

      expect(events, [
        const MorseInput(MorseSignal.dot),
        const BottomZoneAction(),
      ]);
    });
  });

  group('a swipe that starts in the bottom zone still navigates', () {
    test('right swipe emits NavigateNext', () async {
      swipe(x: leftX, y: zoneY, dx: 200);
      await pump();
      expect(events, [const NavigateNext()]);
    });

    test('left swipe emits NavigatePrevious', () async {
      swipe(x: rightX, y: zoneY, dx: -200);
      await pump();
      expect(events, [const NavigatePrevious()]);
    });

    test('up swipe emits NavigateUp', () async {
      swipe(x: leftX, y: 590, dy: -300);
      await pump();
      expect(events, [const NavigateUp()]);
    });

    test('down swipe within the zone emits NavigateDown', () async {
      swipe(x: leftX, y: 520, dy: 70);
      await pump();
      expect(events, [const NavigateDown()]);
    });

    test('a swipe clears the buffer, like any other swipe', () async {
      tap(); // dot
      swipe(x: leftX, y: zoneY, dx: 200);
      await Future<void>.delayed(pastSilence);

      expect(events, [const MorseInput(MorseSignal.dot), const NavigateNext()]);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });
  });

  // Issue #18: a long hold that started in the bottom strip emitted Reset
  // and then, on release, a BottomZoneAction as well.
  group('a long hold in the bottom zone', () {
    test('emits exactly one Reset and no BottomZoneAction', () async {
      down(y: zoneY);
      await Future<void>.delayed(pastReset);
      expect(events, [const Reset()]);

      // Released at 1.25x the reset threshold (2.5 s at the default 2 s).
      up(x: leftX, y: zoneY, afterMs: config.resetMinDuration * 5 ~/ 4);
      await Future<void>.delayed(pastSilence);

      expect(events, [const Reset()]);
    });

    test('released above the zone also emits only the Reset', () async {
      down(y: zoneY);
      await Future<void>.delayed(pastReset);
      up(x: leftX, y: upperY, afterMs: config.resetMinDuration * 5 ~/ 4);
      await Future<void>.delayed(pastSilence);

      expect(events, [const Reset()]);
    });

    test('clears buffered input, which is then never completed', () async {
      tap(); // dot
      down(y: zoneY);
      await Future<void>.delayed(pastReset);
      up(x: leftX, y: zoneY, afterMs: config.resetMinDuration * 5 ~/ 4);
      await Future<void>.delayed(pastSilence);

      expect(events, [const MorseInput(MorseSignal.dot), const Reset()]);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('a tap after it is a normal bottom-zone tap', () async {
      down(y: zoneY);
      await Future<void>.delayed(pastReset);
      up(x: leftX, y: zoneY, afterMs: config.resetMinDuration * 5 ~/ 4);
      tap(y: zoneY);
      await pump();

      expect(events, [const Reset(), const BottomZoneAction()]);
    });
  });

  // Issue #19: the press's TouchDown stops the silence timer, and a
  // bottom-zone tap must restart it, or input buffered before the tap is
  // never completed when nothing acts on the action.
  group('input buffered before a bottom-zone tap', () {
    test('is still completed by the silence timeout if the action is '
        'ignored', () async {
      tap(); // dot
      tap(y: zoneY);
      await Future<void>.delayed(pastSilence);

      expect(events, [
        const MorseInput(MorseSignal.dot),
        const BottomZoneAction(),
        const InputComplete([Signal(MorseSignal.dot)]),
      ]);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('is not completed before the silence timeout', () async {
      tap(); // dot
      tap(y: zoneY);
      await Future<void>.delayed(
        Duration(milliseconds: config.silenceTimeout ~/ 2),
      );

      expect(events.whereType<InputComplete>(), isEmpty);
      expect(classifier.inputBufferNotifier.value, [
        const Signal(MorseSignal.dot),
      ]);
    });

    test('is completed once when the action submits it', () async {
      final orchestrator = actOnBottomZoneAction(
        classifier,
        classifier.submitInput,
      );
      addTearDown(orchestrator.cancel);

      tap(); // dot
      tap(y: zoneY);
      await Future<void>.delayed(pastSilence);

      expect(events, [
        const MorseInput(MorseSignal.dot),
        const BottomZoneAction(),
        const InputComplete([Signal(MorseSignal.dot)]),
      ]);
    });

    test('is completed once when the action inserts a letter gap', () async {
      final orchestrator = actOnBottomZoneAction(
        classifier,
        classifier.insertCharGap,
      );
      addTearDown(orchestrator.cancel);

      tap(); // dot
      tap(y: zoneY);
      await Future<void>.delayed(pastSilence);

      // The trailing letter gap is dropped on completion.
      expect(events, [
        const MorseInput(MorseSignal.dot),
        const BottomZoneAction(),
        const InputComplete([Signal(MorseSignal.dot)]),
      ]);
    });

    test('is completed once when the action arrives after the timeout '
        '(slow tap feedback)', () async {
      tap(); // dot
      tap(y: zoneY);
      await Future<void>.delayed(pastSilence);

      // The orchestrator's tap feedback finished only now.
      classifier
        ..submitInput()
        ..insertCharGap();
      await Future<void>.delayed(pastSilence);

      expect(events.whereType<InputComplete>(), [
        const InputComplete([Signal(MorseSignal.dot)]),
      ]);
      expect(classifier.inputBufferNotifier.value, isEmpty);
    });

    test('an empty buffer stays empty and nothing completes', () async {
      tap(y: zoneY);
      await Future<void>.delayed(pastSilence);

      expect(events, [const BottomZoneAction()]);
    });
  });

  group('without a usable height', () {
    late List<String> logs;

    setUp(() {
      logs = [];
      final originalDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
      addTearDown(() => debugPrint = originalDebugPrint);
    });

    // Replaces the shared classifier with one created with [height].
    Future<void> recreateWith({double? height}) async {
      await subscription.cancel();
      classifier.dispose();
      classifier = GestureClassifier(
        screenWidth: screenWidth,
        screenHeight: height,
        config: config,
      );
      events = [];
      subscription = classifier.events.listen(events.add);
    }

    test('there is no bottom zone until a height is set', () async {
      await recreateWith();
      expect(classifier.screenHeight, 0);

      tap(y: zoneY);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);
      expect(logs, isEmpty);

      classifier.screenHeight = screenHeight;
      tap(y: zoneY);
      await pump();
      expect(events.last, const BottomZoneAction());
    });

    test('an unusable initial height is logged', () async {
      await recreateWith(height: 0);

      expect(logs.single, contains('initial screen height 0.0 is unusable'));

      tap(y: zoneY);
      await pump();
      expect(events, [const MorseInput(MorseSignal.dot)]);
    });

    for (final unusable in [0.0, -1.0, double.nan, double.infinity]) {
      test(
        'ignores unusable height $unusable and keeps the last usable one',
        () async {
          classifier.screenHeight = unusable;

          expect(classifier.screenHeight, screenHeight);
          expect(logs.single, contains('ignoring unusable screen height'));

          // The zone still starts at y = 510.
          tap(y: zoneY);
          await pump();
          expect(events, [const BottomZoneAction()]);
        },
      );
    }
  });
}

/// Subscribes to [classifier] and calls [action] for every
/// [BottomZoneAction], as the teaching orchestrator does.
StreamSubscription<GestureEvent> actOnBottomZoneAction(
  GestureClassifier classifier,
  void Function() action,
) {
  return classifier.events.listen((event) {
    if (event is BottomZoneAction) action();
  });
}
