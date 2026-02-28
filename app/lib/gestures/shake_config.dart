/// Configuration for shake detection.
class ShakeConfig {
  /// Creates a [ShakeConfig] with the given [shakeThreshold] and
  /// [shakeCooldown].
  const ShakeConfig({
    this.shakeThreshold = 15.0,
    this.shakeCooldown = const Duration(milliseconds: 1000),
  });

  /// Minimum acceleration magnitude (in m/s^2, after subtracting gravity)
  /// to count as a shake.
  final double shakeThreshold;

  /// Minimum time between consecutive shake events.
  final Duration shakeCooldown;
}
