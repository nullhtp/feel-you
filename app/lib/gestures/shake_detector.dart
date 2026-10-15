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
///
/// Detection can be suspended with [pause] (e.g. while the app is in the
/// background) and restarted with [resume].
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
       _accelerometerStream = accelerometerStream ?? accelerometerEventStream(),
       _controller = StreamController<GestureEvent>.broadcast() {
    _subscription = _listen();
  }

  final ShakeConfig _config;
  final Stream<AccelerometerEvent> _accelerometerStream;
  final StreamController<GestureEvent> _controller;
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeTime;
  bool _isPaused = false;

  /// Stream of [GestureEvent]s emitted when a shake is detected.
  Stream<GestureEvent> get events => _controller.stream;

  /// Whether detection is currently suspended by [pause].
  bool get isPaused => _isPaused;

  StreamSubscription<AccelerometerEvent> _listen() =>
      _accelerometerStream.listen(_onAccelerometerEvent, onError: _onError);

  /// Suspends shake detection until [resume] is called.
  ///
  /// No [Home] events are emitted while paused. A broadcast accelerometer
  /// stream (such as the default sensors_plus stream) is unsubscribed, so
  /// the platform can stop the sensor and save battery. A single-subscription
  /// stream cannot be listened to again, so it stays subscribed and its
  /// events are dropped instead.
  ///
  /// No-op if already paused or after [dispose].
  void pause() {
    if (_isPaused || _controller.isClosed) return;
    _isPaused = true;
    if (_accelerometerStream.isBroadcast) {
      unawaited(_subscription?.cancel());
      _subscription = null;
    }
  }

  /// Restarts shake detection after [pause].
  ///
  /// No-op if not paused or after [dispose].
  void resume() {
    if (!_isPaused || _controller.isClosed) return;
    _isPaused = false;
    _subscription ??= _listen();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (_isPaused) return;

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
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }
}
