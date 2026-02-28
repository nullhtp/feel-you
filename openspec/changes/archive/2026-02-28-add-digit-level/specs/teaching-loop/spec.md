## MODIFIED Requirements

### Requirement: Play-wait-repeat loop vibrates current letter continuously

The orchestrator SHALL continuously vibrate the current character's Morse pattern followed by a configurable pause (default: 3000ms), repeating indefinitely until the user provides input or navigates. The pattern SHALL be looked up from the current level's pattern data using the current character from the session state.

#### Scenario: Loop starts on orchestrator activation

- **WHEN** the orchestrator is started and the session phase is `playing`
- **THEN** the vibration engine plays the current character's Morse pattern
- **AND** after the pattern completes, waits 3000ms
- **AND** replays the pattern, repeating this cycle indefinitely

#### Scenario: Loop uses correct pattern for current character

- **WHEN** the current level is digits and position is 0 (character "0", pattern dash-dash-dash-dash-dash)
- **THEN** the orchestrator plays `[dash, dash, dash, dash, dash]` via the vibration service on each repetition

#### Scenario: Loop uses letter pattern when on letters level

- **WHEN** the current level is letters and position is 0 (character "A", pattern dot-dash)
- **THEN** the orchestrator plays `[dot, dash]` via the vibration service on each repetition

### Requirement: Navigation events update letter and restart loop

The orchestrator SHALL respond to `NavigateNext`, `NavigatePrevious`, and `Reset` gesture events by calling the corresponding method on `SessionNotifier` and restarting the play-wait-repeat loop for the new character. The orchestrator SHALL also respond to `NavigateUp`, `NavigateDown`, and `Home` gesture events by calling the corresponding level navigation method on `SessionNotifier` and restarting the loop for the new level's character.

#### Scenario: NavigateNext advances to next character

- **WHEN** a `NavigateNext` gesture event is received
- **THEN** `sessionNotifier.nextPosition()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the new character

#### Scenario: NavigatePrevious goes to previous character

- **WHEN** a `NavigatePrevious` gesture event is received
- **THEN** `sessionNotifier.previousPosition()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the new character

#### Scenario: Reset returns to first character in current level

- **WHEN** a `Reset` gesture event is received
- **THEN** `sessionNotifier.reset()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the first character in the current level

#### Scenario: NavigateUp moves to next level

- **WHEN** a `NavigateUp` gesture event is received
- **THEN** `sessionNotifier.nextLevel()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the first character of the new level

#### Scenario: NavigateDown moves to previous level

- **WHEN** a `NavigateDown` gesture event is received
- **THEN** `sessionNotifier.previousLevel()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for the first character of the new level

#### Scenario: Home resets to first level, first character

- **WHEN** a `Home` gesture event is received
- **THEN** `sessionNotifier.home()` is called
- **AND** any ongoing vibration is cancelled
- **AND** the repeat loop restarts for digit "0"

#### Scenario: Navigation during feedback interrupts feedback

- **WHEN** the session phase is `feedback` (success or error vibration playing)
- **AND** a navigation event is received (any of the six navigation types)
- **THEN** the feedback vibration is cancelled
- **AND** the orchestrator navigates and restarts the loop

### Requirement: Gesture events are ignored when not applicable

The orchestrator SHALL ignore `MorseInput` and `InputComplete` events when the session phase is `feedback`. Navigation events (`NavigateNext`, `NavigatePrevious`, `Reset`, `NavigateUp`, `NavigateDown`, `Home`) SHALL be processed in any phase.

#### Scenario: Taps during feedback are ignored

- **WHEN** the session phase is `feedback`
- **AND** a `MorseInput` or `InputComplete` event is received
- **THEN** the event is discarded with no effect

#### Scenario: Navigation works during any phase

- **WHEN** the session phase is `playing`, `listening`, or `feedback`
- **AND** a `NavigateUp` event is received
- **THEN** the navigation is processed normally

## ADDED Requirements

### Requirement: Orchestrator subscribes to both touch and shake event streams

The orchestrator SHALL subscribe to both the `GestureClassifier.events` stream (touch gestures) and the `ShakeDetector.events` stream (shake gestures). Events from both streams SHALL be handled identically through the same event processing logic.

#### Scenario: Touch gesture events are processed

- **WHEN** the `GestureClassifier` emits a `NavigateNext` event
- **THEN** the orchestrator processes it as a navigation event

#### Scenario: Shake gesture events are processed

- **WHEN** the `ShakeDetector` emits a `Home` event
- **THEN** the orchestrator processes it as a home navigation event

#### Scenario: Both subscriptions are cleaned up on dispose

- **WHEN** the orchestrator is disposed
- **THEN** both the touch gesture subscription and the shake gesture subscription SHALL be cancelled

### Requirement: Character pattern resolution uses level system

The orchestrator SHALL resolve the current character's Morse pattern through the level system (via `SessionState.currentLevel` and position) rather than directly from `morseLetters`. This ensures the correct pattern is used regardless of which level is active.

#### Scenario: Pattern resolved from digits level

- **WHEN** the current level is digits and position is 5
- **THEN** the orchestrator looks up the pattern for "5" from the digits level's patterns map

#### Scenario: Pattern resolved from letters level

- **WHEN** the current level is letters and position is 0
- **THEN** the orchestrator looks up the pattern for "A" from the letters level's patterns map
