import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';

/// A [SessionState] that resolves its level from an explicit [levels] list
/// instead of the global `morseRegistry`.
///
/// Lets tests arrange levels in any order (e.g. the words level at index 0)
/// to prove that behaviour follows [Level.kind] rather than the level index.
class FixedLevelsSessionState extends SessionState {
  /// Creates a session state that looks levels up in [levels].
  const FixedLevelsSessionState({
    required this.levels,
    required super.language,
    super.levelIndex,
    super.positionIndex,
    super.phase,
  });

  /// The ordered levels this session resolves [levelIndex] against.
  final List<Level> levels;

  @override
  Level get currentLevel => levels[levelIndex];

  @override
  String get currentCharacter => currentLevel.characters[positionIndex];

  @override
  FixedLevelsSessionState copyWith({
    MorseLanguage? language,
    int? levelIndex,
    int? positionIndex,
    SessionPhase? phase,
  }) {
    return FixedLevelsSessionState(
      levels: levels,
      language: language ?? this.language,
      levelIndex: levelIndex ?? this.levelIndex,
      positionIndex: positionIndex ?? this.positionIndex,
      phase: phase ?? this.phase,
    );
  }

  @override
  List<Object?> get props => [...super.props, levels];
}

/// A [SessionNotifier] that starts from a [FixedLevelsSessionState].
///
/// Phase changes keep the fixed level list. Navigation bounds and
/// [home]/[selectLanguage] still use the app registry, so tests should stay
/// on the initial level.
class FixedLevelsSessionNotifier extends SessionNotifier {
  /// Creates a notifier whose state starts as [initial].
  FixedLevelsSessionNotifier(FixedLevelsSessionState initial)
    : super(initial.language) {
    state = initial;
  }
}

/// Returns the English levels as resolved by a registry in which the
/// English alphabet registers its levels as `[words, letters]` and is
/// registered before the digits alphabet.
///
/// The resulting order is words (0), letters (1), digits (2): the words level
/// is no longer at index 2, and index 2 now holds a characters level.
List<Level> reorderedEnglishLevels() {
  final registry = MorseAlphabetRegistry([
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
  return registry.levelsForLanguage(MorseLanguage.english);
}
