### Requirement: Level data model
The system SHALL define a `Level` class containing:
- `name`: A string identifier for the level (e.g., "digits", "letters").
- `characters`: An ordered `List<String>` of characters in the learning sequence.
- `patterns`: A `Map<String, List<MorseSymbol>>` mapping each character to its Morse pattern.

#### Scenario: Level contains all required fields
- **WHEN** a `Level` is created with name "digits", characters ["0"..."9"], and patterns for each digit
- **THEN** the `name`, `characters`, and `patterns` fields SHALL all be accessible

#### Scenario: Characters list defines learning order
- **WHEN** the digits level's `characters` list is inspected
- **THEN** it SHALL be `["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]`

#### Scenario: Pattern lookup by character
- **WHEN** `level.patterns["3"]` is accessed on the digits level
- **THEN** it SHALL return the Morse pattern for digit 3: `[dot, dot, dot, dash, dash]`

### Requirement: Ordered levels registry
The system SHALL define a top-level `levels` list containing all available levels in order. The digit level SHALL be at index 0 and the letter level SHALL be at index 1.

#### Scenario: Levels list contains digits first, letters second
- **WHEN** the `levels` list is inspected
- **THEN** `levels[0].name` SHALL be "digits" and `levels[1].name` SHALL be "letters"

#### Scenario: Levels list length
- **WHEN** the length of the `levels` list is checked
- **THEN** it SHALL be 2

### Requirement: Level provides character count
The system SHALL allow querying the number of characters in a level via its `characters.length` property.

#### Scenario: Digits level has 10 characters
- **WHEN** `levels[0].characters.length` is checked
- **THEN** it SHALL be 10

#### Scenario: Letters level has 26 characters
- **WHEN** `levels[1].characters.length` is checked
- **THEN** it SHALL be 26

### Requirement: Level provides pattern for current position
Given a position index, the system SHALL resolve the character and its Morse pattern from the level data.

#### Scenario: Resolve character at position
- **WHEN** position 3 is looked up in the digits level
- **THEN** the character SHALL be "3" and the pattern SHALL be `[dot, dot, dot, dash, dash]`

#### Scenario: Resolve character at position in letters level
- **WHEN** position 0 is looked up in the letters level
- **THEN** the character SHALL be "A" and the pattern SHALL be `[dot, dash]`
