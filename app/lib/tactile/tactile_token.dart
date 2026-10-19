/// One element of a tactile pattern: what a codec produces and the
/// vibration engine plays.
///
/// A token says what is felt, never for how long. The engine maps each token
/// to a duration from its timing configuration, so the same tokens feel the
/// same whichever codec produced them, and a speed setting never has to
/// re-encode text. Amplitude never carries meaning (some motors have none),
/// so tokens have no strength either.
///
/// Morse uses the two pulses, the character gap and the word gap. A prosign
/// is one character of its codec: a run of pulses with no [characterGap] or
/// [wordGap] inside. [emptySlot] is there for codecs that place signals in
/// fixed time slots, such as a braille cell of six slots, each a pulse
/// (raised dot) or an empty slot (flat dot).
enum TactileToken {
  /// A short vibration, e.g. a Morse dot.
  shortPulse,

  /// A long vibration, e.g. a Morse dash.
  longPulse,

  /// A silence as long as a [shortPulse], e.g. a flat braille dot.
  emptySlot,

  /// The pause between two characters of a word.
  characterGap,

  /// The pause between two words, in place of a [characterGap].
  wordGap,
}

/// Splits [tokens] at their [TactileToken.characterGap]s and
/// [TactileToken.wordGap]s into the tokens of each character, in order.
///
/// Lets a caller play a text one character at a time (e.g. spelling a word)
/// without knowing which codec encoded it. A word gap is a boundary between
/// two characters too, so each part is one character with no gap inside,
/// whether the text has one word or several. A pattern without a gap is a
/// single character, and an empty pattern has none.
List<List<TactileToken>> splitAtCharacterGaps(List<TactileToken> tokens) {
  if (tokens.isEmpty) return const [];
  final characters = <List<TactileToken>>[[]];
  for (final token in tokens) {
    if (token == TactileToken.characterGap || token == TactileToken.wordGap) {
      characters.add([]);
    } else {
      characters.last.add(token);
    }
  }
  return characters;
}
