## Purpose

The German Morse alphabet (A–Z, Ä, Ö and Ü), its learning order and the data of the German words level.

## ADDED Requirements

### Requirement: Complete German Morse alphabet
The German `MorseAlphabet` instance (whose `language` is `MorseLanguage.german`) SHALL map 29 letters to their Morse patterns in its `characters` map: the 26 letters A–Z with the same International Morse patterns as the English alphabet, and the umlauts Ä, Ö and Ü with their International Morse extension patterns. ß SHALL NOT be taught. No two letters SHALL share a pattern, and no letter SHALL have the pattern of a digit.

#### Scenario: All 29 German letters are mapped
- **WHEN** a developer queries the German alphabet's `characters` map
- **THEN** it SHALL contain exactly 29 entries: A–Z, Ä, Ö and Ü

#### Scenario: A–Z match the English alphabet
- **WHEN** the German and English patterns of any letter A–Z are compared
- **THEN** they SHALL be equal

#### Scenario: Umlauts have their standard patterns
- **WHEN** the pattern of each umlaut is looked up
- **THEN** it SHALL be:
  - Ä: dot-dash-dot-dash
  - Ö: dash-dash-dash-dot
  - Ü: dot-dot-dash-dash

#### Scenario: Ö pattern is correct
- **WHEN** a developer looks up the pattern for 'Ö'
- **THEN** the result SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dash, MorseSignal.dot]`

#### Scenario: ß is not taught
- **WHEN** a developer queries the German alphabet's `characters` map for 'ß' or 'ẞ'
- **THEN** the result SHALL be null

#### Scenario: Letter patterns are unique
- **WHEN** the patterns of the 29 letters and the 10 digits are compared
- **THEN** no two SHALL be equal

### Requirement: Ordered German letter list
The German `MorseAlphabet` instance's `characterOrder` field SHALL contain the 26 letters A–Z in alphabetical order, followed by Ä, Ö and Ü, the order in which German alphabet lists add the umlauts after Z. A–Z keep their places, so the user can count positions as in their own alphabet. This list defines the learning sequence for the German letters level.

#### Scenario: German letters in learning order
- **WHEN** a developer accesses the German alphabet's `characterOrder`
- **THEN** it SHALL be A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, Ä, Ö, Ü

#### Scenario: German letter list length
- **WHEN** `characterOrder.length` is checked
- **THEN** it SHALL be 29

#### Scenario: A–Z keep their places
- **WHEN** accessing indices 0 and 25
- **THEN** the letters SHALL be 'A' and 'Z'

#### Scenario: Umlauts follow Z
- **WHEN** accessing indices 26 to 28
- **THEN** the letters SHALL be 'Ä', 'Ö' and 'Ü'

### Requirement: German word Morse patterns data
The German `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping each German word to its token pattern: the `Signal` tokens of each letter's Morse signals, with a `CharGap()` token between letters. The patterns SHALL be built with `buildWordPatterns` from the German `characters` map, never hardcoded.

#### Scenario: Two-letter German word pattern
- **WHEN** the German alphabet's `wordPatterns!["JA"]` is accessed
- **THEN** it SHALL return `[Signal(dot), Signal(dash), Signal(dash), Signal(dash), CharGap(), Signal(dot), Signal(dash)]`

#### Scenario: Word with Ü
- **WHEN** the German alphabet's `wordPatterns!["MÜDE"]` is accessed
- **THEN** it SHALL return `[Signal(dash), Signal(dash), CharGap(), Signal(dot), Signal(dot), Signal(dash), Signal(dash), CharGap(), Signal(dash), Signal(dot), Signal(dot), CharGap(), Signal(dot)]`

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in the German alphabet's `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

### Requirement: German word list ordering
The German `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 uppercase German words chosen for the daily needs of deaf-blind users, grouped by length, shortest first: five each of 2, 3, 4 and 5 letters. Every word SHALL be spelled only with letters of the German letters level. The list needs a native-speaker review.

#### Scenario: Complete German word list
- **WHEN** `wordList` is inspected
- **THEN** it SHALL be, in this order:
  - 2 letters: JA AU DA WO DU
  - 3 letters: GUT WEH KLO GEH AUF
  - 4 letters: NEIN HALT KALT WARM MÜDE
  - 5 letters: HILFE DANKE BITTE HALLO ESSEN

#### Scenario: German word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: German words are grouped by length
- **WHEN** the entries of `wordList` are inspected in groups of five
- **THEN** the groups SHALL have 2, 3, 4 and 5 letters, in that order

#### Scenario: Words use only letters of the letters level
- **WHEN** every letter of every word in `wordList` is looked up
- **THEN** it SHALL be one of the 29 letters of the German letters level

#### Scenario: Every German word has a pattern entry
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word

### Requirement: German Morse utilities support
The `encodeLetter` function SHALL return the correct Morse signal pattern for German letters, in upper or lower case, when called with `MorseLanguage.german`. The `decodePattern` function SHALL return the correct German letter for German Morse patterns when called with `MorseLanguage.german`.

#### Scenario: Encode Ü
- **WHEN** `encodeLetter('Ü', MorseLanguage.german)` or `encodeLetter('ü', MorseLanguage.german)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dash, MorseSignal.dash]`

#### Scenario: Decode Ö with language context
- **WHEN** `decodePattern([MorseSignal.dash, MorseSignal.dash, MorseSignal.dash, MorseSignal.dot], MorseLanguage.german)` is called
- **THEN** the result SHALL be 'Ö'

#### Scenario: ß cannot be encoded
- **WHEN** `encodeLetter('ß', MorseLanguage.german)` is called
- **THEN** the result SHALL be `null`

#### Scenario: Umlauts are not English letters
- **WHEN** `encodeLetter` is called with Ä, Ö or Ü and `MorseLanguage.english`
- **THEN** the result SHALL be `null`

#### Scenario: Encode and decode round trip
- **WHEN** each letter of the German `characterOrder` is encoded and its pattern decoded with `MorseLanguage.german`
- **THEN** the decoded letter SHALL be the original letter
