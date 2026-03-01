## MODIFIED Requirements

### Requirement: Session state tracks current letter
The system SHALL maintain a `language` field of type `MorseLanguage`, a `levelIndex`, and a `positionIndex` representing the user's position in the language-filtered level list. The initial language SHALL be set by the language picker. The initial level SHALL be the first level in the filtered levels list for the selected language (index 0, digits). The initial position SHALL be 0. A `currentCharacter` getter SHALL return the character at the current position in the current level. A `currentLevel` getter SHALL return the current `Level` object from the language-filtered list.

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

### Requirement: Navigate to next level
The system SHALL advance the `levelIndex` to the next level within the language-filtered level list when a level-up navigation is requested. The `positionIndex` SHALL reset to 0 for the new level. The phase SHALL reset to `playing`. If already at the last level in the filtered list, the request SHALL be a no-op.

#### Scenario: Navigate from digits to Arabic letters (Arabic selected)
- **WHEN** the language is Arabic and the current level is digits (index 0)
- **AND** level-up navigation is requested
- **THEN** the current level SHALL be Arabic letters (index 1) and position SHALL be 0

#### Scenario: Clamp at last level in filtered list
- **WHEN** the current level is the last level in the language-filtered list
- **AND** level-up navigation is requested
- **THEN** the level and position SHALL remain unchanged
- **AND** the phase SHALL remain unchanged

### Requirement: Navigate to previous level
The system SHALL move the `levelIndex` to the previous level within the language-filtered level list when a level-down navigation is requested. The `positionIndex` SHALL reset to 0 for the new level. The phase SHALL reset to `playing`. If already at the first level, the request SHALL be a no-op.

#### Scenario: Navigate from Arabic letters to digits (Arabic selected)
- **WHEN** the language is Arabic and the current level is Arabic letters (index 1)
- **AND** level-down navigation is requested
- **THEN** the current level SHALL be digits (index 0) and position SHALL be 0

#### Scenario: Clamp at first level
- **WHEN** the current level is the first level (digits, index 0)
- **AND** level-down navigation is requested
- **THEN** the level and position SHALL remain unchanged

### Requirement: Home resets to first level, first position
The system SHALL reset `levelIndex` to 0 and `positionIndex` to 0 and the phase to `playing` when a home action is requested. The selected language SHALL NOT change.

#### Scenario: Home from Arabic letters level
- **WHEN** the language is Arabic and the current level is Arabic letters (index 1) and position is 10
- **AND** home is requested
- **THEN** the level SHALL be digits (index 0), position SHALL be 0 (character "0"), and phase SHALL be `playing`
- **AND** the language SHALL remain `MorseLanguage.arabic`

#### Scenario: Home when already at home position
- **WHEN** the current level is digits (index 0) and position is 0
- **AND** home is requested
- **THEN** the state SHALL remain unchanged except phase SHALL be `playing`

### Requirement: Select language
The system SHALL provide a `selectLanguage(MorseLanguage)` method on the session notifier that sets the language, resets `levelIndex` to 0, resets `positionIndex` to 0, and sets the phase to `playing`.

#### Scenario: Select Arabic language
- **WHEN** `selectLanguage(MorseLanguage.arabic)` is called
- **THEN** the language SHALL be `MorseLanguage.arabic`, levelIndex SHALL be 0, positionIndex SHALL be 0, and phase SHALL be `playing`

#### Scenario: Select English language
- **WHEN** `selectLanguage(MorseLanguage.english)` is called
- **THEN** the language SHALL be `MorseLanguage.english`, levelIndex SHALL be 0, positionIndex SHALL be 0, and phase SHALL be `playing`

### Requirement: State is in-memory only
The session state SHALL NOT be persisted to disk or any external storage. The state SHALL reset to its initial values when the app restarts. The language picker SHALL re-appear on restart.

#### Scenario: State resets on fresh provider creation
- **WHEN** a new `ProviderScope` is created (e.g., app restart)
- **THEN** no session state SHALL exist until the user selects a language via the picker
