## Context

The Feel You codebase is well-structured across five modules (`morse/`, `gestures/`, `session/`, `vibration/`, `teaching/`) with comprehensive test coverage. However, organic growth has introduced DRY violations, mixed-concern files, and manual boilerplate that should be addressed before Phase 2 work begins.

Key issues:
- Duplicate `_listEquals` implementations in `gesture_event.dart` and `vibration_service.dart` when `listEquals` from `package:flutter/foundation.dart` is already used in `morse_utils.dart`.
- Five separate `MockVibrationService` test doubles and three `GestureClassifier` test doubles across test files.
- `vibration_service.dart` contains five distinct concerns (pure function, data class, constants, interface, implementation).
- Manual `==`, `hashCode`, `toString` boilerplate on all value classes.
- Hardcoded 500ms post-feedback delay used twice in `teaching_orchestrator.dart`.
- Near-identical `_handleCorrectAnswer` and `_handleWrongAnswer` methods.
- Dead `tuning_reference.dart` never imported anywhere.
- No barrel exports for any module.

## Goals / Non-Goals

**Goals:**
- Eliminate all identified DRY violations in production and test code.
- Apply Single Responsibility Principle by splitting `vibration_service.dart` into focused files.
- Reduce value-class boilerplate using the `equatable` package.
- Add barrel exports for cleaner import statements.
- Remove dead code (`tuning_reference.dart`).
- Maintain 100% behavioral compatibility — all existing tests must pass unchanged.

**Non-Goals:**
- No architecture changes (module boundaries, Riverpod provider structure, stream-based event flow remain as-is).
- No new features or capabilities.
- No adoption of `freezed` or `build_runner`.
- No refactoring of `TeachingOrchestrator` beyond the feedback handler consolidation — its complexity is inherent.
- No changes to the `morse/` data model (already clean).

## Decisions

### 1. Use `equatable` for value class boilerplate

**Decision**: Add the `equatable` package and extend `Equatable` for `GestureEvent` subtypes, `SessionState`, `TeachingOrchestratorState`, and `SignalPattern`.

**Rationale**: Equatable eliminates manual `==` and `hashCode` with a simple `props` getter. It's lightweight (no codegen), widely adopted in the Flutter ecosystem, and sufficient for our needs. `toString` can optionally be auto-generated via `stringify`.

**Alternatives considered**:
- **Freezed**: More powerful (generates `copyWith`, JSON serialization, union types) but requires `build_runner` and generates `.freezed.dart` files. Overkill for this project's simple value classes.
- **Manual cleanup**: Keep manual implementations but simplify. Doesn't reduce code or prevent drift.

**Impact on sealed classes**: `GestureEvent` is a sealed class with subtypes. Each subtype will extend `Equatable` via the sealed base class. The singleton-like subtypes (`NavigateNext`, `NavigatePrevious`, `Reset`) with no fields will have empty `props` lists, giving them identity-based equality, which is correct since they use `const` constructors.

### 2. Split `vibration_service.dart` into four files

**Decision**: Break the 168-line file into:
- `morse_vibration_pattern.dart` — the `buildMorseVibrationPattern()` pure function
- `signal_pattern.dart` — `SignalPattern` class + `successSignal`/`errorSignal` constants
- `vibration_service.dart` — `VibrationService` abstract interface only
- `device_vibration_service.dart` — `DeviceVibrationService` implementation

**Rationale**: Each file has a single responsibility. The pure function, data class, interface, and implementation are independent concerns that change for different reasons.

**Alternatives considered**:
- **Keep as-is**: 168 lines is not egregious, but the file mixes four distinct abstractions. Splitting now prevents further growth.
- **Two files (interface + implementation)**: Still leaves the pure function and data class mixed in with the interface.

### 3. Consolidate test doubles into `test/test_doubles/`

