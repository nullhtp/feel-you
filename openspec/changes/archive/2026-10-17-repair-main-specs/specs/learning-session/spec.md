## MODIFIED Requirements

### Requirement: Session state tracks current letter
The session state SHALL hold the selected `language` (`MorseLanguage`), a `levelIndex` into that language's level list and a `positionIndex` into the current level. A session SHALL start at level 0 (digits), position 0, in the saved language, or English when none is saved, until the picker selects one. A `currentLevel` getter SHALL return the current `Level` from the language's list, and a `currentCharacter` getter the item at the current position.

#### Scenario: Initial state after selecting English
- **WHEN** a new session state is created with language `MorseLanguage.english`
- **THEN** the current level SHALL be digits (level index 0) and the current character SHALL be "0" (position index 0)

#### Scenario: Initial state after selecting Arabic
- **WHEN** a new session state is created with language `MorseLanguage.arabic`
- **THEN** the current level SHALL be digits (level index 0) and the current character SHALL be "0" (position index 0)

#### Scenario: Current character is readable
- **WHEN** the session state exists
- **THEN** the current character (as a String), the current level index, the current position index, and the selected language SHALL all be accessible

#### Scenario: Levels are filtered by selected language
- **WHEN** the session language is `MorseLanguage.arabic`
- **AND** the user navigates to level index 1
- **THEN** the current level SHALL be the Arabic letters level (not English letters)

## ADDED Requirements

### Requirement: Session state tracks current phase
The system SHALL maintain a session phase enum with exactly three values: `playing`, `listening`, and `feedback`. The initial phase SHALL be `playing`.

#### Scenario: Initial state is playing phase
- **WHEN** a new session state is created
- **THEN** the session phase SHALL be `playing`

#### Scenario: Phase can be set to any valid value
- **WHEN** the phase is set to `listening`, `feedback`, or `playing`
- **THEN** the session phase SHALL update to the requested value
- **AND** the level and position SHALL NOT change

### Requirement: Navigate to next item
The system SHALL advance the current position to the next item in the current level when a next navigation is requested, and reset the phase to `playing`. At the last item of the level the request SHALL be a no-op: there is no wrap-around.

#### Scenario: Advance from 0 to 1 in digits
- **WHEN** the current level is digits and position is 0
- **AND** next navigation is requested
- **THEN** the current character SHALL be "1"
- **AND** the phase SHALL be `playing`

#### Scenario: Clamp at last position (boundary)
- **WHEN** the current position is at the last item in the level (e.g., "9" for digits, "Z" for English letters)
- **AND** next navigation is requested
- **THEN** the position SHALL remain unchanged
- **AND** the phase SHALL remain unchanged

### Requirement: Navigate to previous item
The system SHALL move the current position to the previous item in the current level when a previous navigation is requested, and reset the phase to `playing`. At the first item of the level the request SHALL be a no-op: there is no wrap-around.

#### Scenario: Go back from 1 to 0 in digits
- **WHEN** the current level is digits and position is 1
- **AND** previous navigation is requested
- **THEN** the current character SHALL be "0"
- **AND** the phase SHALL be `playing`

#### Scenario: Clamp at first position (boundary)
- **WHEN** the current position is 0
- **AND** previous navigation is requested
- **THEN** the position SHALL remain unchanged
- **AND** the phase SHALL remain unchanged

### Requirement: Reset to the first item of the level
The system SHALL reset the position to 0 within the current level and the phase to `playing` when a reset is requested. The level and the language SHALL NOT change.

#### Scenario: Reset within digits level
- **WHEN** the current level is digits and position is 5
- **AND** a reset is requested
- **THEN** the position SHALL be 0 (character "0")
- **AND** the phase SHALL be `playing`
- **AND** the level SHALL remain digits

#### Scenario: Reset within letters level
- **WHEN** the language is English, the current level is letters and position is 12 (character "M")
- **AND** a reset is requested
- **THEN** the position SHALL be 0 (character "A")
- **AND** the phase SHALL be `playing`
- **AND** the level SHALL remain letters

### Requirement: State is exposed via Riverpod provider
The session state SHALL be exposed as `sessionNotifierProvider`, a `StateNotifierProvider<SessionNotifier, SessionState>`, so other parts of the app can watch it and call its transitions. Its initial language SHALL be the language saved on an earlier run, or English when none is saved. It SHALL resolve levels from `morseRegistryProvider`, and both providers SHALL be overridable for testing.

#### Scenario: Provider exposes current state
- **WHEN** a consumer watches `sessionNotifierProvider`
- **THEN** it SHALL receive the current `SessionState`, including language, level, position and phase

#### Scenario: Provider notifies on state change
- **WHEN** the session state changes (language, level, position or phase)
- **THEN** all watching consumers SHALL be notified with the new state

#### Scenario: Initial language is the saved one
- **WHEN** Russian was saved on an earlier run and the provider is first read
- **THEN** the session language SHALL be `MorseLanguage.russian`

#### Scenario: English when nothing is saved
- **WHEN** no language is saved and the provider is first read
- **THEN** the session language SHALL be `MorseLanguage.english`

### Requirement: Level, position and phase are not saved
The session's level, position and phase SHALL live in memory only. Every launch SHALL start at the digits level, position 0, phase `playing`. The language is the only part of the session kept across launches (see *The chosen language is saved* in `language-selection`).

#### Scenario: Restart returns to the first item
- **WHEN** the user is on the letters level at position 5 and the app is restarted
- **THEN** the session SHALL start at the digits level, position 0, in the saved language

## REMOVED Requirements

### Requirement: State is in-memory only
**Reason**: Since the chosen language is saved, the picker no longer reappears on every launch and a session exists before the picker is used.
**Migration**: Replaced by *Level, position and phase are not saved* here and *The chosen language is saved* in `language-selection`.
