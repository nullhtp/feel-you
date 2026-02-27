## ADDED Requirements

### Requirement: Session state tracks current letter

The system SHALL maintain a current letter index representing the user's position in the A-Z learning sequence. The initial letter SHALL be A (index 0). The letter index SHALL reference the `morseLetters` list from the Morse data model.

#### Scenario: Initial state is letter A

- **WHEN** a new session state is created
- **THEN** the current letter SHALL be A (index 0)

#### Scenario: Current letter is readable

- **WHEN** the session state exists
- **THEN** the current letter (as a String, e.g. "A") and the current index (as an int) SHALL both be accessible

### Requirement: Session state tracks current phase

The system SHALL maintain a session phase enum with exactly three values: `playing`, `listening`, and `feedback`. The initial phase SHALL be `playing`.

#### Scenario: Initial state is playing phase

- **WHEN** a new session state is created
- **THEN** the session phase SHALL be `playing`

#### Scenario: Phase can be set to any valid value

- **WHEN** the phase is set to `listening`, `feedback`, or `playing`
- **THEN** the session phase SHALL update to the requested value

### Requirement: Navigate to next letter

The system SHALL advance the current letter to the next letter in alphabetical order when a next-letter navigation is requested. The phase SHALL be reset to `playing` on navigation.

#### Scenario: Advance from A to B

- **WHEN** the current letter is A
- **AND** next-letter navigation is requested
- **THEN** the current letter SHALL be B
- **AND** the phase SHALL be `playing`

#### Scenario: Advance from middle of alphabet

- **WHEN** the current letter is M
- **AND** next-letter navigation is requested
- **THEN** the current letter SHALL be N
- **AND** the phase SHALL be `playing`

#### Scenario: Clamp at Z (boundary)

- **WHEN** the current letter is Z
- **AND** next-letter navigation is requested
- **THEN** the current letter SHALL remain Z
- **AND** the phase SHALL remain unchanged

### Requirement: Navigate to previous letter

The system SHALL move the current letter to the previous letter in alphabetical order when a previous-letter navigation is requested. The phase SHALL be reset to `playing` on navigation.

#### Scenario: Go back from B to A

- **WHEN** the current letter is B
- **AND** previous-letter navigation is requested
- **THEN** the current letter SHALL be A
- **AND** the phase SHALL be `playing`

#### Scenario: Clamp at A (boundary)

- **WHEN** the current letter is A
- **AND** previous-letter navigation is requested
- **THEN** the current letter SHALL remain A
- **AND** the phase SHALL remain unchanged

### Requirement: Reset to letter A

The system SHALL reset the current letter to A (index 0) and the phase to `playing` when a reset is requested.

#### Scenario: Reset from middle of alphabet

- **WHEN** the current letter is M and the phase is `feedback`
- **AND** a reset is requested
- **THEN** the current letter SHALL be A
- **AND** the phase SHALL be `playing`

#### Scenario: Reset when already at A

- **WHEN** the current letter is already A
- **AND** a reset is requested
- **THEN** the current letter SHALL remain A
- **AND** the phase SHALL be `playing`

### Requirement: State is exposed via Riverpod provider

The session state SHALL be exposed as a `StateNotifierProvider` so that other parts of the app can watch for state changes reactively. The provider SHALL be overridable for testing.

#### Scenario: Provider exposes current state

- **WHEN** a consumer watches the session state provider
- **THEN** it SHALL receive the current `SessionState` including letter index and phase

#### Scenario: Provider notifies on state change

- **WHEN** the session state changes (letter or phase)
- **THEN** all watching consumers SHALL be notified with the new state

### Requirement: State is in-memory only

The session state SHALL NOT be persisted to disk or any external storage. The state SHALL reset to its initial values (letter A, phase `playing`) when the app restarts.

#### Scenario: State resets on fresh provider creation

- **WHEN** a new `ProviderScope` is created (e.g., app restart)
- **THEN** the session state SHALL be at letter A with phase `playing`
