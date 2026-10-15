import 'dart:async';
import 'dart:math';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/shake_config.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects device shakes via accelerometer data and emits [Home] and
/// [ChangeLanguage] events.
///
/// Subscribes to an accelerometer stream, computes the magnitude of the
/// acceleration vector minus gravity, and when the magnitude exceeds
/// [ShakeConfig.shakeThreshold], emits a [Home] event on the [events] stream.
///
/// A cooldown period ([ShakeConfig.shakeCooldown]) is enforced between
/// consecutive [Home] emissions.
///
/// A shake lasts until the acceleration has stayed below the threshold for
/// [ShakeConfig.shakeSettle]. When a new shake starts within
/// [ShakeConfig.doubleShakeWindow] of the end of the previous one, the pair
/// is a double shake: the first shake has already emitted [Home] (with no
/// added delay), and the second emits [ChangeLanguage] instead of another
/// [Home]. A third shake starts a new pair. Because one long, vigorous
/// shake never goes quiet for [ShakeConfig.shakeSettle], it never counts as
/// two.
///
/// Detection can be suspended with [pause] (e.g. while the app is in the
/// background) and restarted with [resume].
class ShakeDetector {
  /// Creates a [ShakeDetector].
  ///
  /// If [accelerometerStream] is provided it will be used instead of the
  /// default [accelerometerEventStream] from sensors_plus. This is useful
  /// for testing, as is [clock], which replaces [DateTime.now] when timing
  /// the cooldown and double shakes.
  ShakeDetector({
    ShakeConfig config = const ShakeConfig(),
    Stream<AccelerometerEvent>? accelerometerStream,
    DateTime Function()? clock,
  }) : _config = config,
       _accelerometerStream = accelerometerStream ?? accelerometerEventStream(),
       _clock = clock ?? DateTime.now,
       _controller = StreamController<GestureEvent>.broadcast() {
    _subscription = _listen();
  }

  final ShakeConfig _config;
  final Stream<AccelerometerEvent> _accelerometerStream;
  final DateTime Function() _clock;
  final StreamController<GestureEvent> _controller;
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeTime;
  bool _isPaused = false;

  /// Time of the latest reading above the threshold, i.e. the end of the
  /// current (or most recent) shake.
  DateTime? _lastStrongReadingTime;

  /// Whether the most recent shake can be the first of a double shake.
  ///
  /// False after the second shake of a pair, so a third shake starts a new
  /// pair instead of emitting [ChangeLanguage] again.
  bool _awaitingSecondShake = false;

  /// Stream of [GestureEvent]s emitted when a shake ([Home]) or a double
  /// shake ([ChangeLanguage]) is detected.
  Stream<GestureEvent> get events => _controller.stream;

  /// Whether detection is currently suspended by [pause].
  bool get isPaused => _isPaused;

  StreamSubscription<AccelerometerEvent> _listen() =>
      _accelerometerStream.listen(_onAccelerometerEvent, onError: _onError);

  /// Suspends shake detection until [resume] is called.
  ///
  /// No [Home] or [ChangeLanguage] events are emitted while paused. A
  /// broadcast accelerometer stream (such as the default sensors_plus
  /// stream) is unsubscribed, so the platform can stop the sensor and save
  /// battery. A single-subscription stream cannot be listened to again, so
  /// it stays subscribed and its events are dropped instead.
  ///
  /// A shake before the pause never pairs with one after it into a double
  /// shake.
  ///
  /// No-op if already paused or after [dispose].
  void pause() {
    if (_isPaused || _controller.isClosed) return;
    _isPaused = true;
    _lastStrongReadingTime = null;
    _awaitingSecondShake = false;
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

    final now = _clock();

    // A strong reading soon after the previous one is more of the same
    // shake; only a reading after a quiet spell starts a new shake.
    final previousStrongReading = _lastStrongReadingTime;
    _lastStrongReadingTime = now;
    final sincePreviousShake = previousStrongReading == null
        ? null
        : now.difference(previousStrongReading);
    final startsNewShake =
        sincePreviousShake == null || sincePreviousShake >= _config.shakeSettle;

    if (startsNewShake) {
      if (_awaitingSecondShake &&
          sincePreviousShake != null &&
          sincePreviousShake <= _config.doubleShakeWindow) {
        // Second shake of a double shake. The first already went home, so
        // this one only asks for the language picker. Restarting the
        // cooldown keeps the rest of this shake from emitting Home too.
        _awaitingSecondShake = false;
        _lastShakeTime = now;
        _emit(const ChangeLanguage());
        return;
      }
      _awaitingSecondShake = true;
    }

    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!) < _config.shakeCooldown) {
      return;
    }

    _lastShakeTime = now;
    _emit(const Home());
  }

  void _emit(GestureEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
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
