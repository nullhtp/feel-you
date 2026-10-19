import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/quiz_item_picker.dart';
import 'package:feel_you/session/session_phase.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages [SessionState] mutations for the learning session.
///
/// The orchestrator (teaching loop) drives transitions by calling these
/// methods. No transition validation is enforced here — the orchestrator
/// owns the valid transition sequences.
///
/// Every state it creates resolves its levels from [registry]; level and
/// position bounds are checked against the current state's
/// [SessionState.levels].
///
/// Every level ends with a quiz, one step to the right of its last item:
/// [nextPosition] enters it and draws its items with [quizItemPicker], and
/// every other move leaves it.
class SessionNotifier extends StateNotifier<SessionState> {
  /// Creates a notifier with an initial state for [language].
  ///
  /// [registry] supplies the alphabets and levels; defaults to the global
  /// [morseRegistry]. [quizItemPicker] draws the quiz items; defaults to one
  /// that draws from the whole level.
  SessionNotifier(
    MorseLanguage language, {
    MorseAlphabetRegistry? registry,
    QuizItemPicker? quizItemPicker,
  }) : this._(
         language,
         registry ?? morseRegistry,
         quizItemPicker ?? QuizItemPicker(),
       );

  SessionNotifier._(MorseLanguage language, this.registry, this.quizItemPicker)
    : super(SessionState(language: language, registry: registry));

  /// The registry every state created by this notifier resolves levels from.
  final MorseAlphabetRegistry registry;

  /// Draws the items of the quiz.
  final QuizItemPicker quizItemPicker;

  /// Selects a new [language], resetting to level 0, position 0, playing,
  /// outside the quiz.
  void selectLanguage(MorseLanguage language) {
    state = SessionState(language: language, registry: registry);
  }

  /// Advances to the next position within the current level.
  ///
  /// On the last item it enters the level's quiz, and in the quiz it draws
  /// another quiz item (see [nextQuizItem]). The position stays on the last
  /// item. Resets the phase to [SessionPhase.playing].
  void nextPosition() {
    final maxIndex = state.currentLevel.characters.length - 1;
    if (state.isInQuiz || state.positionIndex >= maxIndex) {
      _drawQuizItem();
      return;
    }
    state = state.copyWith(
      positionIndex: state.positionIndex + 1,
      phase: SessionPhase.playing,
    );
  }

  /// Draws a new quiz item, other than the current one, and resets the phase
  /// to [SessionPhase.playing].
  ///
  /// No-op outside the quiz.
  void nextQuizItem() {
    if (!state.isInQuiz) return;
    _drawQuizItem();
  }

  void _drawQuizItem() {
    state = state.copyWith(
      quizItem: quizItemPicker.pick(
        state.language,
        state.currentLevel,
        previous: state.quizItem,
      ),
      phase: SessionPhase.playing,
    );
  }

  /// Moves to the previous position within the current level.
  ///
  /// In the quiz it leaves the quiz, back to the level's last item. Resets
  /// the phase to [SessionPhase.playing].
  /// No-op if already at the first position.
  void previousPosition() {
    if (state.isInQuiz) {
      state = state.copyWith(leaveQuiz: true, phase: SessionPhase.playing);
      return;
    }
    if (state.positionIndex <= 0) return;
    state = state.copyWith(
      positionIndex: state.positionIndex - 1,
      phase: SessionPhase.playing,
    );
  }

  /// Resets the position to the first character of the current level,
  /// leaving the quiz.
  ///
  /// Sets the phase to [SessionPhase.playing]. Does NOT change levelIndex.
  void reset() {
    state = state.copyWith(
      positionIndex: 0,
      phase: SessionPhase.playing,
      leaveQuiz: true,
    );
  }

  /// Advances to the next level, resetting position to 0 and leaving the
  /// quiz.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the last level, even in its quiz.
  void nextLevel() {
    if (state.levelIndex >= state.levels.length - 1) return;
    state = state.copyWith(
      levelIndex: state.levelIndex + 1,
      positionIndex: 0,
      phase: SessionPhase.playing,
      leaveQuiz: true,
    );
  }

  /// Moves to the previous level, resetting position to 0 and leaving the
  /// quiz.
  ///
  /// Resets the phase to [SessionPhase.playing].
  /// No-op if already at the first level, even in its quiz.
  void previousLevel() {
    if (state.levelIndex <= 0) return;
    state = state.copyWith(
      levelIndex: state.levelIndex - 1,
      positionIndex: 0,
      phase: SessionPhase.playing,
      leaveQuiz: true,
    );
  }

  /// Resets to the very beginning: level 0, position 0, playing, outside
  /// the quiz. The selected language is preserved.
  void home() {
    state = SessionState(language: state.language, registry: registry);
  }

  /// Updates the session phase without changing the current position or level.
  void setPhase(SessionPhase phase) {
    state = state.copyWith(phase: phase);
  }
}
