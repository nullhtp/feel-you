/// Configuration for gesture recognition thresholds.
///
/// All duration values are in milliseconds. Distance is in logical pixels.
/// Velocity is in logical pixels per second.
///
/// Dot/dash classification is position-based (left half = dot, right half =
/// dash), so no duration thresholds for dot/dash are needed.
/// CharGap insertion is explicit via the bottom input zone, so no
/// charGap threshold is needed.
class GestureTimingConfig {
  const GestureTimingConfig({
    this.resetMinDuration = 2000,
    this.silenceTimeout = 1000,
    this.minSwipeDistance = 50,
    this.minSwipeVelocity = 200,
    this.bottomZoneFraction = 0.15,
  }) : assert(
         bottomZoneFraction >= 0 && bottomZoneFraction <= 1,
         'bottomZoneFraction must be between 0 and 1',
       );

  /// Minimum press duration to trigger a reset, in ms.
  final int resetMinDuration;

  /// Time of silence after the last Morse input before emitting
  /// an input-complete event, in ms.
  final int silenceTimeout;

  /// Minimum distance for a swipe, in logical pixels, along its main
  /// axis (horizontal or vertical).
  final double minSwipeDistance;

  /// Minimum velocity for a swipe, in logical pixels per second, along its
  /// main axis (horizontal or vertical).
  final double minSwipeVelocity;

  /// Fraction of the screen height taken by the bottom input zone, measured
  /// from the bottom edge.
  ///
  /// A tap that starts in this strip is a bottom-zone action (submit, or a
  /// letter gap on word levels) instead of a dot or dash. Use `ZoneLayout`
  /// to turn it into coordinates for a given screen size.
  final double bottomZoneFraction;
}
