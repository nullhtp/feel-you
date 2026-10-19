## REMOVED Requirements

### Requirement: Returning to the foreground restarts the current item
**Reason**: Its "Leaving for the picker" scenario names the screen a double shake used to open; it now opens the home menu, and a renamed scenario cannot be carried by MODIFIED.
**Migration**: Replaced by "Returning to the foreground restarts the lesson's current item" below, the same requirement with the scenario "Leaving for the menu". The menu's own lifecycle is in `home-menu`.

## ADDED Requirements

### Requirement: Returning to the foreground restarts the lesson's current item
When the app is resumed after the lesson was suspended, the wakelock SHALL be enabled again and the teaching loop SHALL start again on the same item, from the beginning, in the `playing` phase, with no input. As on any start, a word SHALL be spelled first, and in the quiz `?` SHALL be played first. Language, level, position and quiz item SHALL NOT change. A resume that follows no suspension SHALL do nothing.

#### Scenario: Resume replays the current item
- **WHEN** the app was suspended on letter "K" while listening, with a dot already entered
- **AND** the app is resumed
- **THEN** the session SHALL be on "K" in the `playing` phase, with an empty input buffer
- **AND** the pattern of "K" SHALL be played from its first element
- **AND** it SHALL keep repeating after each repeat pause

#### Scenario: Wakelock enabled again
- **WHEN** the app is resumed after a suspension
- **THEN** the wakelock SHALL be enabled again

#### Scenario: Resume on a word
- **WHEN** the app is resumed on a word outside the quiz
- **THEN** the word SHALL be spelled letter by letter before it is drilled

#### Scenario: Resume after feedback was cut short
- **WHEN** the app was suspended while the success or error signal of an answer played
- **AND** the app is resumed
- **THEN** the feedback SHALL NOT be played again
- **AND** the loop SHALL start on the same item in the `playing` phase, also in the quiz after a correct answer

#### Scenario: Several trips
- **WHEN** the app goes to the background and comes back several times in a row
- **THEN** each return SHALL start the loop exactly once, and the loop SHALL be running after the last one

#### Scenario: Leaving for the menu
- **WHEN** a double shake has stopped the loop and the home menu is replacing the lesson surface
- **AND** the app goes to the background and comes back during the transition
- **THEN** the teaching loop SHALL NOT start again
