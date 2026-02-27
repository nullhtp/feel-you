## ADDED Requirements

### Requirement: Play-wait-repeat loop vibrates current letter continuously

The orchestrator SHALL continuously vibrate the current letter's Morse pattern followed by a configurable pause (default: 3000ms), repeating indefinitely until the user provides input or navigates. The pattern SHALL be looked up from the Morse alphabet using the current letter from the session state.

#### Scenario: Loop starts on orchestrator activation

- **WHEN** the orchestrator is started and the session phase is `playing`
- **THEN** the vibration engine plays the current letter's Morse pattern
- **AND** after the pattern completes, waits 3000ms
- **AND** replays the pattern, repeating this cycle indefinitely

#### Scenario: Loop uses correct pattern for current letter

- **WHEN** the current letter is "A" (dot-dash)
- **THEN** the orchestrator plays `[dot, dash]` via the vibration service on each repetition

#### Scenario: Loop respects configurable pause duration

- **WHEN** the repeat pause is configured to 5000ms
- **THEN** the orchestrator waits 5000ms between pattern repetitions instead of the default 3000ms

### Requirement: Interrupt playback when user starts tapping

The orchestrator SHALL stop ongoing vibration playback when the first `MorseInput` event is received during the `playing` phase. The session phase SHALL transition to `listening` and the repeat loop SHALL pause until input evaluation completes.

#### Scenario: First tap interrupts playback

- **WHEN** the orchestrator is playing the current letter's pattern
- **AND** the user taps (producing a `MorseInput` event)
- **THEN** the vibration service `cancel()` is called
- **AND** the session phase transitions to `listening`
- **AND** the repeat loop stops

#### Scenario: Subsequent taps during listening do not trigger additional interrupts

- **WHEN** the session phase is already `listening`
- **AND** the user continues tapping (additional `MorseInput` events)
- **THEN** no additional `cancel()` calls are made
- **AND** the orchestrator waits for `InputComplete`

### Requirement: Evaluate user input on InputComplete

The orchestrator SHALL compare the user's input pattern (from `InputComplete`) against the current letter's expected Morse pattern using `patternsEqual`. The result determines the feedback path.

#### Scenario: Correct input matches current letter

- **WHEN** the current letter is "S" (dot-dot-dot)
- **AND** the user taps `[dot, dot, dot]` and `InputComplete` fires
- **THEN** `patternsEqual` returns true
- **AND** the orchestrator enters the correct-answer feedback path

#### Scenario: Incorrect input does not match

- **WHEN** the current letter is "S" (dot-dot-dot)
- **AND** the user taps `[dot, dash]` and `InputComplete` fires
- **THEN** `patternsEqual` returns false
- **AND** the orchestrator enters the wrong-answer feedback path

#### Scenario: Empty input is treated as incorrect

- **WHEN** `InputComplete` fires with an empty symbol list
- **THEN** the orchestrator enters the wrong-answer feedback path

### Requirement: Correct answer plays success vibration and resumes loop

On a correct answer, the orchestrator SHALL transition the session phase to `feedback`, play the success vibration signal, then transition back to `playing` and resume the repeat loop.

#### Scenario: Correct answer feedback sequence

- **WHEN** the user's input matches the current letter
- **THEN** the session phase transitions to `feedback`
- **AND** the vibration service plays the success signal (3 quick pulses)
- **AND** after the success signal completes, the session phase transitions to `playing`
- **AND** the repeat loop resumes from the beginning of a cycle

### Requirement: Wrong answer plays error vibration, replays pattern, and resumes loop

On a wrong answer, the orchestrator SHALL transition the session phase to `feedback`, play the error vibration signal, then replay the correct Morse pattern for the current letter, then transition back to `playing` and resume the repeat loop.

#### Scenario: Wrong answer feedback sequence

- **WHEN** the user's input does not match the current letter
- **THEN** the session phase transitions to `feedback`
- **AND** the vibration service plays the error signal (long buzz)
- **AND** then the vibration service plays the current letter's correct Morse pattern
- **AND** after both complete, the session phase transitions to `playing`
- **AND** the repeat loop resumes from the beginning of a cycle

