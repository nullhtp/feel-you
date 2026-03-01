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
  /// Creates a notifier with an initial state for [language].
  SessionNotifier(MorseLanguage language)
    : super(SessionState(language: language));

  /// Selects a new [language], resetting to level 0, position 0, playing.
  void selectLanguage(MorseLanguage language) {
    state = SessionState(language: language);
  }

  /// Advances to the next position within the current level.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the last position.
  void nextPosition() {
    final filteredLevels = morseRegistry.levelsForLanguage(state.language);
    final maxIndex = filteredLevels[state.levelIndex].characters.length - 1;
    if (state.positionIndex >= maxIndex) return;
    state = state.copyWith(
      positionIndex: state.positionIndex + 1,
      phase: SessionPhase.playing,
    );
  }

  /// Moves to the previous position within the current level.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the first position.
  void previousPosition() {
    if (state.positionIndex <= 0) return;
    state = state.copyWith(
      positionIndex: state.positionIndex - 1,
      phase: SessionPhase.playing,
    );
  }

  /// Resets the position to the first character of the current level.
  ///
  /// Sets the phase to [SessionPhase.playing]. Does NOT change levelIndex.
  void reset() {
    state = state.copyWith(positionIndex: 0, phase: SessionPhase.playing);
  }

  /// Advances to the next level, resetting position to 0.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the last level.
  void nextLevel() {
    final filteredLevels = morseRegistry.levelsForLanguage(state.language);
    if (state.levelIndex >= filteredLevels.length - 1) return;
    state = state.copyWith(
      levelIndex: state.levelIndex + 1,
      positionIndex: 0,
      phase: SessionPhase.playing,
    );
  }

  /// Moves to the previous level, resetting position to 0.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the first level.
  void previousLevel() {
    if (state.levelIndex <= 0) return;
    state = state.copyWith(
      levelIndex: state.levelIndex - 1,
      positionIndex: 0,
      phase: SessionPhase.playing,
    );
  }

  /// Resets to the very beginning: level 0, position 0, playing.
  /// The selected language is preserved.
  void home() {
    state = SessionState(language: state.language);
  }

  /// Updates the session phase without changing the current position or level.
  void setPhase(SessionPhase phase) {
    state = state.copyWith(phase: phase);
  }
}
