/// The atomic user-facing signals in Morse code.
///
/// Unlike the former `MorseSymbol`, this enum contains only the two
/// signals a user can produce — no structural separators.
enum MorseSignal {
  /// A short signal (·).
  dot,

  /// A long signal (−).
  dash,
}
