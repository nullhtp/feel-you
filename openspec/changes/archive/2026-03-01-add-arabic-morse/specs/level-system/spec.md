## MODIFIED Requirements

### Requirement: Level data model
The system SHALL define a `Level` class containing:
- `name`: A string identifier for the level (e.g., "digits", "letters", "arabic-letters").
- `characters`: An ordered `List<String>` of characters in the learning sequence.
- `patterns`: A `Map<String, List<MorseSymbol>>` mapping each character to its Morse pattern.
- `language`: An optional `MorseLanguage?` field. When `null`, the level is universal (included for all languages). When set, it belongs to that specific language.

#### Scenario: Level contains all required fields including language
- **WHEN** a `Level` is created with name "arabic-letters", characters for Arabic alphabet, patterns for each letter, and language `MorseLanguage.arabic`
- **THEN** the `name`, `characters`, `patterns`, and `language` fields SHALL all be accessible

#### Scenario: Universal level has null language
- **WHEN** the digits level is inspected
- **THEN** its `language` field SHALL be `null`

#### Scenario: Language-specific level has language set
- **WHEN** the Arabic letters level is inspected
- **THEN** its `language` field SHALL be `MorseLanguage.arabic`

#### Scenario: Characters list defines learning order
- **WHEN** the digits level's `characters` list is inspected
- **THEN** it SHALL be `["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]`

#### Scenario: Pattern lookup by character
- **WHEN** `level.patterns["3"]` is accessed on the digits level
- **THEN** it SHALL return the Morse pattern for digit 3: `[dot, dot, dot, dash, dash]`

### Requirement: Ordered levels registry
The system SHALL define a top-level `levels` list containing all available levels. The list SHALL contain: digits (universal), English letters, English words, Arabic letters, Arabic words.

#### Scenario: Levels list contains all five levels
- **WHEN** the `levels` list is inspected
- **THEN** it SHALL contain 5 levels total

#### Scenario: Digits level is first
- **WHEN** `levels[0]` is inspected
- **THEN** its `name` SHALL be "digits" and its `language` SHALL be `null`

### Requirement: Language-filtered level list
The system SHALL provide a function `levelsForLanguage(MorseLanguage language)` that returns an ordered list of levels for the given language. The returned list SHALL include all universal levels (where `language` is `null`) followed by language-specific levels.

#### Scenario: English levels include digits, English letters, English words
- **WHEN** `levelsForLanguage(MorseLanguage.english)` is called
- **THEN** it SHALL return a list containing the digits level, English letters level, and English words level, in that order

#### Scenario: Arabic levels include digits, Arabic letters, Arabic words
- **WHEN** `levelsForLanguage(MorseLanguage.arabic)` is called
- **THEN** it SHALL return a list containing the digits level, Arabic letters level, and Arabic words level, in that order

#### Scenario: Filtered list length for English
- **WHEN** `levelsForLanguage(MorseLanguage.english).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for Arabic
- **WHEN** `levelsForLanguage(MorseLanguage.arabic).length` is checked
- **THEN** it SHALL be 3

### Requirement: Words level has 20 characters
The English words level SHALL contain 20 entries in its `characters` list and 20 corresponding pattern entries. The Arabic words level SHALL also contain 20 entries.

#### Scenario: English words level has 20 characters
- **WHEN** the English words level's `characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Arabic words level has 20 characters
- **WHEN** the Arabic words level's `characters.length` is checked
- **THEN** it SHALL be 20

### Requirement: Level provides character count
The system SHALL allow querying the number of characters in a level via its `characters.length` property.

#### Scenario: Digits level has 10 characters
- **WHEN** the digits level's `characters.length` is checked
- **THEN** it SHALL be 10

#### Scenario: English letters level has 26 characters
- **WHEN** the English letters level's `characters.length` is checked
- **THEN** it SHALL be 26

#### Scenario: Arabic letters level has 28 characters
- **WHEN** the Arabic letters level's `characters.length` is checked
- **THEN** it SHALL be 28

### Requirement: Level provides pattern for current position
Given a position index, the system SHALL resolve the character and its Morse pattern from the level data.

#### Scenario: Resolve character at position in Arabic letters level
- **WHEN** position 0 is looked up in the Arabic letters level
- **THEN** the character SHALL be "ا" (Alif) and the pattern SHALL be `[dot, dash]`
