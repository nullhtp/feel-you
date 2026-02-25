### Requirement: Morse symbol representation
The system SHALL represent Morse code using a `MorseSymbol` enum with exactly two values: `dot` and `dash`. All Morse-related APIs SHALL use this enum — not strings, characters, or integers — to represent individual symbols.

#### Scenario: Enum has exactly two values
- **WHEN** a developer inspects the `MorseSymbol` enum
- **THEN** it contains exactly `dot` and `dash` as values

#### Scenario: Type safety prevents invalid symbols
- **WHEN** a developer attempts to pass a non-MorseSymbol value to a Morse API
- **THEN** the Dart type system rejects the code at compile time

### Requirement: Complete A-Z Morse alphabet
The system SHALL provide a compile-time constant mapping from every uppercase letter A through Z to its standard International Morse Code pattern (a list of `MorseSymbol` values). The mapping SHALL cover all 26 letters with no omissions.

#### Scenario: All 26 letters are mapped
- **WHEN** a developer queries the Morse alphabet
- **THEN** entries exist for every letter from A to Z (26 total)

#### Scenario: Patterns match International Morse Code
- **WHEN** a developer looks up the pattern for letter 'A'
- **THEN** the result is `[dot, dash]`

#### Scenario: Patterns match International Morse Code for complex letters
- **WHEN** a developer looks up the pattern for letter 'Q'
- **THEN** the result is `[dash, dash, dot, dash]`

#### Scenario: Map is compile-time constant
- **WHEN** the Morse alphabet map is defined
- **THEN** it is declared as `const` and requires no runtime initialization

### Requirement: Letter-to-pattern encoding
The system SHALL provide a function to encode a single letter (A-Z, case-insensitive) into its Morse pattern. The function SHALL return `null` for any input that is not a letter A-Z.

#### Scenario: Encode uppercase letter
- **WHEN** encoding the letter 'S'
- **THEN** the result is `[dot, dot, dot]`

#### Scenario: Encode lowercase letter
- **WHEN** encoding the letter 's'
- **THEN** the result is `[dot, dot, dot]`

#### Scenario: Encode non-letter character
- **WHEN** encoding the character '5'
- **THEN** the result is `null`

#### Scenario: Encode empty string
- **WHEN** encoding an empty string
- **THEN** the result is `null`

### Requirement: Pattern-to-letter decoding
The system SHALL provide a function to decode a list of `MorseSymbol` values back to the corresponding letter. The function SHALL return `null` if the pattern does not match any letter A-Z.

#### Scenario: Decode valid pattern
- **WHEN** decoding `[dot, dash]`
- **THEN** the result is 'A'

#### Scenario: Decode invalid pattern
- **WHEN** decoding `[dot, dot, dot, dot, dot]` (no letter has 5 dots)
- **THEN** the result is `null`

#### Scenario: Decode empty list
- **WHEN** decoding an empty list
- **THEN** the result is `null`

### Requirement: Pattern validation
The system SHALL provide a function to check whether a list of `MorseSymbol` values is a valid Morse pattern for any letter A-Z.

#### Scenario: Valid pattern
- **WHEN** validating `[dash, dot, dash, dot]` (C)
- **THEN** the result is `true`

#### Scenario: Invalid pattern
- **WHEN** validating `[dash, dash, dash, dash, dash]` (no letter matches)
- **THEN** the result is `false`

#### Scenario: Empty pattern
- **WHEN** validating an empty list
- **THEN** the result is `false`

### Requirement: Ordered letter list
The system SHALL provide a list of all 26 letters in alphabetical order (A to Z) for sequential navigation. This list defines the learning order.

#### Scenario: Letters are in alphabetical order
- **WHEN** a developer accesses the letter list
- **THEN** the list starts with 'A' and ends with 'Z' with all 26 letters in order

#### Scenario: Letter at index matches position
- **WHEN** accessing index 0
- **THEN** the letter is 'A'
