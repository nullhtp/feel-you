/// Configuration for gesture recognition timing thresholds.
///
/// All duration values are in milliseconds. Distance is in logical pixels.
/// Velocity is in logical pixels per second.
class GestureTimingConfig {
  const GestureTimingConfig({
    this.dotMaxDuration = 150,
    this.dashMaxDuration = 500,
    this.resetMinDuration = 2000,
    this.silenceTimeout = 1000,
    this.minSwipeDistance = 50,
    this.minSwipeVelocity = 200,
  });

  /// Maximum press duration (exclusive) to classify as a dot, in ms.
  final int dotMaxDuration;

  /// Maximum press duration (inclusive) to classify as a dash, in ms.
  /// Presses between [dotMaxDuration] (inclusive) and this value (inclusive)
  /// are classified as dashes.
  final int dashMaxDuration;

  /// Minimum press duration to trigger a reset, in ms.
  /// Presses longer than [dashMaxDuration] but shorter than this value
  /// fall in the dead zone and are ignored.
  final int resetMinDuration;

  /// Time of silence after the last Morse input before emitting
  /// an input-complete event, in ms.
  final int silenceTimeout;

  /// Minimum horizontal distance for a swipe, in logical pixels.
  final double minSwipeDistance;

  /// Minimum horizontal velocity for a swipe, in logical pixels per second.
  final double minSwipeVelocity;
}
