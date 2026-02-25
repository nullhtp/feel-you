## Why

The app currently has only an empty scaffold — no feature code. To build the Phase 1 Morse learning experience, we need three foundational capabilities: a Morse code data model, a vibration engine that can play patterns through haptics, and a gesture recognition system that interprets touch input as Morse symbols and navigation commands. These are the building blocks everything else depends on — the "patient teacher" loop, letter navigation, and input evaluation all require these primitives to exist first.

## What Changes

- Add a Morse code data model mapping A-Z to dot/dash sequences, with encoding/decoding utilities
- Add a vibration engine that plays Morse patterns (dot: 100ms, dash: 300ms) and signal vibrations (success: 3 quick pulses, error: one long buzz) using the `vibration` package
- Add a gesture recognition system that classifies touch input into Morse symbols (dot <150ms, dash 150-500ms), navigation (swipe left/right), and reset (long hold >2000ms)
- Add a silence-timeout mechanism (1-1.5s) to detect when the user has finished entering a Morse character
- All timing thresholds are configurable, not hardcoded
- Swipe detection includes velocity/distance thresholds to prevent accidental triggers
- Expose all capabilities through Riverpod providers for downstream consumption

## Non-goals

- **No learning loop / teacher behavior.** This change builds primitives only — the orchestration that ties them together (play pattern, wait, evaluate, respond) is a separate change.
- **No UI.** No screens, no widgets beyond what's needed for gesture detection on the existing scaffold.
- **No letter navigation state.** Tracking which letter the user is on belongs to the learning state change.
- **No persistence.** Nothing is saved between sessions.
- **No future phases.** Words, sentences, speech-to-Morse, etc. are out of scope.

## Capabilities

### New Capabilities
- `morse-data`: Morse code alphabet data model — A-Z to dot/dash pattern mapping, encoding, decoding, and validation utilities
- `vibration-engine`: Haptic feedback engine — plays Morse patterns and signal vibrations (success/error) through phone vibration with configurable timing
- `gesture-recognition`: Touch gesture classification — interprets raw touch events as Morse input (dot/dash), navigation (swipe left/right), and reset (long hold), with configurable timing thresholds and silence-timeout for input completion detection

### Modified Capabilities

_None — no existing capability requirements are changing._

## Impact

- **Dependencies:** Adds `vibration` package to `app/pubspec.yaml`
- **Code:** New files in `app/lib/morse/`, `app/lib/vibration/`, `app/lib/gestures/` (or similar structure)
- **Providers:** New Riverpod providers for vibration service and gesture input stream
- **Platforms:** Vibration requires platform permissions — `VIBRATE` on Android (already default), no special permission on iOS but uses `AudioServicesPlaySystemSound` or `CoreHaptics` under the hood via the package
- **Tests:** Unit tests for Morse data model, vibration pattern generation, and gesture classification logic
