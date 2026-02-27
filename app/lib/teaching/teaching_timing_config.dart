/// Configuration for the teaching loop timing.
///
/// All durations have sensible defaults and can be overridden
/// at construction time for tuning or testing.
class TeachingTimingConfig {
  const TeachingTimingConfig({
    this.repeatPause = const Duration(milliseconds: 3000),
  });

  /// Pause between pattern repetitions in the play-wait-repeat loop.
  ///
  /// After the orchestrator finishes vibrating the current letter's
  /// Morse pattern, it waits this long before replaying it.
  final Duration repeatPause;
}
