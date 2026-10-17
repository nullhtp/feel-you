## MODIFIED Requirements

### Requirement: Level data model
The system SHALL define a `Level` class with: `name` (e.g. "digits" or "arabic-letters"), `characters` (the items in learning order), `patterns` (each item's `List<MorseSignal>`), `kind` (`LevelKind.characters` by default, or `LevelKind.words`), `wordPatterns` (each word's `List<MorseToken>`, required for a words level) and `language` (`MorseLanguage?`, `null` for a universal level). Behaviour that differs for words SHALL switch on `kind`, never on the level's position.

#### Scenario: Level contains all required fields including language
- **WHEN** a `Level` is created with name "arabic-letters", characters for Arabic alphabet, patterns for each letter, and language `MorseLanguage.arabic`
- **THEN** the `name`, `characters`, `patterns`, `kind` and `language` fields SHALL all be accessible
- **AND** its `kind` SHALL be `LevelKind.characters`

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

#### Scenario: Words level carries token patterns
- **WHEN** the English words level is inspected
- **THEN** its `kind` SHALL be `LevelKind.words` and its `wordPatterns` SHALL map every word to its tokens, with a `CharGap` between letters
