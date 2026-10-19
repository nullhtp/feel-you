## Purpose

Which items the user has learned, per language and level, kept on the device across launches so the quiz grows with the user's progress from session to session.

## ADDED Requirements

### Requirement: An item is learned when first answered correctly in the lessons
An item SHALL become learned, for the current language and level, the first time the user answers it correctly in the lessons. A learned item SHALL stay learned. Answers in the quiz SHALL NOT add or remove learned items.

#### Scenario: First correct answer
- **WHEN** the session is on letter "K" of the English letters level, outside the quiz
- **AND** the user's answer is correct
- **THEN** "K" SHALL be a learned item of the English letters level

#### Scenario: Wrong answers do not unlearn
- **WHEN** "K" is learned and the user later answers "K" wrongly in the lessons
- **THEN** "K" SHALL still be learned

#### Scenario: Quiz answers do not count
- **WHEN** "M" is not learned and "M" is a quiz item drawn from the whole level
- **AND** the user answers it correctly in the quiz
- **THEN** "M" SHALL still not be learned

### Requirement: Learned items are kept per language and level
Learned items SHALL be kept separately for each language and level. Learning an item in one language SHALL NOT make it learned in another, including the digits, which have the same patterns in every language.

#### Scenario: Digits per language
- **WHEN** digit "5" is learned in English
- **AND** the user switches to Russian
- **THEN** "5" SHALL NOT be a learned item of the Russian digits level

### Requirement: Learned items are saved on the device
Learned items SHALL be saved on the device (`SharedPreferences`, a string list per language and level, key `learned_items.<language>.<level name>`) as the items themselves, and read back on the next launch. Every launch SHALL still start at the digits level on 0. Saving is best effort: when the storage cannot be loaded or written, the app SHALL still run and keep learned items in memory for the current run.

#### Scenario: Learned items survive a restart
- **WHEN** "A" and "B" are learned on the English letters level and the app is restarted
- **THEN** "A" and "B" SHALL still be learned items of the English letters level
- **AND** the session SHALL start at the digits level on 0

#### Scenario: Storage unavailable
- **WHEN** the platform storage cannot be loaded at launch
- **THEN** learned items SHALL be kept in memory for the current run only

### Requirement: Stored items that are not in the level are ignored
A stored item that is not an item of its level SHALL be ignored, and so SHALL a stored value that is not a string list. The level's other learned items SHALL still be read.

#### Scenario: Word removed from a level
- **WHEN** the stored learned items of a words level include a word that is no longer in that level
- **THEN** that word SHALL be ignored and the other stored words SHALL be learned

#### Scenario: Corrupt value
- **WHEN** the stored value for a level is not a string list
- **THEN** the level SHALL have no learned items

### Requirement: Learned items cannot be cleared from the app
The app SHALL offer no gesture or screen that clears learned items. Clearing the app's data (Android) or reinstalling it (iOS) SHALL clear them.

#### Scenario: No clearing gesture
- **WHEN** the user performs any gesture in the lessons, the quiz or the language picker
- **THEN** no learned item SHALL be removed
