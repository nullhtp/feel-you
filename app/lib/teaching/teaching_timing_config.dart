/// Configuration for the teaching loop timing.
///
/// All durations have sensible defaults and can be overridden
/// at construction time for tuning or testing.
class TeachingTimingConfig {
  const TeachingTimingConfig({
    this.repeatPause = const Duration(milliseconds: 3000),
    this.postFeedbackPause = const Duration(milliseconds: 500),
    this.spellingLetterGap = const Duration(milliseconds: 1000),
    this.quizMarkerGap = const Duration(milliseconds: 1000),
  });

  /// Pause between pattern repetitions in the play-wait-repeat loop.
  ///
  /// After the orchestrator finishes vibrating the current letter's
  /// Morse pattern, it waits this long before replaying it.
  final Duration repeatPause;

  /// Pause after feedback (success/error) vibration before resuming the loop.
  ///
  /// Gives the user time to register the feedback before the next
  /// Morse pattern begins.
  final Duration postFeedbackPause;

  /// Silence between the letters when a word is spelled before it is drilled.
  ///
  /// When the loop starts on a word, the orchestrator first plays the word
  /// one letter at a time with this gap, so a user who knows the letters can
  /// tell which word it is. It must be clearly longer than the 300 ms gap
  /// between the letters of a drilled word, and clearly shorter than
  /// [repeatPause], so the spelled letters still belong together.
  final Duration spellingLetterGap;

  /// Silence between the `?` marker and the first quiz item.
  ///
  /// When the user enters a level's quiz, the orchestrator plays Morse `?`
  /// to tell them where they are, waits this long, then plays the quiz
  /// item. The gap keeps the marker from running into the item.
  final Duration quizMarkerGap;
}
