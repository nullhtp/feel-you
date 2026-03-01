## MODIFIED Requirements

### Requirement: MorseToken charGap representation
The `MorseToken` sealed class SHALL include a `CharGap` subtype representing the inter-character silence within a multi-character word pattern. The `charGap` concept SHALL NOT exist in `MorseSignal`.

#### Scenario: MorseSignal has only two values
- **WHEN** `MorseSignal.values` is inspected
- **THEN** it SHALL contain exactly two values: `dot` and `dash`

#### Scenario: CharGap is a MorseToken subtype
- **WHEN** a `CharGap()` instance is created
- **THEN** it SHALL be a valid `MorseToken`

### Requirement: Word Morse patterns data
The English `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping uppercase word strings to their token patterns. The patterns SHALL be computed at runtime by calling `buildWordPatterns(wordList, characters)` using the letter patterns from the same alphabet. Each word's pattern SHALL concatenate `Signal` tokens for each letter's Morse signals, separated by `CharGap()` tokens between each letter. The `wordPatterns` map SHALL NOT contain hardcoded pattern values.

#### Scenario: Two-letter word pattern
- **WHEN** the English alphabet's `wordPatterns!["IT"]` is accessed
- **THEN** it SHALL return `[Signal(dot), Signal(dot), CharGap(), Signal(dash)]`

#### Scenario: Three-letter word pattern
- **WHEN** the English alphabet's `wordPatterns!["THE"]` is accessed
- **THEN** it SHALL return `[Signal(dash), CharGap(), Signal(dot), Signal(dot), Signal(dot), Signal(dot), CharGap(), Signal(dot)]`

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

#### Scenario: Patterns are derived from characters map
- **WHEN** the English alphabet is initialized
- **THEN** every word's pattern SHALL be computed from the alphabet's `characters` map using `buildWordPatterns`, not hardcoded

### Requirement: Word list ordering
The English `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 common English words sorted primarily by length (shortest first, 2-5 letters) and secondarily by usage frequency.

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
- 2-letter: IT, IS, TO, IN, AT
- 3-letter: THE, AND, FOR, ARE, BUT
- 4-letter: THAT, WITH, HAVE, THIS, FROM
- 5-letter: THEIR, ABOUT, WHICH, WOULD, THERE

#### Scenario: Complete word list verification
- **WHEN** `wordList` is inspected
- **THEN** it SHALL equal `["IT", "IS", "TO", "IN", "AT", "THE", "AND", "FOR", "ARE", "BUT", "THAT", "WITH", "HAVE", "THIS", "FROM", "THEIR", "ABOUT", "WHICH", "WOULD", "THERE"]`

### Requirement: Every word has a pattern entry
Every word in `wordList` SHALL have a corresponding entry in the `wordPatterns` map.

#### Scenario: All words have patterns
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word
