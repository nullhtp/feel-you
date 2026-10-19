# learning-session Specification

## Purpose

The session state (language, level, position and phase) and the transitions that change it.

## Requirements

### Requirement: Session state tracks current letter
The session state SHALL hold the selected `language` (`MorseLanguage`), a `levelIndex` into that language's level list, a `positionIndex` into the current level and, in the quiz, the quiz item. A session SHALL start at level 0 (digits), position 0, outside the quiz, in the saved language, or English when none is saved, until the picker selects one. A `currentLevel` getter SHALL return the current `Level`, and `currentCharacter` the quiz item in the quiz, else the item at the position.

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

#### Scenario: Current character in the quiz
- **WHEN** the session is in the quiz of the English letters level with quiz item "K"
- **THEN** the current character SHALL be "K"
- **AND** the position index SHALL be 25, the last letter "Z"
- **AND** the state SHALL report that it is in the quiz

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

### Requirement: Session state tracks current phase
The system SHALL maintain a session phase enum with exactly three values: `playing`, `listening`, and `feedback`. The initial phase SHALL be `playing`.

#### Scenario: Initial state is playing phase
- **WHEN** a new session state is created
- **THEN** the session phase SHALL be `playing`

#### Scenario: Phase can be set to any valid value
- **WHEN** the phase is set to `listening`, `feedback`, or `playing`
- **THEN** the session phase SHALL update to the requested value
- **AND** the level and position SHALL NOT change

### Requirement: Navigate to previous item
The system SHALL move the current position to the previous item in the current level when a previous navigation is requested, and reset the phase to `playing`. At the first item of the level the request SHALL be a no-op: there is no wrap-around. In the quiz the request SHALL leave the quiz and return to the last item of the level.

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

#### Scenario: Leave the quiz to the last item
- **WHEN** the session is in the quiz of the digits level
- **AND** previous navigation is requested
- **THEN** the session SHALL no longer be in the quiz
- **AND** the current character SHALL be "9"
- **AND** the phase SHALL be `playing`

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
The session's level, position, phase and quiz item SHALL live in memory only. Every launch SHALL start at the digits level, position 0, outside the quiz, phase `playing`. The language and the learned items are the only data kept across launches (see *The chosen language is saved* in `language-selection`, and `learned-items`).

#### Scenario: Restart returns to the first item
- **WHEN** the user is on the letters level at position 5 and the app is restarted
- **THEN** the session SHALL start at the digits level, position 0, in the saved language

#### Scenario: Restart from the quiz
- **WHEN** the user is in the quiz of the letters level and the app is restarted
- **THEN** the session SHALL start at the digits level, position 0, outside the quiz

### Requirement: Navigate to next item or into the quiz
The system SHALL advance the position to the next item of the current level when a next navigation is requested, and reset the phase to `playing`. On the last item it SHALL enter the level's quiz with a quiz item drawn as described in `quiz`, keeping the position on the last item. In the quiz it SHALL draw a new quiz item. There is no wrap-around.

#### Scenario: Advance from 0 to 1 in digits
- **WHEN** the current level is digits and position is 0
- **AND** next navigation is requested
- **THEN** the current character SHALL be "1"
- **AND** the phase SHALL be `playing`

#### Scenario: Enter the quiz from the last item
- **WHEN** the current position is the last item of the level (e.g., "9" for digits, "Z" for English letters)
- **AND** next navigation is requested
- **THEN** the session SHALL be in the quiz of that level
- **AND** the position SHALL remain on the last item
- **AND** the phase SHALL be `playing`

#### Scenario: Next in the quiz draws a new item
- **WHEN** the session is in the quiz with quiz item "3"
- **AND** next navigation is requested
- **THEN** the session SHALL still be in the quiz
- **AND** the quiz item SHALL NOT be "3"

### Requirement: Other navigation leaves the quiz
Reset, level navigation, home and selecting a language SHALL leave the quiz and then act as they do outside it. A level navigation that is a no-op at the first or last level SHALL leave the session in the quiz with the same quiz item.

#### Scenario: Reset from the quiz
- **WHEN** the session is in the quiz of the English letters level
- **AND** a reset is requested
- **THEN** the session SHALL no longer be in the quiz
- **AND** the current character SHALL be "A"

#### Scenario: Level up from the quiz
- **WHEN** the session is in the quiz of the digits level
- **AND** level-up navigation is requested
- **THEN** the session SHALL be on the first item of the letters level, outside the quiz

#### Scenario: Level up from the quiz of the last level
- **WHEN** the session is in the quiz of the words level with quiz item "HI"
- **AND** level-up navigation is requested
- **THEN** the session SHALL still be in the quiz with quiz item "HI"

#### Scenario: Home from the quiz
- **WHEN** the session is in the quiz of the words level
- **AND** home is requested
- **THEN** the session SHALL be on digit "0", outside the quiz
