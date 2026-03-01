## MODIFIED Requirements

### Requirement: composeWordPattern utility function
The system SHALL provide a `composeWordPattern` function that accepts a word string and an alphabet map (`Map<String, List<MorseSignal>>`), and returns a `List<MorseToken>`. The function SHALL look up each character of the word in the alphabet map and create `Signal` tokens for each `MorseSignal`, inserting a `CharGap()` token between each letter's pattern.

#### Scenario: Two-letter English word composition
- **WHEN** `composeWordPattern('IT', morseAlphabet)` is called
- **THEN** it SHALL return `[Signal(dot), Signal(dot), CharGap(), Signal(dash)]`

#### Scenario: Three-letter English word composition
- **WHEN** `composeWordPattern('THE', morseAlphabet)` is called
- **THEN** it SHALL return `[Signal(dash), CharGap(), Signal(dot), Signal(dot), Signal(dot), Signal(dot), CharGap(), Signal(dot)]`

#### Scenario: Single-letter word produces no CharGap
- **WHEN** `composeWordPattern('A', morseAlphabet)` is called
- **THEN** it SHALL return `[Signal(dot), Signal(dash)]` with no `CharGap` tokens

#### Scenario: Pattern uses the provided alphabet map
- **WHEN** `composeWordPattern` is called with a custom alphabet map `{'X': [MorseSignal.dot], 'Y': [MorseSignal.dash]}`
- **THEN** `composeWordPattern('XY', customMap)` SHALL return `[Signal(dot), CharGap(), Signal(dash)]`

### Requirement: composeWordPattern character not found behavior
The `composeWordPattern` function SHALL throw an `ArgumentError` if any character in the word is not found in the provided alphabet map.

#### Scenario: Unknown character throws error
- **WHEN** `composeWordPattern('A1', morseAlphabet)` is called (digit '1' is not in `morseAlphabet`)
- **THEN** it SHALL throw an `ArgumentError`

### Requirement: composeWordPattern empty word behavior
The `composeWordPattern` function SHALL throw an `ArgumentError` when called with an empty string.

#### Scenario: Empty word throws error
- **WHEN** `composeWordPattern('', morseAlphabet)` is called
- **THEN** it SHALL throw an `ArgumentError`

### Requirement: buildWordPatterns batch utility function
The system SHALL provide a `buildWordPatterns` function that accepts a list of word strings and an alphabet map (`Map<String, List<MorseSignal>>`), and returns a `Map<String, List<MorseToken>>` mapping each word to its composed token pattern. It SHALL call `composeWordPattern` for each word.

#### Scenario: Build patterns for a word list
- **WHEN** `buildWordPatterns(['IT', 'IS'], morseAlphabet)` is called
- **THEN** it SHALL return a map with keys 'IT' and 'IS', where each value equals the result of calling `composeWordPattern` with that word

#### Scenario: Empty word list returns empty map
- **WHEN** `buildWordPatterns([], morseAlphabet)` is called
- **THEN** it SHALL return an empty map
