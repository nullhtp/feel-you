## MODIFIED Requirements

### Requirement: MorseAlphabet data class
The system SHALL define a `MorseAlphabet` class with: `language` (`MorseLanguage?`, `null` for a universal alphabet such as digits, which every language includes), `characters` (each character's `List<MorseSignal>` pattern), `characterOrder` (the learning sequence), `wordList` and `wordPatterns` (the words and their `List<MorseToken>` patterns, both `null` when the alphabet has no words level) and `levels` (the `List<Level>` the alphabet defines).

#### Scenario: Universal alphabet has null language
- **WHEN** the digits `MorseAlphabet` is inspected
- **THEN** its `language` field SHALL be `null`

#### Scenario: Language-specific alphabet has language set
- **WHEN** the English `MorseAlphabet` is inspected
- **THEN** its `language` field SHALL be `MorseLanguage.english`

#### Scenario: Alphabet characters map is accessible
- **WHEN** the English alphabet's `characters` map is queried for 'A'
- **THEN** it SHALL return `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Character order defines learning sequence
- **WHEN** the English alphabet's `characterOrder` is inspected
- **THEN** it SHALL start with 'A' and end with 'Z' with all 26 letters in order

#### Scenario: Alphabet with words has wordList and wordPatterns
- **WHEN** the English alphabet is inspected
- **THEN** `wordList` SHALL be a list of 20 words and `wordPatterns` SHALL map each word to its token pattern

#### Scenario: Alphabet without words has null wordList
- **WHEN** the digits alphabet is inspected
- **THEN** `wordList` SHALL be `null` and `wordPatterns` SHALL be `null`
