## MODIFIED Requirements

### Requirement: Level data model
The system SHALL define a `Level` class containing:
- `name`: A string identifier for the level (e.g., "digits", "letters", "arabic-letters").
- `characters`: An ordered `List<String>` of characters in the learning sequence.
- `patterns`: A `Map<String, List<MorseSignal>>` mapping each character to its Morse signal pattern (for single-character levels) OR the level MAY reference word-level token patterns from the alphabet.
- `language`: An optional `MorseLanguage?` field. When `null`, the level is universal. When set, it belongs to that specific language.

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
- **THEN** it SHALL return the Morse signal pattern for digit 3: `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dash, MorseSignal.dash]`

### Requirement: Level equality uses all fields
The `Level` class SHALL use all fields (`name`, `characters`, `patterns`, `language`) for equality comparison, not just `name`.

#### Scenario: Levels with same name but different content are not equal
- **WHEN** two `Level` instances have the same `name` but different `characters`
- **THEN** they SHALL NOT be equal

#### Scenario: Identical levels are equal
- **WHEN** two `Level` instances have the same `name`, `characters`, `patterns`, and `language`
- **THEN** they SHALL be equal

### Requirement: Levels defined within MorseAlphabet
Each `MorseAlphabet` instance SHALL define its own levels as part of its data. The digits alphabet SHALL define a "digits" level. The English alphabet SHALL define "letters" and "words" levels. The Arabic alphabet SHALL define "arabic-letters" and "arabic-words" levels.

#### Scenario: Digits alphabet defines one level
- **WHEN** the digits `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain exactly one level named "digits"

#### Scenario: English alphabet defines two levels
- **WHEN** the English `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain two levels: "letters" and "words"

#### Scenario: Arabic alphabet defines two levels
- **WHEN** the Arabic `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain two levels: "arabic-letters" and "arabic-words"

### Requirement: Language-filtered level list from registry
The `MorseAlphabetRegistry` SHALL provide a `levelsForLanguage(MorseLanguage language)` method that returns an ordered, unmodifiable list of levels. The list SHALL include all universal levels (from alphabets where `language` is `null`) followed by language-specific levels, preserving definition order.

#### Scenario: English levels include digits, English letters, English words
- **WHEN** `registry.levelsForLanguage(MorseLanguage.english)` is called
- **THEN** it SHALL return a list containing the digits level, English letters level, and English words level, in that order

#### Scenario: Arabic levels include digits, Arabic letters, Arabic words
- **WHEN** `registry.levelsForLanguage(MorseLanguage.arabic)` is called
- **THEN** it SHALL return a list containing the digits level, Arabic letters level, and Arabic words level, in that order

#### Scenario: Filtered list length for English
- **WHEN** `registry.levelsForLanguage(MorseLanguage.english).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for Arabic
- **WHEN** `registry.levelsForLanguage(MorseLanguage.arabic).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Levels list is unmodifiable
- **WHEN** a consumer attempts to modify the list returned by `levelsForLanguage`
- **THEN** it SHALL throw an `UnsupportedError`

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
Given a position index, the system SHALL resolve the character and its Morse signal pattern from the level data.

#### Scenario: Resolve character at position in Arabic letters level
- **WHEN** position 0 is looked up in the Arabic letters level
- **THEN** the character SHALL be "ا" (Alif) and the pattern SHALL be `[MorseSignal.dot, MorseSignal.dash]`
