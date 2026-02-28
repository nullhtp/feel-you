## MODIFIED Requirements

### Requirement: Ordered levels registry
The system SHALL define a top-level `levels` list containing all available levels in order. The digit level SHALL be at index 0, the letter level SHALL be at index 1, and the words level SHALL be at index 2.

#### Scenario: Levels list contains digits first, letters second, words third
- **WHEN** the `levels` list is inspected
- **THEN** `levels[0].name` SHALL be "digits", `levels[1].name` SHALL be "letters", and `levels[2].name` SHALL be "words"

#### Scenario: Levels list length
- **WHEN** the length of the `levels` list is checked
- **THEN** it SHALL be 3

### Requirement: Words level has 20 characters
The words level SHALL contain 20 entries in its `characters` list and 20 corresponding pattern entries.

#### Scenario: Words level has 20 characters
- **WHEN** `levels[2].characters.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Words level pattern lookup
- **WHEN** `levels[2].patterns["THE"]` is accessed
- **THEN** it SHALL return the Morse pattern for the word "THE" (dash, charGap, dot dot dot dot, charGap, dot)