### Requirement: Navigation events update letter and restart loop

The orchestrator SHALL respond to `NavigateNext`, `NavigatePrevious`, and `Reset` gesture events by calling the corresponding method on `SessionNotifier` and restarting the play-wait-repeat loop for the new letter.

#### Scenario: NavigateNext advances to next letter

- **WHEN** a `NavigateNext` gesture event is received
- **THEN** `sessionNotifier.nextLetter()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the new letter

#### Scenario: NavigatePrevious goes to previous letter

- **WHEN** a `NavigatePrevious` gesture event is received
- **THEN** `sessionNotifier.previousLetter()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the new letter

#### Scenario: Reset returns to letter A

- **WHEN** a `Reset` gesture event is received
- **THEN** `sessionNotifier.reset()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for letter A

#### Scenario: Navigation during feedback interrupts feedback

- **WHEN** the session phase is `feedback` (success or error vibration playing)
- **AND** a navigation event is received
- **THEN** the feedback vibration is cancelled
- **AND** the orchestrator navigates to the new letter and restarts the loop

### Requirement: Gesture events are ignored when not applicable

The orchestrator SHALL ignore `MorseInput` and `InputComplete` events when the session phase is `feedback`. Navigation events (`NavigateNext`, `NavigatePrevious`, `Reset`) SHALL be processed in any phase.

#### Scenario: Taps during feedback are ignored

- **WHEN** the session phase is `feedback`
- **AND** a `MorseInput` or `InputComplete` event is received
- **THEN** the event is discarded with no effect

#### Scenario: Navigation works during any phase

- **WHEN** the session phase is `playing`, `listening`, or `feedback`
- **AND** a `NavigateNext` event is received
- **THEN** the navigation is processed normally

### Requirement: Configurable teaching loop timing

The orchestrator SHALL use a `TeachingTimingConfig` configuration object with a `repeatPause` duration (default: 3000ms). The config SHALL be overridable via a Riverpod provider.

#### Scenario: Default repeat pause

- **WHEN** a `TeachingTimingConfig` is created with no arguments
- **THEN** the repeat pause is 3000ms

#### Scenario: Custom repeat pause

- **WHEN** a `TeachingTimingConfig` is created with `repeatPause: Duration(milliseconds: 5000)`
- **THEN** the repeat pause is 5000ms

### Requirement: Orchestrator is exposed via Riverpod provider

The teaching loop orchestrator SHALL be exposed as a `StateNotifierProvider`. It SHALL depend on the gesture classifier, vibration service, and session notifier providers. It SHALL clean up stream subscriptions and cancel any running loops on dispose.

#### Scenario: Provider creates orchestrator with dependencies

- **WHEN** the orchestrator provider is read
- **THEN** it receives the gesture classifier, vibration service, and session notifier from their respective providers

#### Scenario: Provider cleans up on dispose

- **WHEN** the orchestrator provider is disposed
- **THEN** the gesture stream subscription is cancelled
- **AND** any running vibration is cancelled
- **AND** the repeat loop is stopped

### Requirement: Orchestrator can be started and stopped

The orchestrator SHALL provide `start()` and `stop()` methods. `start()` begins the play-wait-repeat loop. `stop()` cancels any running loop and vibration. The orchestrator SHALL not auto-start on creation — it waits for an explicit `start()` call.

#### Scenario: Start begins the loop

- **WHEN** `start()` is called on the orchestrator
- **THEN** the play-wait-repeat loop begins for the current letter

#### Scenario: Stop halts the loop

- **WHEN** `stop()` is called while the loop is running
- **THEN** vibration is cancelled
- **AND** the loop stops
- **AND** no further vibrations occur until `start()` is called again

#### Scenario: Orchestrator does not auto-start

- **WHEN** the orchestrator is created via its provider
- **THEN** no vibration occurs until `start()` is explicitly called
