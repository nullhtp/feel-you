import 'package:feel_you/morse/morse.dart';

/// A mode the home menu opens, in the order the menu shows them, left to
/// right.
///
/// Each mode is announced by its [letter] in International Morse: the
/// letter is encoded with the codec of [identifierLanguage] (English, plain
/// International Morse), whatever language the lessons are in. The letters
/// are chosen so the pattern is also a letter of the lesson languages (L is
/// Arabic ل and Russian Л, S is س and С, and both are L and S in Spanish,
/// French and German), so the user feels a letter they are learning.
///
/// To add a mode (R = Read #44, T = Talk #51, ...), add a value where it
/// should appear in the menu and give `HomeMenuSurface` the screen it opens:
/// its switch over this enum is exhaustive, so the compiler points at it.
/// Its identifier must differ from every other mode's.
enum HomeMenuMode {
  /// The Morse lessons.
  learn(letter: 'L', label: 'Learn', hint: 'Opens the Morse lessons'),

  /// The settings. Until the settings list exists (#45) this is the
  /// language picker.
  settings(letter: 'S', label: 'Settings', hint: 'Opens the language choice');

  const HomeMenuMode({
    required this.letter,
    required this.label,
    required this.hint,
  });

  /// The language whose codec plays the modes' letters: English, i.e.
  /// International Morse.
  static const identifierLanguage = MorseLanguage.english;

  /// The Latin letter that identifies this mode, played in International
  /// Morse (e.g. `· − · ·` for L).
  final String letter;

  /// The mode's name, drawn for a sighted helper and read by screen
  /// readers.
  final String label;

  /// What activating the mode does, for screen readers.
  final String hint;
}
