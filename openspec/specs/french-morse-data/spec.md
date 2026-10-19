# french-morse-data Specification

## Purpose
The French Morse alphabet (A–Z, À, Ç, É and È), its learning order and the data of the French words level.

## Requirements

### Requirement: Complete French Morse alphabet
The French `MorseAlphabet` instance (whose `language` is `MorseLanguage.french`) SHALL map 30 letters to their Morse patterns in its `characters` map: the 26 letters A–Z with the same International Morse patterns as the English alphabet, and the accented letters À, Ç, É and È with their International Morse extension patterns. No two letters SHALL share a pattern, and no letter SHALL have the pattern of a digit.

#### Scenario: All 30 French letters are mapped
- **WHEN** a developer queries the French alphabet's `characters` map
- **THEN** it SHALL contain exactly 30 entries: A–Z, À, Ç, É and È

#### Scenario: A–Z match the English alphabet
- **WHEN** the French and English patterns of any letter A–Z are compared
- **THEN** they SHALL be equal

#### Scenario: Accented letters have their standard patterns
- **WHEN** the pattern of each accented letter is looked up
- **THEN** it SHALL be:
  - À: dot-dash-dash-dot-dash
  - Ç: dash-dot-dash-dot-dot
  - É: dot-dot-dash-dot-dot
  - È: dot-dash-dot-dot-dash

#### Scenario: É pattern is correct
- **WHEN** a developer looks up the pattern for 'É'
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dash, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Letter patterns are unique
- **WHEN** the patterns of the 30 letters and the 10 digits are compared
- **THEN** no two SHALL be equal

### Requirement: Ordered French letter list
The French `MorseAlphabet` instance's `characterOrder` field SHALL contain the 26 letters A–Z in alphabetical order, followed by the accented letters À, Ç, É, È: by their base letter, and É before È as in French dictionary order. French counts 26 letters, so A–Z keep their places and the user can count positions as in their own alphabet. This list defines the learning sequence for the French letters level.

#### Scenario: French letters in learning order
- **WHEN** a developer accesses the French alphabet's `characterOrder`
- **THEN** it SHALL be A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, À, Ç, É, È

#### Scenario: French letter list length
- **WHEN** `characterOrder.length` is checked
- **THEN** it SHALL be 30

#### Scenario: A–Z keep their places
- **WHEN** accessing indices 0 and 25
- **THEN** the letters SHALL be 'A' and 'Z'

#### Scenario: Accented letters follow Z
- **WHEN** accessing indices 26 to 29
- **THEN** the letters SHALL be 'À', 'Ç', 'É' and 'È'

### Requirement: French word Morse patterns data
The French `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping each French word to its token pattern: the `Signal` tokens of each letter's Morse signals, with a `CharGap()` token between letters. The patterns SHALL be built with `buildWordPatterns` from the French `characters` map, never hardcoded.

#### Scenario: Word with Ç
- **WHEN** the French alphabet's `wordPatterns!["ÇA"]` is accessed
- **THEN** it SHALL return `[Signal(dash), Signal(dot), Signal(dash), Signal(dot), Signal(dot), CharGap(), Signal(dot), Signal(dash)]`

#### Scenario: Three-letter French word pattern
- **WHEN** the French alphabet's `wordPatterns!["OUI"]` is accessed
- **THEN** it SHALL return `[Signal(dash), Signal(dash), Signal(dash), CharGap(), Signal(dot), Signal(dot), Signal(dash), CharGap(), Signal(dot), Signal(dot)]`

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in the French alphabet's `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

### Requirement: French word list ordering
The French `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 uppercase French words chosen for the daily needs of deaf-blind users, grouped by length, shortest first: five each of 2, 3, 4 and 5 letters. Every word SHALL be spelled only with letters of the French letters level. The list needs a native-speaker review.

#### Scenario: Complete French word list
- **WHEN** `wordList` is inspected
- **THEN** it SHALL be, in this order:
  - 2 letters: ÇA VA LÀ OK HÉ
  - 3 letters: OUI NON EAU MAL BON
  - 4 letters: AIDE FAIM SOIF BIEN STOP
  - 5 letters: MERCI FROID CHAUD SALUT APRÈS

#### Scenario: French word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: French words are grouped by length
- **WHEN** the entries of `wordList` are inspected in groups of five
- **THEN** the groups SHALL have 2, 3, 4 and 5 letters, in that order

#### Scenario: Words use only letters of the letters level
- **WHEN** every letter of every word in `wordList` is looked up
- **THEN** it SHALL be one of the 30 letters of the French letters level

#### Scenario: Every French word has a pattern entry
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word

### Requirement: French Morse utilities support
The `encodeLetter` function SHALL return the correct Morse signal pattern for French letters, in upper or lower case, when called with `MorseLanguage.french`. The `decodePattern` function SHALL return the correct French letter for French Morse patterns when called with `MorseLanguage.french`.

#### Scenario: Encode É
- **WHEN** `encodeLetter('É', MorseLanguage.french)` or `encodeLetter('é', MorseLanguage.french)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dash, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Decode Ç with language context
- **WHEN** `decodePattern([MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dot, MorseSignal.dot], MorseLanguage.french)` is called
- **THEN** the result SHALL be 'Ç'

#### Scenario: Accented letters are not English letters
- **WHEN** `encodeLetter` is called with À, Ç, É or È and `MorseLanguage.english`
- **THEN** the result SHALL be `null`

#### Scenario: Encode and decode round trip
- **WHEN** each letter of the French `characterOrder` is encoded and its pattern decoded with `MorseLanguage.french`
- **THEN** the decoded letter SHALL be the original letter
