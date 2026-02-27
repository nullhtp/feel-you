## Context

The foundation layer is complete: Morse data model (`app/lib/morse/`), gesture recognition (`app/lib/gestures/`), and vibration engine (`app/lib/vibration/`). All three have Riverpod providers using the classic `Provider` API.

Currently there is no mutable application state — the existing providers all expose immutable configuration or service instances. The teaching loop orchestrator (Change 2) needs a reactive state layer to know which letter the user is on and what phase of the learning cycle is active. This change introduces that state layer.

## Goals / Non-Goals

**Goals:**
- Provide a single source of truth for the user's position in the A-Z learning sequence
- Track the session phase (playing, listening, feedback) so the orchestrator can react
- Handle navigation commands (next, previous, reset) with boundary clamping
- Expose state via Riverpod so downstream consumers can watch for changes
- Keep the state model fully testable without Flutter widget tree or device dependencies

**Non-Goals:**
- Teaching loop logic (play/wait/repeat, input evaluation, feedback sequencing)
- Persistence — state lives in memory only, resets on app restart
- Analytics or progress tracking beyond the current letter
- Any UI rendering or touch input handling

## Decisions

### 1. StateNotifier + StateNotifierProvider over StateProvider or Notifier

**Choice**: Use `StateNotifier<SessionState>` with `StateNotifierProvider`.

**Why**: The session state is a compound object (letter index + phase) that changes together. `StateNotifier` groups mutations into named methods (`nextLetter`, `previousLetter`, `reset`, `setPhase`) which makes the API explicit and testable. `StateProvider` would require separate providers for each field, losing atomicity. The newer `Notifier` API (Riverpod 2.x) is viable but the existing codebase uses the classic API exclusively — consistency matters more than novelty here.

**Alternative considered**: Separate `StateProvider<int>` for letter index and `StateProvider<SessionPhase>` for phase. Rejected because navigation must update both atomically (change letter + reset phase to `playing`).

### 2. Immutable state class over mutable fields

**Choice**: `SessionState` is an immutable class with a `copyWith` method. The `StateNotifier` produces new instances on each mutation.

**Why**: Immutable state is idiomatic Riverpod. It makes equality checks trivial, prevents accidental mutation, and ensures `ref.watch` triggers correctly on changes.

### 3. Boundary clamping over wrapping

**Choice**: At letter A, `previousLetter` is a no-op. At letter Z, `nextLetter` is a no-op.

**Why**: The learning sequence is linear (A-Z). Wrapping from Z to A could confuse a deaf-blind user who has no visual cue about their position. Clamping is safer — doing nothing is better than unexpected behavior.

### 4. Navigation resets phase to `playing`

**Choice**: `nextLetter`, `previousLetter`, and `reset` all set phase to `SessionPhase.playing`.

**Why**: When you move to a new letter, the orchestrator should immediately start playing that letter's Morse pattern. Setting the phase during navigation avoids a two-step "navigate then explicitly set phase" dance, which would create a brief inconsistent state.

### 5. File organization: `app/lib/session/` directory

**Choice**: New `session/` directory alongside existing `morse/`, `gestures/`, `vibration/`.

**Why**: Follows the established pattern. Three files: state model, state notifier, providers — mirroring how `vibration/` has config, service, and providers.

## Risks / Trade-offs

**[Phase enum may evolve]** → The `playing`/`listening`/`feedback` phases are defined now but the orchestrator (Change 2) may need sub-states or additional phases. Mitigation: the enum is cheap to extend, and `StateNotifier.setPhase` accepts any `SessionPhase` value without transition validation.

**[No transition enforcement]** → The state notifier does not validate phase transitions (e.g., jumping from `feedback` to `listening` directly). This is intentional — the orchestrator owns transition logic. Risk: a bug in the orchestrator could set invalid states. Mitigation: unit tests on the orchestrator will cover valid sequences.

**[Letter index coupled to morseLetters list]** → The notifier indexes into `morseLetters` from the Morse data model. If that list changes (e.g., adding numbers), the session state automatically adapts. No risk for Phase 1 where the alphabet is fixed.
