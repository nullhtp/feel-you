## ADDED Requirements

### Requirement: Screen-reader summary of the lesson
Screen readers SHALL see the overlay as a single live-region node, re-announced when it changes, whose label summarises what the overlay draws. In reading order: the level, the item, its pattern in words, the position, the learned count, the phase and, when input is buffered, that input. The zone labels, the dividers, the vibration readout and the separate text fragments SHALL NOT be nodes of their own.

#### Scenario: Summary while listening
- **WHEN** the session is on letter "A" of the English letters level, outside the quiz, 3 letters are learned, the phase is `listening` and the user has tapped a dot
- **THEN** the summary SHALL be "Letters level, A, dot dash, 1 of 26, learned 3 of 26, listening, input dot"

#### Scenario: Words are spoken with their gaps
- **WHEN** the item is the word "IT" or the buffered input contains a letter gap
- **THEN** the pattern or input SHALL be spoken as words, with "gap" between letters: "dot dot gap dash"

#### Scenario: Level names
- **WHEN** the current level is named "arabic-letters"
- **THEN** the summary SHALL start with "Arabic letters level"

#### Scenario: No input yet
- **WHEN** the input buffer is empty
- **THEN** the summary SHALL end with the phase, without "input"

#### Scenario: One node for the overlay
- **WHEN** a screen reader is on and the lesson surface is shown
- **THEN** "DOT", "DASH", "SUBMIT" or "GAP", the item, the pattern, the indicators and the vibration readout SHALL NOT be separate nodes

#### Scenario: Summary follows the lesson
- **WHEN** the item, the phase, the level or the input changes
- **THEN** the summary SHALL change with it
