import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';

/// A fake [GestureClassifier] for testing.
///
/// Exposes a [StreamController] for injecting gesture events and
/// records raw touch events for verification.
class FakeGestureClassifier extends GestureClassifier {
  FakeGestureClassifier() : super(screenWidth: 800);

  final _testController = StreamController<GestureEvent>.broadcast();

  /// Raw touch events received via [handleTouch].
  final List<RawTouchEvent> touchEvents = [];

  /// Calls to [insertCharGap].
  int insertCharGapCallCount = 0;

  /// Calls to [submitInput].
  int submitInputCallCount = 0;

  @override
  Stream<GestureEvent> get events => _testController.stream;

  /// Injects a gesture event into the stream.
  void addEvent(GestureEvent event) {
    _testController.add(event);
  }

  @override
  void handleTouch(RawTouchEvent event) {
    touchEvents.add(event);
  }

  @override
  void insertCharGap() {
    insertCharGapCallCount++;
  }

  @override
  void submitInput() {
    submitInputCallCount++;
  }

  @override
  void dispose() {
    _testController.close();
    super.dispose();
  }
}
