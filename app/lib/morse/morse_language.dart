/// Identifies which Morse code language/alphabet the user is learning.
///
/// The order is the order of the languages in the picker. Add a new
/// language at the end and never rename a value: the saved language and the
/// learned items are stored under the value's [name].
enum MorseLanguage {
  /// International Morse Code — Latin letters A-Z.
  english,

  /// Arabic Morse Code — Arabic letters.
  arabic,

  /// Russian Morse Code — Cyrillic letters.
  russian,

  /// Spanish Morse Code — Latin letters A-Z and Ñ.
  spanish,

  /// French Morse Code — Latin letters A-Z, À, Ç, É and È.
  french,

  /// German Morse Code — Latin letters A-Z, Ä, Ö and Ü.
  german,
}
