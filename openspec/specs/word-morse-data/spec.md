# word-morse-data Specification

## Purpose

The English words level: the word list, its order and the word token patterns.

## Requirements

### Requirement: MorseToken charGap representation
The `MorseToken` sealed class SHALL include a `CharGap` subtype representing the inter-character silence within a multi-character word pattern. The `charGap` concept SHALL NOT exist in `MorseSignal`.

#### Scenario: MorseSignal has only two values
- **WHEN** `MorseSignal.values` is inspected
- **THEN** it SHALL contain exactly two values: `dot` and `dash`

#### Scenario: CharGap is a MorseToken subtype
- **WHEN** a `CharGap()` instance is created
- **THEN** it SHALL be a valid `MorseToken`

### Requirement: Word Morse patterns data
The English `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping each uppercase word to its token pattern: the `Signal` tokens of each letter's Morse signals, with a `CharGap()` token between letters. The patterns SHALL be computed at runtime with `buildWordPatterns(wordList, characters)` from the same alphabet's letter patterns, never hardcoded.

#### Scenario: Two-letter word pattern
- **WHEN** the English alphabet's `wordPatterns!["HI"]` is accessed
- **THEN** it SHALL return `[Signal(dot), Signal(dot), Signal(dot), Signal(dot), CharGap(), Signal(dot), Signal(dot)]`

#### Scenario: Three-letter word pattern
- **WHEN** the English alphabet's `wordPatterns!["YES"]` is accessed
- **THEN** it SHALL return `[Signal(dash), Signal(dot), Signal(dash), Signal(dash), CharGap(), Signal(dot), CharGap(), Signal(dot), Signal(dot), Signal(dot)]`

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

#### Scenario: Patterns are derived from characters map
- **WHEN** the English alphabet is initialized
- **THEN** every word's pattern SHALL be computed from the alphabet's `characters` map using `buildWordPatterns`, not hardcoded

### Requirement: Word list ordering
The English `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 English words chosen for the daily needs of deaf-blind users, grouped by length, shortest first: five each of 2, 3, 4 and 5 letters.

#### Scenario: Word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Word list starts with 2-letter words
- **WHEN** the first 5 entries of `wordList` are inspected
- **THEN** they SHALL all be 2-letter words

#### Scenario: Word list ends with 5-letter words
- **WHEN** the last 5 entries of `wordList` are inspected
- **THEN** they SHALL all be 5-letter words

### Requirement: Word list content
The English alphabet's `wordList` SHALL contain the following 20 words in this order:
- 2-letter: HI, OK, NO, GO, UP
- 3-letter: YES, EAT, HOT, SIT, BAD
- 4-letter: HELP, COLD, PAIN, GOOD, STOP
- 5-letter: WATER, HAPPY, TIRED, SORRY, THANK

#### Scenario: Complete word list verification
- **WHEN** `wordList` is inspected
- **THEN** it SHALL equal `["HI", "OK", "NO", "GO", "UP", "YES", "EAT", "HOT", "SIT", "BAD", "HELP", "COLD", "PAIN", "GOOD", "STOP", "WATER", "HAPPY", "TIRED", "SORRY", "THANK"]`

### Requirement: Every word has a pattern entry
Every word in `wordList` SHALL have a corresponding entry in the `wordPatterns` map.

#### Scenario: All words have patterns
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word
