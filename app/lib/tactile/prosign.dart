/// A prosign: a service signal that says what is happening ("end of
/// message", "wait") instead of spelling a text.
///
/// The set is closed and the same in every language. Callers name a prosign
/// and leave its pattern to the codec (see `TactileCodec.encodeProsign`),
/// which plays it as one character: a run of pulses with no character gap
/// inside. The Morse codec uses the International Morse prosigns named
/// below, identical in all six languages, and timed like any character.
///
/// Nothing in the app plays a prosign yet; each value says which feature it
/// is for.
enum Prosign {
  /// End of message: Morse AR, `· − · − ·`.
  ///
  /// Marks the end of a text in the text reader (#44).
  endOfMessage,

  /// Wait: Morse AS, `· − · · ·`.
  ///
  /// Plays while the app is working on something, such as a cloud request
  /// (#64).
  wait,

  /// Distress: Morse SOS, `· · · − − − · · ·`, sent as one character.
  ///
  /// Reserved for the emergency gesture (#80).
  sos,

  /// Error: eight Morse dots, written HH.
  ///
  /// The sender's "I made a mistake" in Morse input (#53). Not the app's
  /// *wrong* signal (`VibrationService.playError`), which is deliberately
  /// not Morse.
  error,
}
