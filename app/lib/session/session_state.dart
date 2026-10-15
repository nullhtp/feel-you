import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Immutable snapshot of the learning session.
///
/// Tracks the user's selected language, current level and position within
/// the language-filtered level list, and the current phase of the teaching
/// loop.
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
  /// [registry] resolves the level list; defaults to the global
  /// [morseRegistry].
  const SessionState({
    required this.language,
    this.levelIndex = 0,
    this.positionIndex = 0,
    this.phase = SessionPhase.playing,
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

  /// The current character as a string (e.g. "0", "A", "ا").
  String get currentCharacter => currentLevel.characters[positionIndex];

  /// Returns a copy with the given fields replaced.
  ///
  /// The copy keeps this state's [registry].
  SessionState copyWith({
    MorseLanguage? language,
    int? levelIndex,
    int? positionIndex,
    SessionPhase? phase,
  }) {
    return SessionState(
      language: language ?? this.language,
      levelIndex: levelIndex ?? this.levelIndex,
      positionIndex: positionIndex ?? this.positionIndex,
      phase: phase ?? this.phase,
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
    registry,
  ];

  @override
  String toString() =>
      'SessionState(language: $language, level: ${currentLevel.name}, '
      'character: $currentCharacter, phase: $phase)';
}
