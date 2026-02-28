## Why

The codebase has accumulated several DRY violations, mixed-concern files, and manual boilerplate that increase maintenance burden and risk of inconsistency. Addressing these now — while the project is small — prevents these issues from compounding as Phase 2 features are added.

## What Changes

- **Eliminate duplicated code**: Remove duplicate `_listEquals` implementations (use `listEquals` from Flutter foundation everywhere), merge near-identical `_handleCorrectAnswer`/`_handleWrongAnswer` into a shared feedback handler, extract hardcoded 500ms post-feedback delay into `TeachingTimingConfig`.
- **Consolidate test doubles**: Extract 5 duplicate `MockVibrationService` implementations and 3 duplicate `GestureClassifier` test doubles into shared test helpers under `test/test_doubles/`.
- **Split mixed-concern file**: Break `vibration_service.dart` (currently containing a pure function, a data class, signal constants, an abstract interface, and a concrete implementation) into focused single-responsibility files.
- **Reduce value-class boilerplate**: Adopt the `equatable` package for `GestureEvent` subtypes, `SessionState`, and `TeachingOrchestratorState` to eliminate manual `==`, `hashCode`, and `toString` implementations.
- **Add barrel exports**: Create index files for each module (`morse/`, `gestures/`, `session/`, `vibration/`, `teaching/`) to simplify imports.
- **Remove dead code**: Delete `tuning_reference.dart` which is never imported and duplicates config defaults.

## Non-goals

- No behavioral changes — all existing tests must continue to pass with identical semantics.
- No new features or capabilities.
- No architecture changes (module boundaries, provider structure, and stream-based event flow remain the same).
- No adoption of `freezed` or `build_runner` — using the lighter `equatable` package instead.

## Capabilities

### New Capabilities

_None — this is a pure refactoring with no new capabilities._

### Modified Capabilities

_None — no spec-level requirements are changing. All changes are implementation-level only._

## Impact

- **Production code**: `gestures/`, `vibration/`, `session/`, `teaching/` modules will have files restructured and boilerplate reduced. All public APIs remain identical.
- **Test code**: Test files will be updated to import shared test doubles instead of defining their own. Test behavior is unchanged.
- **Dependencies**: `equatable` package added to `pubspec.yaml`.
- **Dead code**: `tuning/tuning_reference.dart` removed.
- **Imports**: All import paths updated to use barrel exports.
