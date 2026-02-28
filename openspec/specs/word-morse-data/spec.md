### Requirement: MorseSymbol charGap value
The `MorseSymbol` enum SHALL include a `charGap` value in addition to `dot` and `dash`. The `charGap` value represents the inter-character silence within a multi-character word pattern.

#### Scenario: MorseSymbol has three values
- **WHEN** the `MorseSymbol` enum is inspected
- **THEN** it SHALL contain exactly three values: `dot`, `dash`, and `charGap`

#### Scenario: charGap is distinct from dot and dash
- **WHEN** comparing `MorseSymbol.charGap` to `MorseSymbol.dot` and `MorseSymbol.dash`
- **THEN** all three values SHALL be distinct

### Requirement: Word Morse patterns data file
The system SHALL define a `morseWords` constant map of type `Map<String, List<MorseSymbol>>` mapping uppercase word strings to their flat Morse patterns. Each word's pattern SHALL concatenate the Morse patterns of its component letters, separated by `MorseSymbol.charGap` values between each letter.

#### Scenario: Two-letter word pattern
- **WHEN** `morseWords["IT"]` is accessed
- **THEN** it SHALL return `[dot, dot, charGap, dash]` (I = dot dot, T = dash, separated by charGap)

#### Scenario: Three-letter word pattern
- **WHEN** `morseWords["THE"]` is accessed
- **THEN** it SHALL return `[dash, charGap, dot, dot, dot, dot, charGap, dot]` (T = dash, H = dot dot dot dot, E = dot)

#### Scenario: All patterns use charGap between letters
- **WHEN** any word pattern in `morseWords` is inspected
- **THEN** `charGap` symbols SHALL appear between each letter's Morse symbols and SHALL NOT appear at the start or end of the pattern

### Requirement: Word list ordering
The system SHALL define a `morseWordsList` constant of type `List<String>` containing exactly 20 common English words. Words SHALL be sorted primarily by length (shortest first, 2-5 letters) and secondarily by usage frequency (most common first within each length group).

#### Scenario: Word list contains exactly 20 words
- **WHEN** `morseWordsList.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Word list starts with 2-letter words
- **WHEN** the first 5 entries of `morseWordsList` are inspected
- **THEN** they SHALL all be 2-letter words

#### Scenario: Word list ends with 5-letter words
- **WHEN** the last 5 entries of `morseWordsList` are inspected
- **THEN** they SHALL all be 5-letter words

#### Scenario: Words within same length are sorted by frequency
- **WHEN** the 2-letter words in `morseWordsList` are inspected
- **THEN** they SHALL be ordered by English usage frequency (most common first)

### Requirement: Word list content
The `morseWordsList` SHALL contain the following 20 words in this order:
- 2-letter: IT, IS, TO, IN, AT
- 3-letter: THE, AND, FOR, ARE, BUT
- 4-letter: THAT, WITH, HAVE, THIS, FROM
- 5-letter: THEIR, ABOUT, WHICH, WOULD, THERE

#### Scenario: Complete word list verification
- **WHEN** `morseWordsList` is inspected
- **THEN** it SHALL equal `["IT", "IS", "TO", "IN", "AT", "THE", "AND", "FOR", "ARE", "BUT", "THAT", "WITH", "HAVE", "THIS", "FROM", "THEIR", "ABOUT", "WHICH", "WOULD", "THERE"]`

### Requirement: Every word has a pattern entry
Every word in `morseWordsList` SHALL have a corresponding entry in the `morseWords` map.

#### Scenario: All words have patterns
- **WHEN** iterating through `morseWordsList`
- **THEN** `morseWords[word]` SHALL be non-null for every word
