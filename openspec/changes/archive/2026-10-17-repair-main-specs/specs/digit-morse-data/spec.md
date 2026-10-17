## MODIFIED Requirements

### Requirement: Morse code patterns for digits 0-9
The system SHALL define digit Morse code patterns within a universal `MorseAlphabet` instance (where `language` is `null`). The `characters` map SHALL contain patterns for all ten digits (0-9), each mapping to a `List<MorseSignal>` representing its standard International Morse Code pattern.

#### Scenario: All ten digits have patterns defined
- **WHEN** a developer inspects the digits alphabet's `characters` map
- **THEN** it SHALL contain exactly 10 entries, one for each digit "0" through "9"

#### Scenario: Every digit has its standard pattern
- **WHEN** the pattern of each digit is looked up
- **THEN** it SHALL be:
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

#### Scenario: Digit patterns follow International Morse Code
- **WHEN** the pattern for "1" is looked up
- **THEN** it SHALL be `[MorseSignal.dot, MorseSignal.dash, MorseSignal.dash, MorseSignal.dash, MorseSignal.dash]`

#### Scenario: Digit patterns are distinct from letter patterns
- **WHEN** all digit patterns are compared against all English letter patterns
- **THEN** no digit pattern SHALL be identical to any letter pattern
