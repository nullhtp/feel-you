## MODIFIED Requirements

### Requirement: Haptic feedback on bottom zone tap
When a `BottomZoneAction` arrives while the teaching loop is listening (the user has tapped at least one dot or dash), the orchestrator SHALL first play the tap feedback, one 50 ms vibration (`playTapFeedback()`, see `vibration-engine`). Only once it has finished SHALL it submit the input or add a letter gap. A bottom-strip tap while the item plays or during feedback SHALL get no tap feedback. The classifier itself SHALL NOT vibrate.

#### Scenario: Haptic pulse on bottom zone tap
- **WHEN** the user has tapped a dot and taps in the bottom zone (non-swipe, non-reset)
- **THEN** a 50 ms tap feedback SHALL be played
- **AND** the input SHALL be submitted, or the letter gap added, only after the tap feedback has finished

#### Scenario: No haptic pulse on swipe through bottom zone
- **WHEN** the user swipes through the bottom zone
- **THEN** no haptic pulse SHALL be triggered for the bottom zone

#### Scenario: No tap feedback during feedback
- **WHEN** the success or error signal is playing and the user taps the bottom zone
- **THEN** no tap feedback SHALL be played, and nothing SHALL be submitted or added

#### Scenario: Navigation during the tap feedback
- **WHEN** a navigation event, a stop or a restart of the loop happens while the tap feedback plays
- **THEN** the bottom-strip action SHALL be abandoned: the input SHALL NOT be submitted and no letter gap SHALL be added for the item the user has left

### Requirement: Level-aware behavior in teaching orchestrator
The `TeachingOrchestrator` SHALL handle a `BottomZoneAction` received while listening by the kind of the current level (`Level.kind`, not its index), after the tap feedback:
- On a **words** level: insert a `charGap` into the gesture classifier's input buffer (`insertCharGap()`), which restarts the silence timer and emits no event
- On a **characters** level (digits, letters): immediately trigger `InputComplete` with the current accumulated input buffer (`submitInput()`)

#### Scenario: Bottom zone tap on words level inserts charGap
- **WHEN** the current level is a words level
- **AND** the user has entered `[dot, dot]` and taps the bottom zone
- **THEN** a `charGap` symbol SHALL be added to the input buffer
- **AND** the input buffer becomes `[dot, dot, charGap]`
- **AND** the silence timer SHALL be restarted
- **AND** no `MorseInput` event SHALL be emitted for the gap

#### Scenario: Bottom zone tap on letters level triggers InputComplete
- **WHEN** the current level is letters (index 1)
- **AND** the user has entered `[dot, dash]` and taps the bottom zone
- **THEN** an `InputComplete([dot, dash])` event SHALL be emitted
- **AND** the input buffer SHALL be cleared

#### Scenario: Bottom zone tap on digits level triggers InputComplete
- **WHEN** the current level is digits (index 0)
- **AND** the user has entered `[dash, dash, dash]` and taps the bottom zone
- **THEN** an `InputComplete([dash, dash, dash])` event SHALL be emitted
- **AND** the input buffer SHALL be cleared

#### Scenario: Bottom zone tap with empty buffer on non-words level
- **WHEN** the current level is letters
- **AND** no Morse input has been entered (empty buffer)
- **AND** the user taps the bottom zone
- **THEN** no `InputComplete` event SHALL be emitted (nothing to submit)

#### Scenario: Bottom zone tap with empty buffer on words level
- **WHEN** the current level is words
- **AND** no Morse input has been entered (empty buffer)
- **AND** the user taps the bottom zone
- **THEN** no `charGap` SHALL be inserted (cannot start with a charGap)

#### Scenario: Bottom zone tap during playback is ignored on every level
- **WHEN** the word or character pattern is playing (the user has not tapped a dot or dash yet)
- **AND** the user taps the bottom zone
- **THEN** playback SHALL NOT be interrupted and the pattern SHALL keep repeating
- **AND** no tap feedback SHALL be played and the input buffer SHALL stay empty
