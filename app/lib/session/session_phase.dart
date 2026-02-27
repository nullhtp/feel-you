/// The current phase of a learning session.
///
/// - [playing]: The app is vibrating the current letter's Morse pattern.
/// - [listening]: The app is waiting for the user to tap their answer.
/// - [feedback]: The app is delivering success or error feedback.
enum SessionPhase {
  /// The app is playing (vibrating) the current letter's Morse pattern.
  playing,

  /// The app is listening for user input.
  listening,

  /// The app is delivering feedback (success or error vibration).
  feedback,
}
