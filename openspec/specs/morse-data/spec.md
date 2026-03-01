## MODIFIED Requirements

### Requirement: Morse symbol representation
The system SHALL represent Morse code signals using a `MorseSignal` enum with exactly two values: `dot` and `dash`. All Morse-related APIs SHALL use this enum — not strings, characters, integers, or the former `MorseSymbol` — to represent individual signals.

#### Scenario: Enum has exactly two values
- **WHEN** a developer inspects the `MorseSignal` enum
- **THEN** it SHALL contain exactly `dot` and `dash` as values

#### Scenario: Type safety prevents invalid signals
- **WHEN** a developer attempts to pass a non-MorseSignal value to a Morse API
- **THEN** the Dart type system SHALL reject the code at compile time

### Requirement: Complete A-Z Morse alphabet
The system SHALL provide a compile-time constant mapping from every uppercase letter A through Z to its standard International Morse Code pattern (a list of `MorseSignal` values). The mapping SHALL cover all 26 letters with no omissions. This mapping SHALL be defined within the English `MorseAlphabet` instance's `characters` field.

#### Scenario: All 26 letters are mapped
- **WHEN** a developer queries the English alphabet's `characters` map
- **THEN** entries SHALL exist for every letter from A to Z (26 total)

#### Scenario: Patterns match International Morse Code
- **WHEN** a developer looks up the pattern for letter 'A'
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Patterns match International Morse Code for complex letters
- **WHEN** a developer looks up the pattern for letter 'Q'
- **THEN** the result SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Map is compile-time constant
- **WHEN** the English alphabet's characters map is defined
- **THEN** it SHALL be declared as `const` and require no runtime initialization

### Requirement: Letter-to-pattern encoding
The system SHALL provide a function to encode a single letter (A-Z, case-insensitive) into its Morse signal pattern, requiring a `MorseLanguage` parameter. The function SHALL return `null` for any input that is not a recognized character in the specified language's alphabet or the universal (digits) alphabet.

#### Scenario: Encode uppercase letter
- **WHEN** encoding the letter 'S' with `MorseLanguage.english`
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Encode lowercase letter
- **WHEN** encoding the letter 's' with `MorseLanguage.english`
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Encode non-letter character
- **WHEN** encoding the character '5' with `MorseLanguage.english`
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]` (digit found in universal alphabet)

#### Scenario: Encode empty string
- **WHEN** encoding an empty string
- **THEN** the result SHALL be `null`

### Requirement: Pattern-to-letter decoding
The system SHALL provide a function to decode a list of `MorseSignal` values back to the corresponding character, requiring a `MorseLanguage` parameter. The function SHALL return `null` if the pattern does not match any character in the specified language's alphabet or the universal alphabet.

#### Scenario: Decode valid pattern
- **WHEN** decoding `[MorseSignal.dot, MorseSignal.dash]` with `MorseLanguage.english`
- **THEN** the result SHALL be 'A'

#### Scenario: Decode invalid pattern
- **WHEN** decoding a pattern that matches no known character
- **THEN** the result SHALL be `null`

#### Scenario: Decode empty list
- **WHEN** decoding an empty list
- **THEN** the result SHALL be `null`

### Requirement: Pattern validation
The system SHALL provide a function to check whether a list of `MorseSignal` values is a valid Morse pattern for any character in the specified language's alphabet or the universal alphabet. A `MorseLanguage` parameter SHALL be required.

#### Scenario: Valid pattern
- **WHEN** validating `[MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dot]` with `MorseLanguage.english` (C)
- **THEN** the result SHALL be `true`

#### Scenario: Invalid pattern
- **WHEN** validating a pattern that matches no known character
- **THEN** the result SHALL be `false`

#### Scenario: Empty pattern
- **WHEN** validating an empty list
- **THEN** the result SHALL be `false`

### Requirement: Ordered letter list
The system SHALL provide a list of all 26 letters in alphabetical order (A to Z) for sequential navigation via the English `MorseAlphabet` instance's `characterOrder` field. This list defines the learning order.

#### Scenario: Letters are in alphabetical order
- **WHEN** a developer accesses the English alphabet's `characterOrder`
- **THEN** the list SHALL start with 'A' and end with 'Z' with all 26 letters in order

#### Scenario: Letter at index matches position
- **WHEN** accessing index 0
- **THEN** the letter SHALL be 'A'
