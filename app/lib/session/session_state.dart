import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/levels.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Immutable snapshot of the learning session.
///
/// Tracks the user's current level and position within that level,
/// and the current phase of the teaching loop.
@immutable
class SessionState extends Equatable {
  /// Creates a session state.
  ///
  /// [levelIndex] selects the level (0 = digits, 1 = letters).
  /// [positionIndex] selects the character within that level.
  const SessionState({
    this.levelIndex = 0,
    this.positionIndex = 0,
    this.phase = SessionPhase.playing,
  });

  /// Zero-based index into [levels] (0 = digits, 1 = letters).
  final int levelIndex;

  /// Zero-based index into the current level's character list.
  final int positionIndex;

  /// The current phase of the teaching loop.
  final SessionPhase phase;

  /// The current [Level] object.
  Level get currentLevel => levels[levelIndex];

  /// The current character as a string (e.g. "0", "A").
  String get currentCharacter => levels[levelIndex].characters[positionIndex];

  /// Returns a copy with the given fields replaced.
  SessionState copyWith({
    int? levelIndex,
    int? positionIndex,
    SessionPhase? phase,
  }) {
    return SessionState(
      levelIndex: levelIndex ?? this.levelIndex,
      positionIndex: positionIndex ?? this.positionIndex,
      phase: phase ?? this.phase,
    );
  }

  @override
  List<Object?> get props => [levelIndex, positionIndex, phase];

  @override
  String toString() =>
      'SessionState(level: ${currentLevel.name}, '
      'character: $currentCharacter, phase: $phase)';
}
