## 1. State Model

- [x] 1.1 Create `app/lib/session/session_phase.dart` with `SessionPhase` enum (`playing`, `listening`, `feedback`)
- [x] 1.2 Create `app/lib/session/session_state.dart` with immutable `SessionState` class (letterIndex, phase, computed currentLetter getter using `morseLetters`) and `copyWith` method
- [x] 1.3 Implement `==` and `hashCode` overrides on `SessionState`

## 2. State Notifier

- [x] 2.1 Create `app/lib/session/session_notifier.dart` with `SessionNotifier extends StateNotifier<SessionState>`
- [x] 2.2 Implement `nextLetter()` — increment index, clamp at 25 (Z), reset phase to `playing`. No-op if already at Z.
- [x] 2.3 Implement `previousLetter()` — decrement index, clamp at 0 (A), reset phase to `playing`. No-op if already at A.
- [x] 2.4 Implement `reset()` — set index to 0 and phase to `playing`
- [x] 2.5 Implement `setPhase(SessionPhase phase)` — update phase only

## 3. Riverpod Providers

- [x] 3.1 Create `app/lib/session/session_providers.dart` with `sessionNotifierProvider` (`StateNotifierProvider<SessionNotifier, SessionState>`)
- [x] 3.2 Verify provider is overridable for testing (standard StateNotifierProvider behavior)

## 4. Unit Tests

- [x] 4.1 Create `app/test/session/session_state_test.dart` — test initial state (letter A, phase playing), copyWith, equality, currentLetter getter
- [x] 4.2 Create `app/test/session/session_notifier_test.dart` — test nextLetter (normal + boundary at Z), previousLetter (normal + boundary at A), reset (from middle + from A), setPhase
- [x] 4.3 Test navigation resets phase to playing (next from non-playing phase, previous from non-playing phase, reset from non-playing phase)
- [x] 4.4 Test boundary no-ops preserve state (nextLetter at Z does not change state, previousLetter at A does not change state)

## 5. Verification

- [x] 5.1 Run `flutter test` from `app/` and confirm all existing + new tests pass
- [x] 5.2 Run `flutter analyze` from `app/` and confirm no lint warnings
