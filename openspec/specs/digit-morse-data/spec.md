### Requirement: Morse code patterns for digits 0-9
The system SHALL define a `morseDigits` map containing Morse code patterns for all ten digits (0-9). Each digit SHALL map to a `List<MorseSymbol>` representing its standard International Morse Code pattern.

The standard patterns SHALL be:
- 0: dash-dash-dash-dash-dash
- 1: dot-dash-dash-dash-dash
- 2: dot-dot-dash-dash-dash
- 3: dot-dot-dot-dash-dash
- 4: dot-dot-dot-dot-dash
- 5: dot-dot-dot-dot-dot
- 6: dash-dot-dot-dot-dot
- 7: dash-dash-dot-dot-dot
- 8: dash-dash-dash-dot-dot
- 9: dash-dash-dash-dash-dot

#### Scenario: All ten digits have patterns defined
- **WHEN** a developer inspects the `morseDigits` map
- **THEN** it SHALL contain exactly 10 entries, one for each digit "0" through "9"

#### Scenario: Digit patterns follow International Morse Code
- **WHEN** the pattern for "1" is looked up
- **THEN** it SHALL be `[dot, dash, dash, dash, dash]`

#### Scenario: Digit patterns are distinct from letter patterns
- **WHEN** all digit patterns are compared against all letter patterns
- **THEN** no digit pattern SHALL be identical to any letter pattern

### Requirement: Ordered digit list for learning sequence
The system SHALL define a `morseDigitsList` containing all ten digits as strings in order from "0" to "9". This list defines the learning sequence within the digit level.

#### Scenario: Digit list is ordered 0-9
- **WHEN** a developer inspects the `morseDigitsList`
- **THEN** it SHALL contain `["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]`

#### Scenario: Digit list length
- **WHEN** the length of `morseDigitsList` is checked
- **THEN** it SHALL be 10

### Requirement: Morse utilities support digits
The `encodeLetter` function SHALL return the correct Morse pattern for digit characters. The `decodePattern` function SHALL return the correct digit string for digit Morse patterns. The `isValidPattern` function SHALL accept digit patterns as valid.

#### Scenario: Encode a digit
- **WHEN** `encodeLetter("5")` is called
- **THEN** it SHALL return `[dot, dot, dot, dot, dot]`

#### Scenario: Decode a digit pattern
- **WHEN** `decodePattern([dash, dash, dash, dash, dash])` is called
- **THEN** it SHALL return `"0"`

#### Scenario: Digit patterns are valid
- **WHEN** `isValidPattern([dot, dash, dash, dash, dash])` is called
- **THEN** it SHALL return `true`
