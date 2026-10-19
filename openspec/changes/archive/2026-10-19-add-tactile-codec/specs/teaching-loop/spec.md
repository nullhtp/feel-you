## MODIFIED Requirements

### Requirement: Play-wait-repeat loop vibrates current letter continuously

The orchestrator SHALL continuously vibrate the current character's Morse pattern followed by a configurable pause (default: 3000ms), repeating indefinitely until the user provides input or navigates. The pattern SHALL be the current character from the session state, encoded with the session language's codec.

#### Scenario: Loop starts on orchestrator activation

- **WHEN** the orchestrator is started and the session phase is `playing`
- **THEN** the vibration engine plays the current character's Morse pattern
- **AND** after the pattern completes, waits 3000ms
- **AND** replays the pattern, repeating this cycle indefinitely

#### Scenario: Loop uses correct pattern for current character

- **WHEN** the current level is digits and position is 0 (character "0", pattern dash-dash-dash-dash-dash)
- **THEN** the orchestrator plays `[dash, dash, dash, dash, dash]` (five long pulses) via the vibration service on each repetition

#### Scenario: Loop uses letter pattern when on letters level

- **WHEN** the current level is letters and position is 0 (character "A", pattern dot-dash)
- **THEN** the orchestrator plays `[dot, dash]` (a short and a long pulse) via the vibration service on each repetition

### Requirement: Character pattern resolution uses level system

The orchestrator SHALL resolve the current item through the level system (via `SessionState.currentLevel` and position, or the quiz item) rather than directly from `morseLetters`, and SHALL obtain what it plays by encoding that item, a letter of a spelled word, or the quiz marker `?` with the session language's codec. Answers SHALL still be checked against the level's patterns.

#### Scenario: Pattern resolved from digits level

- **WHEN** the current level is digits and position is 5
- **THEN** the orchestrator encodes "5" with the session language's codec
- **AND** plays five short pulses

#### Scenario: Pattern resolved from letters level

- **WHEN** the current level is letters and position is 0
- **THEN** the orchestrator encodes "A" with the session language's codec
- **AND** plays a short and a long pulse

#### Scenario: Word encoded with letter gaps

- **WHEN** the current level is the English words level and the word "HI" is drilled
- **THEN** the orchestrator plays four short pulses, a character gap and two short pulses

#### Scenario: Spelling splits the encoded word

- **WHEN** the orchestrator spells the word "HI"
- **THEN** it plays the tokens of the encoded word up to its first character gap ("H"), then the tokens after it ("I"), each on its own

#### Scenario: Quiz marker encoded as question mark

- **WHEN** the loop announces the quiz
- **THEN** it plays the session language's codec encoding of "?"

#### Scenario: Playback follows the codec

- **WHEN** the codec of the session language is replaced, for example by a test codec
- **THEN** the orchestrator plays exactly the tokens that codec returns for the current item
- **AND** it still checks the user's answer against the level's Morse pattern