**Decision**: Create shared test doubles:
- `test/test_doubles/mock_vibration_service.dart` — a single recording mock that covers all test needs
- `test/test_doubles/fake_gesture_classifier.dart` — a single controllable fake

**Rationale**: Five mock vibration services and three gesture classifier fakes share 80%+ of their code. A shared implementation eliminates duplication and ensures test infrastructure evolves consistently.

**Design for `MockVibrationService`**: Use the `RecordingVibrationService` pattern from integration tests (records typed `VibrationCall` objects) as the canonical implementation. It's the most capable existing variant. Add convenience getters like `callLog` (list of string names) for tests that only check call order.

**Design for `FakeGestureClassifier`**: Expose a `StreamController<GestureEvent>` for test control, plus a recording list for raw touch events (for touch_surface tests that verify event forwarding).

### 4. Extract hardcoded 500ms into `TeachingTimingConfig`

**Decision**: Add a `postFeedbackPause` field to `TeachingTimingConfig` with a default of `Duration(milliseconds: 500)`.

**Rationale**: This value appears twice in `_handleCorrectAnswer` and `_handleWrongAnswer`. Making it configurable follows the existing pattern where all timing values live in config classes and can be overridden via Riverpod providers.

### 5. Merge `_handleCorrectAnswer` and `_handleWrongAnswer`

**Decision**: Extract a shared `_handleFeedback(Future<void> Function() playFeedback)` method. The two methods differ only in calling `playSuccess()` vs `playError()`.

**Rationale**: The guard checks, delay, loop resumption, and state transitions are identical. A single method with a callback parameter eliminates the duplication while remaining clear.

### 6. Replace `_listEquals` with `listEquals` from Flutter foundation

**Decision**: Use `listEquals` from `package:flutter/foundation.dart` in both `gesture_event.dart` and `vibration_service.dart`, removing both private implementations.

**Rationale**: `morse_utils.dart` already imports and uses this function. Using the same standard library function everywhere eliminates duplication and leverages a well-tested implementation.

### 7. Barrel export structure

**Decision**: Create one barrel file per module at the module root (e.g., `lib/morse/morse.dart`). Each barrel re-exports all public files in that module.

**Rationale**: Simplifies imports from `import 'package:feel_you/morse/morse_symbol.dart'; import 'package:feel_you/morse/morse_alphabet.dart'; import 'package:feel_you/morse/morse_utils.dart';` to a single `import 'package:feel_you/morse/morse.dart';`.

Barrel files to create:
- `lib/morse/morse.dart`
- `lib/gestures/gestures.dart`
- `lib/session/session.dart`
- `lib/vibration/vibration.dart`
- `lib/teaching/teaching.dart`

### 8. Delete `tuning_reference.dart`

**Decision**: Remove `lib/tuning/tuning_reference.dart` and the `tuning/` directory entirely.

**Rationale**: The file is never imported by any production code or test. It duplicates default values already present in the actual config classes (`MorseTimingConfig`, `GestureTimingConfig`, `TeachingTimingConfig`). Keeping it risks staleness and confusion.

## Risks / Trade-offs

- **[Risk] Equatable changes `toString` behavior** → Mitigation: Override `toString` explicitly on classes where the current format is important for debugging (e.g., `SessionState.toString()` shows `letter:` not `letterIndex:`). Use `stringify = false` on Equatable and keep manual `toString` where needed.
- **[Risk] Barrel exports could cause circular imports** → Mitigation: Each module's barrel only exports its own files. The existing dependency graph (morse ← gestures/session/vibration ← teaching ← ui) has no cycles. Verify with `dart analyze` after changes.
- **[Risk] Test double consolidation could miss variant-specific behavior** → Mitigation: Review each existing mock carefully before consolidation. The canonical mock should be a superset of all existing capabilities.
- **[Risk] Splitting vibration files changes import paths** → Mitigation: Barrel export `lib/vibration/vibration.dart` re-exports everything, so most imports can use the barrel. Update remaining direct imports in the same PR.
