import 'package:feel_you/tactile/tactile_token.dart';

/// Turns text into tactile tokens, and into a written form of the same
/// pattern for a sighted helper.
///
/// Everything that plays or shows a text goes through this interface, so it
/// does not depend on which code is in use. Morse (`MorseCodec`) is the
/// first implementation.
abstract interface class TactileCodec {
  /// The tokens that play [text], with a [TactileToken.characterGap] between
  /// consecutive characters.
  ///
  /// Returns an empty list for an empty [text]. Throws an [ArgumentError]
  /// if [text] contains a character this codec cannot encode.
  List<TactileToken> encode(String text);

  /// The written form of the pattern [encode] returns for [text], as the
  /// companion overlay shows it (e.g. `· · / —` for Morse "IT").
  ///
  /// Throws an [ArgumentError] for the characters [encode] rejects.
  String describe(String text);
}
