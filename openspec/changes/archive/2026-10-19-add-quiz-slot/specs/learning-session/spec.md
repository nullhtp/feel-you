## MODIFIED Requirements

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

### Requirement: Level, position and phase are not saved
The session's level, position, phase and quiz item SHALL live in memory only. Every launch SHALL start at the digits level, position 0, outside the quiz, phase `playing`. The language and the learned items are the only data kept across launches (see *The chosen language is saved* in `language-selection`, and `learned-items`).

#### Scenario: Restart returns to the first item
- **WHEN** the user is on the letters level at position 5 and the app is restarted
- **THEN** the session SHALL start at the digits level, position 0, in the saved language

#### Scenario: Restart from the quiz
- **WHEN** the user is in the quiz of the letters level and the app is restarted
- **THEN** the session SHALL start at the digits level, position 0, outside the quiz

## REMOVED Requirements

### Requirement: Navigate to next item
**Reason**: Swiping right on the last item of a level now enters the level's quiz instead of doing nothing, so the old clamp at the last item no longer holds.
**Migration**: See *Navigate to next item or into the quiz*, which keeps the move to the next item and adds the quiz.

## ADDED Requirements

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
