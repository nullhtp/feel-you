## Context

The foundation and session state layers are complete. The gesture classifier (`app/lib/gestures/`) emits a stream of `GestureEvent` values (taps classified as dots/dashes, input completion, navigation, reset). The vibration engine (`app/lib/vibration/`) can play Morse patterns and success/error signals. The session state (`app/lib/session/`) tracks the current letter (A-Z position) and phase (`playing`/`listening`/`feedback`).

These components exist in isolation. Nothing connects them. The orchestrator is the missing piece: it subscribes to gesture events, drives the vibration engine, and manages session phase transitions to create the actual learning experience.

## Goals / Non-Goals

**Goals:**
- Connect gesture input, vibration output, and session state into a continuous learning loop
- Implement the play-wait-repeat cycle: vibrate current letter's pattern, pause 3 seconds, repeat until the user acts
- Evaluate user input against the current letter's Morse pattern
- Deliver correct/incorrect feedback through distinct vibration patterns
- Handle interrupts: cancel vibration when the user starts tapping
- Respond to navigation and reset events by changing letters and restarting the loop
- Drive session phase transitions (`playing` -> `listening` -> `feedback` -> `playing`)
- Make timing configurable for later device-specific tuning

**Non-Goals:**
- UI or touch capture (Change 3)
- Persistence or progress tracking
- Adaptive difficulty or spaced repetition
- Word/sentence-level teaching

## Decisions

### 1. StateNotifier for the orchestrator

**Choice**: Implement the orchestrator as a `StateNotifier` exposed via `StateNotifierProvider`, consistent with the session state pattern.

**Why**: The orchestrator has its own internal state (whether the loop is active, whether it's been interrupted) and needs to reactively consume the session state. `StateNotifier` integrates naturally with Riverpod's lifecycle — it can watch providers, subscribe to streams, and be auto-disposed. The existing codebase uses `StateNotifier` exclusively.

**Alternative considered**: A plain Dart class with explicit `start()`/`stop()` methods, injected via a simple `Provider`. Rejected because it breaks from the established Riverpod pattern and requires manual lifecycle management that Riverpod already handles.

### 2. Orchestrator state is minimal — loop running + interrupted flag

**Choice**: The orchestrator's own state is a simple value class with two fields: `isRunning` (bool) and `isInterrupted` (bool). All meaningful application state (current letter, phase) stays in `SessionNotifier`.

**Why**: The orchestrator is a coordinator, not a state store. Duplicating letter/phase in the orchestrator would create two sources of truth. The orchestrator reads session state when needed and writes to it through `SessionNotifier` methods.

### 3. `Vibration.cancel()` + state flag for interrupt handling

**Choice**: When the user starts tapping (first `MorseInput` arrives during `playing` phase), call `Vibration.cancel()` to stop the hardware, set `isInterrupted = true` to break the playback loop, and transition to `listening` phase.

**Why**: The `vibration` Flutter package supports `Vibration.cancel()` on both iOS and Android. Checking a flag between loop iterations is simple and avoids the complexity of breaking a pattern into individual symbol-level steps with cancellation points.

**Alternative considered**: Breaking `playMorsePattern` into per-symbol steps with interrupt checks between each. More precise cancellation but significantly more complex. Not justified for Phase 1 where patterns are short (1-4 symbols max).

### 4. Add `cancel()` to VibrationService abstract class

**Choice**: Extend the `VibrationService` interface with a `Future<void> cancel()` method. `DeviceVibrationService` implements it via `Vibration.cancel()`.

**Why**: The abstract class is the test seam. Tests need to verify that `cancel()` is called at the right time. Adding it to the abstract class keeps the mock/real implementations symmetric. The method is inherently tied to vibration lifecycle — it belongs on the service.

### 5. Configurable loop timing via `TeachingTimingConfig`

**Choice**: A new `TeachingTimingConfig` class with `repeatPause` (default: 3000ms) — the pause between pattern repetitions. Exposed via a Riverpod `Provider` for override.

**Why**: The 3-second pause is a reasonable default but may need tuning on real devices or for individual users. Following the same config-class pattern as `GestureTimingConfig` and `MorseTimingConfig`.

### 6. Async loop with cancellation via Completer

**Choice**: The play-repeat loop runs as an async method using `Future.delayed` for the pause. A `Completer` is used as a cancellation signal — completing it interrupts the delay early.

**Why**: Dart's async/await is the natural tool for sequential operations (vibrate, wait, check flag, repeat). A `Completer` allows the navigation and interrupt handlers to break the loop without polling. This avoids `Timer`-based state machines, keeping the flow readable as straight-line code.

**Alternative considered**: A `Timer.periodic` approach. Rejected because the loop timing is variable (pattern duration depends on the letter) and the sequential nature of vibrate-then-pause maps better to async/await.

### 7. File organization: `app/lib/teaching/` directory

**Choice**: New `teaching/` directory with: `teaching_timing_config.dart`, `teaching_orchestrator.dart`, `teaching_providers.dart`.

**Why**: Follows the established pattern (`morse/`, `gestures/`, `vibration/`, `session/`). Each domain concept gets its own directory.

### 8. Gesture stream subscription lifecycle

**Choice**: The orchestrator subscribes to the gesture classifier's event stream in its constructor and cancels the subscription on dispose.

**Why**: The orchestrator must react to gesture events for its entire lifetime. Riverpod's `ref.onDispose` ensures cleanup. The subscription processes events by type: `MorseInput` triggers interrupt, `InputComplete` triggers evaluation, `NavigateNext`/`NavigatePrevious`/`Reset` trigger navigation.

## Risks / Trade-offs

**[Vibration.cancel() timing is platform-dependent]** → On some devices, `Vibration.cancel()` may not immediately stop a pattern in progress. Mitigation: for Phase 1 with short patterns (max ~1.1s for Q: dash-dash-dot-dash), the worst case is the user feels the end of the current pattern before silence. Acceptable.

**[No backpressure on gesture events during feedback]** → If the user taps rapidly during the feedback phase, events accumulate. Mitigation: the orchestrator ignores `MorseInput` and `InputComplete` events when not in `playing` or `listening` phase. Navigation events are always processed regardless of phase.

**[Async loop could race with navigation]** → If a navigation event arrives mid-vibration, the loop must stop cleanly and restart for the new letter. Mitigation: completing the cancellation `Completer` breaks any pending delay, and the `isInterrupted` flag stops the loop from continuing. The navigation handler then starts a fresh loop.

**[No retry limit]** → The loop repeats indefinitely with no hint escalation. The user could be stuck on a letter. This is intentional for Phase 1 — the design philosophy is "patient instrument, not impatient teacher." Future phases could add progressive hints.
