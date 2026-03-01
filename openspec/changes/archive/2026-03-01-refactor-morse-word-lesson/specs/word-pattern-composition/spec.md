## ADDED Requirements

### Requirement: composeWordPattern utility function
The system SHALL provide a `composeWordPattern` function in `morse_utils.dart` that accepts a word string and an alphabet map (`Map<String, List<MorseSymbol>>`), and returns the composed flat Morse pattern for that word. The function SHALL look up each character of the word in the alphabet map and concatenate the resulting patterns, inserting a `MorseSymbol.charGap` between each letter's pattern.

#### Scenario: Two-letter English word composition
- **WHEN** `composeWordPattern('IT', morseAlphabet)` is called
- **THEN** it SHALL return `[dot, dot, charGap, dash]` (I=dot,dot + charGap + T=dash)

#### Scenario: Three-letter English word composition
- **WHEN** `composeWordPattern('THE', morseAlphabet)` is called
- **THEN** it SHALL return `[dash, charGap, dot, dot, dot, dot, charGap, dot]` (T=dash + charGap + H=dot,dot,dot,dot + charGap + E=dot)

#### Scenario: Single-letter word produces no charGap
- **WHEN** `composeWordPattern('A', morseAlphabet)` is called
- **THEN** it SHALL return `[dot, dash]` with no `charGap` symbols

#### Scenario: Pattern uses the provided alphabet map
- **WHEN** `composeWordPattern` is called with a custom alphabet map `{'X': [dot], 'Y': [dash]}`
- **THEN** `composeWordPattern('XY', customMap)` SHALL return `[dot, charGap, dash]`

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
The system SHALL provide a `buildWordPatterns` function in `morse_utils.dart` that accepts a list of word strings and an alphabet map, and returns a `Map<String, List<MorseSymbol>>` mapping each word to its composed pattern. It SHALL call `composeWordPattern` for each word.

#### Scenario: Build patterns for a word list
- **WHEN** `buildWordPatterns(['IT', 'IS'], morseAlphabet)` is called
- **THEN** it SHALL return a map with keys `'IT'` and `'IS'`, where each value equals the result of calling `composeWordPattern` with that word

#### Scenario: Empty word list returns empty map
- **WHEN** `buildWordPatterns([], morseAlphabet)` is called
- **THEN** it SHALL return an empty map
