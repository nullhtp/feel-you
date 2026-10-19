import 'package:feel_you/morse/morse_alphabet_registry.dart';
import 'package:feel_you/morse/morse_codec.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [MorseAlphabetRegistry] that resolves alphabets and levels.
///
/// Defaults to the global [morseRegistry]. Override this provider in tests to
/// substitute a smaller or differently ordered registry; the session notifier
/// picks it up through `sessionNotifierProvider`.
final morseRegistryProvider = Provider<MorseAlphabetRegistry>(
  (ref) => morseRegistry,
);

/// Provides the [TactileCodec] that turns text in a language into tactile
/// tokens and into the companion overlay's notation.
///
/// Defaults to the [MorseCodec] of the language, looking characters up in
/// [morseRegistryProvider]. Everything that plays or shows a text in a
/// language reads it here: the teaching loop, the language picker and the
/// companion overlay. Override it in tests to substitute another codec.
final tactileCodecProvider = Provider.family<TactileCodec, MorseLanguage>(
  (ref, language) =>
      MorseCodec(language, registry: ref.watch(morseRegistryProvider)),
);
