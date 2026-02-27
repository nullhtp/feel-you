## Why

The foundation layer (Morse data, gesture recognition, vibration engine) is complete, but there is no state to track the user's learning session. Without session state, there is nothing to tell the app which letter the user is learning, what phase of the teaching loop they are in, or how to respond to navigation gestures. This is the first piece needed before the teaching loop orchestrator (Change 2) can be built.

## What Changes

- Add a session state model with the current letter index (A-Z position) and session phase (`playing`, `listening`, `feedback`)
- Add navigation logic: advance to next letter, go to previous letter, reset to A — all clamped at boundaries (A and Z)
- Add Riverpod providers (StateNotifier + StateNotifierProvider) exposing session state to the rest of the app
- Navigation and reset automatically set the phase back to `playing`
- In-memory only — no persistence, no serialization

## Non-goals

- Teaching loop logic (play-wait-repeat, input evaluation, feedback) — that is Change 2
- Touch UI / gesture capture widget — that is Change 3
- Persistence or saving progress across app restarts
- Any visual or auditory UI elements

## Capabilities

### New Capabilities

- `learning-session`: State machine tracking the user's position in the A-Z learning sequence and the current session phase (playing/listening/feedback). Includes navigation (next/previous/reset) and Riverpod state management.

### Modified Capabilities

_(none — no existing spec requirements change)_

## Impact

- **New code**: `app/lib/session/` directory with state model, state notifier, and providers
- **New tests**: `app/test/session/` with unit tests for state transitions and navigation
- **Dependencies**: No new packages — uses existing `flutter_riverpod`
- **Existing code**: No modifications to existing morse, gesture, or vibration code
