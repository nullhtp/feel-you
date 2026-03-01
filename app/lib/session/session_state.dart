import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Immutable snapshot of the learning session.
///
/// Tracks the user's selected language, current level and position within
/// the language-filtered level list, and the current phase of the teaching
/// loop.
@immutable
class SessionState extends Equatable {
  /// Creates a session state.
  ///
  /// [language] selects which Morse alphabet is active.
  /// [levelIndex] selects the level within the language-filtered list
  /// (0 = digits, 1 = letters, 2 = words).
  /// [positionIndex] selects the character within that level.
  const SessionState({
    required this.language,
    this.levelIndex = 0,
    this.positionIndex = 0,
    this.phase = SessionPhase.playing,
  });

  /// The Morse language/alphabet the user is learning.
  final MorseLanguage language;

  /// Zero-based index into the language-filtered levels list.
  final int levelIndex;

  /// Zero-based index into the current level's character list.
  final int positionIndex;

  /// The current phase of the teaching loop.
  final SessionPhase phase;

  /// The levels available for the selected [language].
  List<Level> get _levels => levelsForLanguage(language);

  /// The current [Level] object.
  Level get currentLevel => _levels[levelIndex];

  /// The current character as a string (e.g. "0", "A", "ا").
  String get currentCharacter => _levels[levelIndex].characters[positionIndex];

  /// Returns a copy with the given fields replaced.
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
    );
  }

  @override
  List<Object?> get props => [language, levelIndex, positionIndex, phase];

  @override
  String toString() =>
      'SessionState(language: $language, level: ${currentLevel.name}, '
      'character: $currentCharacter, phase: $phase)';
}
