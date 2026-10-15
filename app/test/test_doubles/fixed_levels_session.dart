import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';

/// Returns a registry whose level list is exactly [levels] for every
/// language.
///
/// The levels are registered as a single universal alphabet with no
/// characters, so the registry is only meant for level resolution, not for
/// encoding or decoding.
MorseAlphabetRegistry fixedLevelsRegistry(List<Level> levels) =>
    MorseAlphabetRegistry([
      MorseAlphabet(
        language: null,
        characters: const {},
        characterOrder: const [],
        levels: levels,
      ),
    ]);

/// A [SessionState] that resolves its levels from an explicit [levels] list
/// instead of the global `morseRegistry`.
///
/// Lets tests arrange levels in any order (e.g. the words level at index 0)
/// to prove that behaviour follows [Level.kind] rather than the level index.
///
/// The list is injected through [fixedLevelsRegistry], so copies made by
/// [copyWith] (plain [SessionState]s) keep resolving against it.
class FixedLevelsSessionState extends SessionState {
  /// Creates a session state that looks levels up in [levels].
  FixedLevelsSessionState({
    required List<Level> levels,
    required super.language,
    super.levelIndex,
    super.positionIndex,
    super.phase,
  }) : super(registry: fixedLevelsRegistry(levels));
}

/// A [SessionNotifier] that starts from a [FixedLevelsSessionState].
///
/// Uses the initial state's registry, so navigation bounds, [home] and
/// [selectLanguage] all stay within the fixed level list.
class FixedLevelsSessionNotifier extends SessionNotifier {
  /// Creates a notifier whose state starts as [initial].
  FixedLevelsSessionNotifier(FixedLevelsSessionState initial)
    : super(initial.language, registry: initial.registry) {
    state = initial;
  }
}

/// Returns the English levels as resolved by a registry in which the
/// English alphabet registers its levels as `[words, letters]` and is
/// registered before the digits alphabet.
///
/// The resulting order is words (0), letters (1), digits (2): the words level
/// is no longer at index 2, and index 2 now holds a characters level.
List<Level> reorderedEnglishLevels() =>
    reorderedEnglishRegistry().levelsForLanguage(MorseLanguage.english);

/// Returns a registry in which the English alphabet registers its levels as
/// `[words, letters]` and is registered before the digits alphabet.
///
/// See [reorderedEnglishLevels] for the resulting English level order.
MorseAlphabetRegistry reorderedEnglishRegistry() => MorseAlphabetRegistry([
  MorseAlphabet(
    language: MorseLanguage.english,
    characters: englishAlphabet.characters,
    characterOrder: englishAlphabet.characterOrder,
    wordList: englishAlphabet.wordList,
    wordPatterns: englishAlphabet.wordPatterns,
    levels: englishAlphabet.levels.reversed.toList(),
  ),
  digitAlphabet,
]);
