## ADDED Requirements

### Requirement: Cloud key line
The overlay SHALL show, in the bottom-right corner in small dim text, a line `Cloud key: ` followed by the masked cloud key, or `none` when no key is saved, or `checking…` while the key is still being read at launch. It SHALL update as soon as the key is saved or deleted, and SHALL never show more of the key than its masked form.

#### Scenario: Key saved
- **WHEN** the saved key is `sk-or-v1-` followed by 60 hexadecimal characters ending in `a1b2`
- **THEN** the text `Cloud key: sk-or-...a1b2` SHALL be displayed
- **AND** no text containing the key SHALL be displayed

#### Scenario: No key saved
- **WHEN** no key is saved
- **THEN** the text `Cloud key: none` SHALL be displayed

#### Scenario: Key still being read
- **WHEN** the key has not been read from the secure storage yet
- **THEN** the text `Cloud key: checking…` SHALL be displayed

#### Scenario: Line follows a save and a deletion
- **WHEN** a key is saved while the overlay is shown
- **THEN** the line SHALL show its masked form without a restart
- **AND** after the key is deleted it SHALL show `Cloud key: none`

## MODIFIED Requirements

### Requirement: Screen-reader summary of the lesson
Screen readers SHALL see the overlay as a single live-region node, re-announced when it changes, whose label summarises what the overlay draws. In reading order: the level, the item, its pattern in words, the position, the learned count, the phase, when input is buffered that input and, last, `cloud key` with the value of the cloud key line. The zone labels, the dividers, the vibration readout, the cloud key line and the separate text fragments SHALL NOT be nodes of their own.

#### Scenario: Summary while listening
- **WHEN** the session is on letter "A" of the English letters level, outside the quiz, 3 letters are learned, the phase is `listening`, the user has tapped a dot and no cloud key is saved
- **THEN** the summary SHALL be "Letters level, A, dot dash, 1 of 26, learned 3 of 26, listening, input dot, cloud key none"

#### Scenario: Words are spoken with their gaps
- **WHEN** the item is the word "IT" or the buffered input contains a letter gap
- **THEN** the pattern or input SHALL be spoken as words, with "gap" between letters: "dot dot gap dash"

#### Scenario: Level names
- **WHEN** the current level is named "arabic-letters"
- **THEN** the summary SHALL start with "Arabic letters level"

#### Scenario: No input yet
- **WHEN** the input buffer is empty
- **THEN** the summary SHALL go from the phase straight to the cloud key, without "input": "…, playing, cloud key none"

#### Scenario: One node for the overlay
- **WHEN** a screen reader is on and the lesson surface is shown
- **THEN** "DOT", "DASH", "SUBMIT" or "GAP", the item, the pattern, the indicators, the vibration readout and the cloud key line SHALL NOT be separate nodes

#### Scenario: Summary follows the lesson
- **WHEN** the item, the phase, the level, the input or the cloud key changes
- **THEN** the summary SHALL change with it

#### Scenario: Summary with a cloud key
- **WHEN** the saved key masks to `sk-or-...a1b2` and the user is on letter "A" of the English letters level, nothing learned, playing
- **THEN** the summary SHALL be "Letters level, A, dot dash, 1 of 26, learned 0 of 26, playing, cloud key sk-or-...a1b2"
- **AND** it SHALL NOT contain the key

#### Scenario: Cloud key still being read
- **WHEN** the key has not been read from the secure storage yet
- **THEN** the summary SHALL end with "cloud key checking…"
