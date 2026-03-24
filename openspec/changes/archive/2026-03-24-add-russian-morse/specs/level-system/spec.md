## MODIFIED Requirements

### Requirement: Levels defined within MorseAlphabet
Each `MorseAlphabet` instance SHALL define its own levels as part of its data. The digits alphabet SHALL define a "digits" level. The English alphabet SHALL define "letters" and "words" levels. The Arabic alphabet SHALL define "arabic-letters" and "arabic-words" levels. The Russian alphabet SHALL define "russian-letters" and "russian-words" levels.

#### Scenario: Digits alphabet defines one level
- **WHEN** the digits `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain exactly one level named "digits"

#### Scenario: English alphabet defines two levels
- **WHEN** the English `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain two levels: "letters" and "words"

#### Scenario: Arabic alphabet defines two levels
- **WHEN** the Arabic `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain two levels: "arabic-letters" and "arabic-words"

#### Scenario: Russian alphabet defines two levels
- **WHEN** the Russian `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain two levels: "russian-letters" and "russian-words"

### Requirement: Language-filtered level list from registry
The `MorseAlphabetRegistry` SHALL provide a `levelsForLanguage(MorseLanguage language)` method that returns an ordered, unmodifiable list of levels. The list SHALL include all universal levels (from alphabets where `language` is `null`) followed by language-specific levels, preserving definition order.

#### Scenario: English levels include digits, English letters, English words
- **WHEN** `registry.levelsForLanguage(MorseLanguage.english)` is called
- **THEN** it SHALL return a list containing the digits level, English letters level, and English words level, in that order

#### Scenario: Arabic levels include digits, Arabic letters, Arabic words
- **WHEN** `registry.levelsForLanguage(MorseLanguage.arabic)` is called
- **THEN** it SHALL return a list containing the digits level, Arabic letters level, and Arabic words level, in that order

#### Scenario: Russian levels include digits, Russian letters, Russian words
- **WHEN** `registry.levelsForLanguage(MorseLanguage.russian)` is called
- **THEN** it SHALL return a list containing the digits level, Russian letters level, and Russian words level, in that order

#### Scenario: Filtered list length for English
- **WHEN** `registry.levelsForLanguage(MorseLanguage.english).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for Arabic
- **WHEN** `registry.levelsForLanguage(MorseLanguage.arabic).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for Russian
- **WHEN** `registry.levelsForLanguage(MorseLanguage.russian).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Levels list is unmodifiable
- **WHEN** a consumer attempts to modify the list returned by `levelsForLanguage`
- **THEN** it SHALL throw an `UnsupportedError`

### Requirement: Russian letters level has 32 characters
The Russian letters level SHALL contain 32 entries in its `characters` list and 32 corresponding pattern entries (Ё excluded).

#### Scenario: Russian letters level has 32 characters
- **WHEN** the Russian letters level's `characters.length` is checked
- **THEN** it SHALL be 32

### Requirement: Words level has 20 characters
The English words level SHALL contain 20 entries in its `characters` list and 20 corresponding pattern entries. The Arabic words level SHALL also contain 20 entries. The Russian words level SHALL also contain 20 entries.

#### Scenario: English words level has 20 characters
- **WHEN** the English words level's `characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Arabic words level has 20 characters
- **WHEN** the Arabic words level's `characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Russian words level has 20 characters
- **WHEN** the Russian words level's `characters.length` is checked
- **THEN** it SHALL be 20

### Requirement: Level provides pattern for current position
Given a position index, the system SHALL resolve the character and its Morse signal pattern from the level data.

#### Scenario: Resolve character at position in Russian letters level
- **WHEN** position 0 is looked up in the Russian letters level
- **THEN** the character SHALL be "А" and the pattern SHALL be `[MorseSignal.dot, MorseSignal.dash]`
