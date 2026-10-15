/// Configuration for shake detection.
class ShakeConfig {
  /// Creates a [ShakeConfig] with the given [shakeThreshold],
  /// [shakeCooldown], [shakeSettle] and [doubleShakeWindow].
  const ShakeConfig({
    this.shakeThreshold = 15.0,
    this.shakeCooldown = const Duration(milliseconds: 1000),
    this.shakeSettle = const Duration(milliseconds: 700),
    this.doubleShakeWindow = const Duration(milliseconds: 1500),
  });

  /// Minimum acceleration magnitude (in m/s^2, after subtracting gravity)
  /// to count as a shake.
  final double shakeThreshold;

  /// Minimum time between consecutive shake events.
  final Duration shakeCooldown;

  /// How long the acceleration must stay below [shakeThreshold] before the
  /// next strong reading counts as a new shake rather than more of the same
  /// one.
  ///
  /// The default accelerometer stream samples every 200 ms, so a reading
  /// often falls between the peaks of a shake. This spans two missed
  /// readings in a row, so one long, vigorous shake is not split into two.
  /// It is also the shortest pause that separates two shakes.
  final Duration shakeSettle;

  /// Longest pause between the end of one shake and the start of the next
  /// for the pair to count as a double shake.
  ///
  /// With the default [shakeSettle], a double shake is: shake, pause for
  /// about a second (0.7 to 1.5 s), shake again.
  final Duration doubleShakeWindow;
}
