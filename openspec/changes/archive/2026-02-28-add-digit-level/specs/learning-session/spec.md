## MODIFIED Requirements

### Requirement: Session state tracks current letter

The system SHALL maintain a `levelIndex` and `positionIndex` representing the user's position in the level-based learning system. The initial level SHALL be the first level in the levels list (index 0, digits). The initial position SHALL be 0. A `currentCharacter` getter SHALL return the character at the current position in the current level. A `currentLevel` getter SHALL return the current `Level` object.

#### Scenario: Initial state is digit 0

- **WHEN** a new session state is created
- **THEN** the current level SHALL be digits (level index 0) and the current character SHALL be "0" (position index 0)

#### Scenario: Current character is readable

- **WHEN** the session state exists
- **THEN** the current character (as a String), the current level index, and the current position index SHALL all be accessible

### Requirement: Navigate to next letter

The system SHALL advance the current position to the next character in the current level's character list when a next navigation is requested. The phase SHALL be reset to `playing` on navigation.

#### Scenario: Advance from 0 to 1 in digits

- **WHEN** the current level is digits and position is 0
- **AND** next navigation is requested
- **THEN** the current character SHALL be "1"
- **AND** the phase SHALL be `playing`

#### Scenario: Clamp at last position (boundary)

- **WHEN** the current position is at the last character in the level (e.g., "9" for digits, "Z" for letters)
- **AND** next navigation is requested
- **THEN** the position SHALL remain unchanged
- **AND** the phase SHALL remain unchanged

### Requirement: Navigate to previous letter

The system SHALL move the current position to the previous character in the current level's character list when a previous navigation is requested. The phase SHALL be reset to `playing` on navigation.

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

### Requirement: Reset to letter A

The system SHALL reset the position to 0 within the current level and the phase to `playing` when a reset is requested. The level SHALL NOT change.

#### Scenario: Reset within digits level

- **WHEN** the current level is digits and position is 5
- **AND** a reset is requested
- **THEN** the position SHALL be 0 (character "0")
- **AND** the phase SHALL be `playing`
- **AND** the level SHALL remain digits

#### Scenario: Reset within letters level

- **WHEN** the current level is letters and position is 12 (character "M")
- **AND** a reset is requested
- **THEN** the position SHALL be 0 (character "A")
- **AND** the phase SHALL be `playing`
- **AND** the level SHALL remain letters

## ADDED Requirements

### Requirement: Navigate to next level

The system SHALL advance the `levelIndex` to the next level when a level-up navigation is requested. The `positionIndex` SHALL reset to 0 for the new level. The phase SHALL reset to `playing`. If already at the last level, the request SHALL be a no-op.

#### Scenario: Navigate from digits to letters

- **WHEN** the current level is digits (index 0)
- **AND** level-up navigation is requested
- **THEN** the current level SHALL be letters (index 1) and position SHALL be 0 (character "A")
- **AND** the phase SHALL be `playing`

#### Scenario: Clamp at last level (boundary)

- **WHEN** the current level is the last level (letters, index 1)
- **AND** level-up navigation is requested
- **THEN** the level and position SHALL remain unchanged
- **AND** the phase SHALL remain unchanged

### Requirement: Navigate to previous level

The system SHALL move the `levelIndex` to the previous level when a level-down navigation is requested. The `positionIndex` SHALL reset to 0 for the new level. The phase SHALL reset to `playing`. If already at the first level, the request SHALL be a no-op.

#### Scenario: Navigate from letters to digits

- **WHEN** the current level is letters (index 1)
- **AND** level-down navigation is requested
- **THEN** the current level SHALL be digits (index 0) and position SHALL be 0 (character "0")
- **AND** the phase SHALL be `playing`

#### Scenario: Clamp at first level (boundary)

- **WHEN** the current level is the first level (digits, index 0)
- **AND** level-down navigation is requested
- **THEN** the level and position SHALL remain unchanged
- **AND** the phase SHALL remain unchanged

### Requirement: Home resets to first level, first position

The system SHALL reset `levelIndex` to 0 and `positionIndex` to 0 and the phase to `playing` when a home action is requested. This is the global "home" action triggered by phone shake.

#### Scenario: Home from letters level, middle position

- **WHEN** the current level is letters (index 1) and position is 12
- **AND** home is requested
- **THEN** the level SHALL be digits (index 0), position SHALL be 0 (character "0"), and phase SHALL be `playing`

#### Scenario: Home when already at home position

- **WHEN** the current level is digits (index 0) and position is 0
- **AND** home is requested
- **THEN** the state SHALL remain unchanged except phase SHALL be `playing`

### Requirement: State is in-memory only

The session state SHALL NOT be persisted to disk or any external storage. The state SHALL reset to its initial values (level 0 digits, position 0, phase `playing`) when the app restarts.

#### Scenario: State resets on fresh provider creation

- **WHEN** a new `ProviderScope` is created (e.g., app restart)
- **THEN** the session state SHALL be at level 0 (digits), position 0, with phase `playing`
