## ADDED Requirements

### Requirement: composeWordPattern produces MorseToken list
The system SHALL provide a `composeWordPattern(String word, Map<String, List<MorseSignal>> alphabet)` function that accepts a word string and an alphabet map, and returns a `List<MorseToken>`. The function SHALL look up each character of the word in the alphabet map and create `Signal` tokens for each `MorseSignal`, inserting a `CharGap()` token between each letter's pattern.

#### Scenario: Two-letter word composition
- **WHEN** `composeWordPattern('IT', morseAlphabet)` is called
- **THEN** it SHALL return `[Signal(dot), Signal(dot), CharGap(), Signal(dash)]`

#### Scenario: Three-letter word composition
- **WHEN** `composeWordPattern('THE', morseAlphabet)` is called
- **THEN** it SHALL return `[Signal(dash), CharGap(), Signal(dot), Signal(dot), Signal(dot), Signal(dot), CharGap(), Signal(dot)]`

#### Scenario: Single-letter word produces no CharGap
- **WHEN** `composeWordPattern('A', morseAlphabet)` is called
- **THEN** it SHALL return `[Signal(dot), Signal(dash)]` with no `CharGap` tokens

#### Scenario: Unknown character throws error
- **WHEN** `composeWordPattern('A1', morseAlphabet)` is called (digit '1' not in letter alphabet)
- **THEN** it SHALL throw an `ArgumentError`

#### Scenario: Empty word throws error
- **WHEN** `composeWordPattern('', morseAlphabet)` is called
- **THEN** it SHALL throw an `ArgumentError`

### Requirement: buildWordPatterns produces MorseToken maps
The system SHALL provide a `buildWordPatterns(List<String> words, Map<String, List<MorseSignal>> alphabet)` function that returns a `Map<String, List<MorseToken>>` mapping each word to its composed token pattern.

#### Scenario: Build patterns for a word list
- **WHEN** `buildWordPatterns(['IT', 'IS'], morseAlphabet)` is called
- **THEN** it SHALL return a map with keys 'IT' and 'IS', where each value equals the result of `composeWordPattern` with that word

#### Scenario: Empty word list returns empty map
- **WHEN** `buildWordPatterns([], morseAlphabet)` is called
- **THEN** it SHALL return an empty map
