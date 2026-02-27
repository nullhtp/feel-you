## Why

The foundation components exist in isolation: the gesture classifier emits events, the vibration engine plays patterns, and the session state tracks the current letter and phase. But nothing connects them. Without an orchestrator, the app cannot teach — it has parts but no behavior. The teaching loop is the core learning experience: it makes the phone "speak" a letter, "listen" for the user's attempt, and "respond" with feedback, continuously and patiently.

## What Changes

- Add a teaching loop orchestrator that drives the entire learning interaction
- Implement a play-wait-repeat cycle: vibrate the current letter's Morse pattern, pause 3 seconds, repeat — infinitely until the user acts
- Evaluate user input: when `InputComplete` fires, compare the tapped pattern against the current letter using `patternsEqual`
- Deliver feedback: correct answer triggers success vibration (`3 short pulses`), then resumes the repeat loop; wrong answer triggers error vibration (`long buzz`), replays the correct pattern, then resumes the repeat loop
- Handle interrupts: cancel ongoing vibration playback when the user starts tapping (`MorseInput`), resume the loop after feedback completes
- Integrate navigation: respond to `NavigateNext`, `NavigatePrevious`, and `Reset` gesture events by updating the session state and restarting the loop for the new letter
- Drive session phase transitions (`playing` -> `listening` -> `feedback` -> `playing`) through the orchestrator
- Add `cancel()` capability to the vibration service to support interrupt handling
- Make loop timing configurable (repeat pause duration, etc.)

## Non-goals

- No UI changes — the touch layer (Change 3) will connect to this orchestrator later
- No persistence — session state remains in-memory only
- No analytics or progress tracking beyond current letter position
- No adaptive difficulty or spaced repetition logic
- No word/sentence-level teaching (Phase 1 is letter-by-letter only)

## Capabilities

### New Capabilities
- `teaching-loop`: The orchestrator that connects gesture input, vibration output, and session state into a continuous learn-by-repetition loop. Manages the play-wait-repeat cycle, input evaluation, feedback delivery, interrupt handling, and navigation response.

### Modified Capabilities
- `vibration-engine`: Adding a `cancel()` method to `VibrationService` to support interrupting ongoing vibration playback when the user starts tapping.

## Impact

- **New code**: `app/lib/teaching/` — orchestrator notifier, timing config, and Riverpod providers
- **Modified code**: `app/lib/vibration/vibration_service.dart` — add `cancel()` to the abstract class and `DeviceVibrationService` implementation
- **Dependencies**: Consumes `gestureClassifierProvider`, `vibrationServiceProvider`, `sessionNotifierProvider` — all already exist
- **Tests**: New unit tests for the orchestrator covering the play-repeat loop, input evaluation, feedback flow, interrupt handling, and navigation integration
