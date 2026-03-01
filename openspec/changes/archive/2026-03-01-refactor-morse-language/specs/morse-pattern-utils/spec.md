## ADDED Requirements

### Requirement: Pattern equality comparison
The system SHALL provide a `patternsEqual(List<MorseSignal> a, List<MorseSignal> b)` function in a dedicated pattern utilities module that returns `true` if the two signal patterns contain the same signals in the same order.

#### Scenario: Equal patterns
- **WHEN** `patternsEqual([MorseSignal.dot, MorseSignal.dash], [MorseSignal.dot, MorseSignal.dash])` is called
- **THEN** the result SHALL be `true`

#### Scenario: Unequal patterns
- **WHEN** `patternsEqual([MorseSignal.dot], [MorseSignal.dash])` is called
- **THEN** the result SHALL be `false`

#### Scenario: Different length patterns
- **WHEN** `patternsEqual([MorseSignal.dot], [MorseSignal.dot, MorseSignal.dash])` is called
- **THEN** the result SHALL be `false`

#### Scenario: Empty patterns
- **WHEN** `patternsEqual([], [])` is called
- **THEN** the result SHALL be `true`

### Requirement: Pattern validation
The system SHALL provide an `isValidPattern(List<MorseSignal> pattern, MorseLanguage language)` function that returns `true` if the pattern matches any known character in the universal or language-specific alphabet.

#### Scenario: Valid English letter pattern
- **WHEN** `isValidPattern([MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dot], MorseLanguage.english)` is called (C)
- **THEN** the result SHALL be `true`

#### Scenario: Invalid pattern
- **WHEN** `isValidPattern([MorseSignal.dash, MorseSignal.dash, MorseSignal.dash, MorseSignal.dash, MorseSignal.dash], MorseLanguage.english)` is called (no English letter matches, but this is digit 0)
- **THEN** the result SHALL be `true` (matches digit 0 in universal alphabet)

#### Scenario: Empty pattern is invalid
- **WHEN** `isValidPattern([], MorseLanguage.english)` is called
- **THEN** the result SHALL be `false`

### Requirement: Token-level pattern equality
The system SHALL provide a `tokenPatternsEqual(List<MorseToken> a, List<MorseToken> b)` function for comparing word-level patterns that include `CharGap` tokens.

#### Scenario: Equal token patterns
- **WHEN** comparing `[Signal(dot), Signal(dot), CharGap(), Signal(dash)]` with `[Signal(dot), Signal(dot), CharGap(), Signal(dash)]`
- **THEN** the result SHALL be `true`

#### Scenario: Different token patterns
- **WHEN** comparing `[Signal(dot), CharGap(), Signal(dash)]` with `[Signal(dot), Signal(dash)]`
- **THEN** the result SHALL be `false`
