import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Immutable snapshot of the learning session.
///
/// Tracks the user's selected language, current level and position within
/// the language-filtered level list, whether the session is in the level's
/// quiz (and its item), and the current phase of the teaching loop.
///
/// Levels are resolved through [registry], which caches each language's
/// level list, so [currentLevel] and [currentCharacter] are cheap to read on
/// hot paths (widget builds, every teaching-loop iteration).
@immutable
class SessionState extends Equatable {
  /// Creates a session state.
  ///
  /// [language] selects which Morse alphabet is active.
  /// [levelIndex] selects the level within the language-filtered list
  /// (0 = digits, 1 = letters, 2 = words).
  /// [positionIndex] selects the character within that level.
  /// [quizItem], when not `null`, puts the session in the level's quiz with
  /// that item; [positionIndex] then stays on the level's last item.
  /// [registry] resolves the level list; defaults to the global
  /// [morseRegistry].
  const SessionState({
    required this.language,
    this.levelIndex = 0,
    this.positionIndex = 0,
    this.phase = SessionPhase.playing,
    this.quizItem,
    MorseAlphabetRegistry? registry,
  }) : _registry = registry;

  /// The Morse language/alphabet the user is learning.
  final MorseLanguage language;

  /// Zero-based index into the language-filtered levels list.
  ///
  /// The index only reflects registration order; use [currentLevel]'s
  /// [Level.kind] to decide level-specific behaviour.
  final int levelIndex;

  /// Zero-based index into the current level's character list.
  final int positionIndex;

  /// The current phase of the teaching loop.
  final SessionPhase phase;

  /// The item the quiz is playing, or `null` outside the quiz.
  ///
  /// The quiz comes after the last item of every level. While the session
  /// is in it, [positionIndex] stays on the last item, so leaving the quiz
  /// to the left lands there.
  final String? quizItem;

  /// Whether the session is in the current level's quiz.
  bool get isInQuiz => quizItem != null;

  /// The registry passed to the constructor, or `null` for the global one.
  ///
  /// Kept nullable so the constructor stays `const`: the global
  /// [morseRegistry] is not a compile-time constant.
  final MorseAlphabetRegistry? _registry;

  /// The registry that [levels] are resolved from.
  MorseAlphabetRegistry get registry => _registry ?? morseRegistry;

  /// The levels available for the selected [language], in [registry] order.
  ///
  /// The registry caches this list, so it is the same instance on every read
  /// and follows [language] automatically after [copyWith].
  List<Level> get levels => registry.levelsForLanguage(language);

  /// The current [Level] object.
  Level get currentLevel => levels[levelIndex];

  /// The item being taught: the [quizItem] in the quiz, otherwise the item
  /// at [positionIndex] (e.g. "0", "A", "ا").
  String get currentCharacter =>
      quizItem ?? currentLevel.characters[positionIndex];

  /// Returns a copy with the given fields replaced.
  ///
  /// The copy keeps this state's [registry] and, unless [quizItem] replaces
  /// it or [leaveQuiz] is set, its [quizItem]. [leaveQuiz] takes the copy
  /// out of the quiz, which passing `null` as [quizItem] cannot.
  SessionState copyWith({
    MorseLanguage? language,
    int? levelIndex,
    int? positionIndex,
    SessionPhase? phase,
    String? quizItem,
    bool leaveQuiz = false,
  }) {
    return SessionState(
      language: language ?? this.language,
      levelIndex: levelIndex ?? this.levelIndex,
      positionIndex: positionIndex ?? this.positionIndex,
      phase: phase ?? this.phase,
      quizItem: leaveQuiz ? null : quizItem ?? this.quizItem,
      registry: _registry,
    );
  }

  /// Compares the resolved [registry] by identity, so a state built without a
  /// registry equals one built with the global [morseRegistry], while states
  /// that resolve levels from different registries are never equal.
  @override
  List<Object?> get props => [
    language,
    levelIndex,
    positionIndex,
    phase,
    quizItem,
    registry,
  ];

  @override
  String toString() =>
      'SessionState(language: $language, level: ${currentLevel.name}, '
      'character: $currentCharacter, ${isInQuiz ? 'in the quiz, ' : ''}'
      'phase: $phase)';
}
