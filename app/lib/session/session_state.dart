import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Immutable snapshot of the learning session.
///
/// Tracks the user's current position in the A-Z learning sequence
/// and the current phase of the teaching loop.
@immutable
class SessionState extends Equatable {
  /// Creates a session state.
  ///
  /// [letterIndex] must be in the range `[0, morseLetters.length)`.
  const SessionState({this.letterIndex = 0, this.phase = SessionPhase.playing});

  /// Zero-based index into [morseLetters] (0 = A, 25 = Z).
  final int letterIndex;

  /// The current phase of the teaching loop.
  final SessionPhase phase;

  /// The current letter as an uppercase string (e.g. "A", "B", ..., "Z").
  String get currentLetter => morseLetters[letterIndex];

  /// Returns a copy with the given fields replaced.
  SessionState copyWith({int? letterIndex, SessionPhase? phase}) {
    return SessionState(
      letterIndex: letterIndex ?? this.letterIndex,
      phase: phase ?? this.phase,
    );
  }

  @override
  List<Object?> get props => [letterIndex, phase];

  @override
  String toString() => 'SessionState(letter: $currentLetter, phase: $phase)';
}
