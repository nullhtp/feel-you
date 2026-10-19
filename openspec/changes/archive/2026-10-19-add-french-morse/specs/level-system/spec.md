## MODIFIED Requirements

### Requirement: Levels defined within MorseAlphabet
Each `MorseAlphabet` instance SHALL define its own levels as part of its data. The digits alphabet SHALL define a "digits" level. Each language alphabet SHALL define a letters level and a words level: English names them "letters" and "words", and every other language prefixes them with its `MorseLanguage` name, e.g. "arabic-letters" and "arabic-words".

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

#### Scenario: Spanish alphabet defines two levels
- **WHEN** the Spanish `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain two levels: "spanish-letters" and "spanish-words"

#### Scenario: French alphabet defines two levels
- **WHEN** the French `MorseAlphabet` instance's `levels` is inspected
- **THEN** it SHALL contain two levels: "french-letters" and "french-words"

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

#### Scenario: Spanish levels include digits, Spanish letters, Spanish words
- **WHEN** `registry.levelsForLanguage(MorseLanguage.spanish)` is called
- **THEN** it SHALL return a list containing the digits level, Spanish letters level, and Spanish words level, in that order

#### Scenario: French levels include digits, French letters, French words
- **WHEN** `registry.levelsForLanguage(MorseLanguage.french)` is called
- **THEN** it SHALL return a list containing the digits level, French letters level, and French words level, in that order

#### Scenario: Filtered list length for English
- **WHEN** `registry.levelsForLanguage(MorseLanguage.english).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for Arabic
- **WHEN** `registry.levelsForLanguage(MorseLanguage.arabic).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for Russian
- **WHEN** `registry.levelsForLanguage(MorseLanguage.russian).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for Spanish
- **WHEN** `registry.levelsForLanguage(MorseLanguage.spanish).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Filtered list length for French
- **WHEN** `registry.levelsForLanguage(MorseLanguage.french).length` is checked
- **THEN** it SHALL be 3

#### Scenario: Levels list is unmodifiable
- **WHEN** a consumer attempts to modify the list returned by `levelsForLanguage`
- **THEN** it SHALL throw an `UnsupportedError`

### Requirement: Words level has 20 characters
The English words level SHALL contain 20 entries in its `characters` list and 20 corresponding pattern entries. The Arabic words level SHALL also contain 20 entries. The Russian words level SHALL also contain 20 entries. The Spanish words level SHALL also contain 20 entries. The French words level SHALL also contain 20 entries.

#### Scenario: English words level has 20 characters
- **WHEN** the English words level's `characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Arabic words level has 20 characters
- **WHEN** the Arabic words level's `characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Russian words level has 20 characters
- **WHEN** the Russian words level's `characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Spanish words level has 20 characters
- **WHEN** the Spanish words level's `characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: French words level has 20 characters
- **WHEN** the French words level's `characters.length` is checked
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

#### Scenario: Spanish letters level has 27 characters
- **WHEN** the Spanish letters level's `characters.length` is checked
- **THEN** it SHALL be 27

#### Scenario: French letters level has 30 characters
- **WHEN** the French letters level's `characters.length` is checked
- **THEN** it SHALL be 30

### Requirement: Level provides pattern for current position
Given a position index, the system SHALL resolve the character and its Morse signal pattern from the level data.

#### Scenario: Resolve character at position in Arabic letters level
- **WHEN** position 0 is looked up in the Arabic letters level
- **THEN** the character SHALL be "ا" (Alif) and the pattern SHALL be `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Resolve character at position in Russian letters level
- **WHEN** position 0 is looked up in the Russian letters level
- **THEN** the character SHALL be "А" and the pattern SHALL be `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Resolve Ñ in the Spanish letters level
- **WHEN** position 14 is looked up in the Spanish letters level
- **THEN** the character SHALL be "Ñ" and the pattern SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dash]`

#### Scenario: Resolve É in the French letters level
- **WHEN** position 28 is looked up in the French letters level
- **THEN** the character SHALL be "É" and the pattern SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dash, MorseSignal.dot, MorseSignal.dot]`
