import 'package:feel_you/morse/morse_alphabet_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [MorseAlphabetRegistry] that resolves alphabets and levels.
///
/// Defaults to the global [morseRegistry]. Override this provider in tests to
/// substitute a smaller or differently ordered registry; the session notifier
/// picks it up through `sessionNotifierProvider`.
final morseRegistryProvider = Provider<MorseAlphabetRegistry>(
  (ref) => morseRegistry,
);
