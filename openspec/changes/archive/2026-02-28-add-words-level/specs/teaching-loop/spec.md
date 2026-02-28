## MODIFIED Requirements

### Requirement: Evaluate user input on InputComplete
The orchestrator SHALL compare the user's input pattern (from `InputComplete`) against the current character's (or word's) expected Morse pattern using `patternsEqual`. The input pattern MAY include `charGap` symbols when the user pauses between letters within a word. The result determines the feedback path.

#### Scenario: Correct input matches current letter
- **WHEN** the current character is "S" (dot-dot-dot)
- **AND** the user taps `[dot, dot, dot]` and `InputComplete` fires
- **THEN** `patternsEqual` returns true
- **AND** the orchestrator enters the correct-answer feedback path

#### Scenario: Incorrect input does not match
- **WHEN** the current character is "S" (dot-dot-dot)
- **AND** the user taps `[dot, dash]` and `InputComplete` fires
- **THEN** `patternsEqual` returns false
- **AND** the orchestrator enters the wrong-answer feedback path

#### Scenario: Empty input is treated as incorrect
- **WHEN** `InputComplete` fires with an empty symbol list
- **THEN** the orchestrator enters the wrong-answer feedback path

#### Scenario: Correct word input with charGaps
- **WHEN** the current word is "IT" with pattern `[dot, dot, charGap, dash]`
- **AND** the user taps `[dot, dot, charGap, dash]` and `InputComplete` fires
- **THEN** `patternsEqual` returns true
- **AND** the orchestrator enters the correct-answer feedback path

#### Scenario: Word input missing charGap is incorrect
- **WHEN** the current word is "IT" with pattern `[dot, dot, charGap, dash]`
- **AND** the user taps `[dot, dot, dash]` (no charGap) and `InputComplete` fires
- **THEN** `patternsEqual` returns false
- **AND** the orchestrator enters the wrong-answer feedback path

## ADDED Requirements

### Requirement: Gesture classifier emits charGap symbols for inter-character silence
The `GestureClassifier` SHALL emit `charGap` symbols in the input sequence when a silence between taps exceeds the `charGapThreshold` but is less than the `silenceTimeout`. This allows users to input multi-character word patterns with explicit character boundaries.

#### Scenario: Short silence is inter-symbol gap (no charGap emitted)
- **WHEN** the user taps twice with a silence shorter than `charGapThreshold` (default 400ms)
- **THEN** no `charGap` symbol is inserted between the taps in the input sequence

#### Scenario: Medium silence produces charGap
- **WHEN** the user taps, waits longer than `charGapThreshold` but less than `silenceTimeout`, then taps again
- **THEN** a `charGap` symbol SHALL be inserted between the two taps in the input sequence

#### Scenario: Long silence triggers InputComplete
- **WHEN** the user taps, then waits longer than `silenceTimeout` (default 1000ms)
- **THEN** an `InputComplete` event SHALL fire (no charGap — the sequence ends)

### Requirement: Configurable charGap threshold
The `GestureTimingConfig` SHALL include a `charGapThreshold` parameter (default: 400ms) that defines the minimum silence duration to classify as an inter-character gap during input.

#### Scenario: Default charGapThreshold
- **WHEN** a `GestureTimingConfig` is created with no arguments
- **THEN** `charGapThreshold` SHALL be 400ms

#### Scenario: Custom charGapThreshold
- **WHEN** a `GestureTimingConfig` is created with `charGapThreshold: 500`
- **THEN** the charGap threshold SHALL be 500ms
