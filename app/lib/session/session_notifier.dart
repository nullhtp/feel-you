import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages [SessionState] mutations for the learning session.
///
/// The orchestrator (teaching loop) drives transitions by calling these
/// methods. No transition validation is enforced here — the orchestrator
/// owns the valid transition sequences.
class SessionNotifier extends StateNotifier<SessionState> {
  /// Creates a notifier with the default initial state (letter A, playing).
  SessionNotifier() : super(const SessionState());

  /// The index of the last letter in the learning sequence.
  static final int _maxIndex = morseLetters.length - 1;

  /// Advances to the next letter in the sequence.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the last letter (Z).
  void nextLetter() {
    if (state.letterIndex >= _maxIndex) return;
    state = state.copyWith(
      letterIndex: state.letterIndex + 1,
      phase: SessionPhase.playing,
    );
  }

  /// Moves to the previous letter in the sequence.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the first letter (A).
  void previousLetter() {
    if (state.letterIndex <= 0) return;
    state = state.copyWith(
      letterIndex: state.letterIndex - 1,
      phase: SessionPhase.playing,
    );
  }

  /// Resets the session to letter A with phase [SessionPhase.playing].
  void reset() {
    state = const SessionState();
  }

  /// Updates the session phase without changing the current letter.
  void setPhase(SessionPhase phase) {
    state = state.copyWith(phase: phase);
  }
}
