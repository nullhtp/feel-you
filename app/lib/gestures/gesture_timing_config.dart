/// Configuration for gesture recognition timing thresholds.
///
/// All duration values are in milliseconds. Distance is in logical pixels.
/// Velocity is in logical pixels per second.
///
/// Dot/dash classification is position-based (left half = dot, right half =
/// dash), so no duration thresholds for dot/dash are needed.
class GestureTimingConfig {
  const GestureTimingConfig({
    this.resetMinDuration = 2000,
    this.silenceTimeout = 1000,
    this.charGapThreshold = 400,
    this.minSwipeDistance = 50,
    this.minSwipeVelocity = 200,
  });

  /// Minimum press duration to trigger a reset, in ms.
  final int resetMinDuration;

  /// Time of silence after the last Morse input before emitting
  /// an input-complete event, in ms.
  final int silenceTimeout;

  /// Minimum silence duration between taps to classify as an
  /// inter-character gap (charGap) rather than an inter-symbol gap, in ms.
  /// Must be less than [silenceTimeout].
  final int charGapThreshold;

  /// Minimum horizontal distance for a swipe, in logical pixels.
  final double minSwipeDistance;

  /// Minimum horizontal velocity for a swipe, in logical pixels per second.
  final double minSwipeVelocity;
}
