import 'dart:async';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/shake_detector.dart';

/// A fake [ShakeDetector] for testing.
///
/// Exposes a [StreamController] for injecting gesture events without
/// requiring a real accelerometer.
class FakeShakeDetector extends ShakeDetector {
  FakeShakeDetector()
    : _testController = StreamController<GestureEvent>.broadcast(),
      // Provide a never-emitting stream so the real constructor
      // doesn't try to use a real accelerometer.
      super(accelerometerStream: const Stream.empty());

  final StreamController<GestureEvent> _testController;

  @override
  Stream<GestureEvent> get events => _testController.stream;

  /// Injects a gesture event into the stream.
  void addEvent(GestureEvent event) {
    _testController.add(event);
  }

  @override
  void dispose() {
    _testController.close();
    super.dispose();
  }
}
