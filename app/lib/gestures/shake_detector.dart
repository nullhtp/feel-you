import 'dart:async';
import 'dart:math';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/shake_config.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects device shakes via accelerometer data and emits [Home] events.
///
/// Subscribes to an accelerometer stream, computes the magnitude of the
/// acceleration vector minus gravity, and when the magnitude exceeds
/// [ShakeConfig.shakeThreshold], emits a [Home] event on the [events] stream.
///
/// A cooldown period ([ShakeConfig.shakeCooldown]) is enforced between
/// consecutive emissions.
class ShakeDetector {
  /// Creates a [ShakeDetector].
  ///
  /// If [accelerometerStream] is provided it will be used instead of the
  /// default [accelerometerEventStream] from sensors_plus. This is useful
  /// for testing.
  ShakeDetector({
    ShakeConfig config = const ShakeConfig(),
    Stream<AccelerometerEvent>? accelerometerStream,
  }) : _config = config,
       _controller = StreamController<GestureEvent>.broadcast() {
    _subscription = (accelerometerStream ?? accelerometerEventStream()).listen(
      _onAccelerometerEvent,
      onError: _onError,
    );
  }

  final ShakeConfig _config;
  final StreamController<GestureEvent> _controller;
  late final StreamSubscription<AccelerometerEvent> _subscription;
  DateTime? _lastShakeTime;

  /// Stream of [GestureEvent]s emitted when a shake is detected.
  Stream<GestureEvent> get events => _controller.stream;

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.81;

    if (magnitude < _config.shakeThreshold) return;

    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!) < _config.shakeCooldown) {
      return;
    }

    _lastShakeTime = now;
    if (!_controller.isClosed) {
      _controller.add(const Home());
    }
  }

  void _onError(Object error) {
    // Gracefully ignore accelerometer stream errors to avoid crashing.
  }

  /// Cancels the accelerometer subscription and closes the event stream.
  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
