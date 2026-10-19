# spanish-morse-data Specification

## Purpose
The Spanish Morse alphabet (A–Z and Ñ), its learning order and the data of the Spanish words level.

## Requirements

### Requirement: Complete Spanish Morse alphabet
The Spanish `MorseAlphabet` instance (whose `language` is `MorseLanguage.spanish`) SHALL map 27 letters to their Morse patterns in its `characters` map: the 26 letters A–Z with the same International Morse patterns as the English alphabet, and Ñ with dash-dash-dot-dash-dash. No two letters SHALL share a pattern, and no letter SHALL have the pattern of a digit. The digits come from the shared digits level.

#### Scenario: All 27 Spanish letters are mapped
- **WHEN** a developer queries the Spanish alphabet's `characters` map
- **THEN** it SHALL contain exactly 27 entries: A–Z and Ñ

#### Scenario: Every letter has its standard pattern
- **WHEN** the pattern of each letter is looked up
- **THEN** it SHALL be:
  - A: dot-dash
  - B: dash-dot-dot-dot
  - C: dash-dot-dash-dot
  - D: dash-dot-dot
  - E: dot
  - F: dot-dot-dash-dot
  - G: dash-dash-dot
  - H: dot-dot-dot-dot
  - I: dot-dot
  - J: dot-dash-dash-dash
  - K: dash-dot-dash
  - L: dot-dash-dot-dot
  - M: dash-dash
  - N: dash-dot
  - Ñ: dash-dash-dot-dash-dash
  - O: dash-dash-dash
  - P: dot-dash-dash-dot
  - Q: dash-dash-dot-dash
  - R: dot-dash-dot
  - S: dot-dot-dot
  - T: dash
  - U: dot-dot-dash
  - V: dot-dot-dot-dash
  - W: dot-dash-dash
  - X: dash-dot-dot-dash
  - Y: dash-dot-dash-dash
  - Z: dash-dash-dot-dot

#### Scenario: A–Z match the English alphabet
- **WHEN** the Spanish and English patterns of any letter A–Z are compared
- **THEN** they SHALL be equal

#### Scenario: Ñ pattern is correct
- **WHEN** a developer looks up the pattern for 'Ñ'
- **THEN** the result SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dash]`

#### Scenario: Letter patterns are unique
- **WHEN** the patterns of the 27 letters and the 10 digits are compared
- **THEN** no two SHALL be equal

### Requirement: Ordered Spanish letter list
The Spanish `MorseAlphabet` instance's `characterOrder` field SHALL contain the 27 letters in Spanish alphabetical order, with Ñ between N and O, as Spanish speakers learn the alphabet. This list defines the learning sequence for the Spanish letters level, so the user can count positions in their own alphabet.

#### Scenario: Spanish letters are in Spanish alphabetical order
- **WHEN** a developer accesses the Spanish alphabet's `characterOrder`
- **THEN** it SHALL be A, B, C, D, E, F, G, H, I, J, K, L, M, N, Ñ, O, P, Q, R, S, T, U, V, W, X, Y, Z

#### Scenario: Spanish letter list length
- **WHEN** `characterOrder.length` is checked
- **THEN** it SHALL be 27

#### Scenario: Ñ is the fifteenth letter
- **WHEN** accessing indices 13, 14 and 15
- **THEN** the letters SHALL be 'N', 'Ñ' and 'O'

#### Scenario: Every letter in the order has a pattern
- **WHEN** iterating through `characterOrder`
- **THEN** `characters[letter]` SHALL be non-null for every letter

### Requirement: Spanish word Morse patterns data
The Spanish `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping each Spanish word to its token pattern: the `Signal` tokens of each letter's Morse signals, with a `CharGap()` token between letters. The patterns SHALL be built with `buildWordPatterns` from the Spanish `characters` map, never hardcoded.

#### Scenario: Two-letter Spanish word pattern
- **WHEN** the Spanish alphabet's `wordPatterns!["NO"]` is accessed
- **THEN** it SHALL return `[Signal(dash), Signal(dot), CharGap(), Signal(dash), Signal(dash), Signal(dash)]`

#### Scenario: Word with Ñ
- **WHEN** the Spanish alphabet's `wordPatterns!["BAÑO"]` is accessed
- **THEN** it SHALL return the tokens of B, A, Ñ and O separated by CharGap tokens: `[Signal(dash), Signal(dot), Signal(dot), Signal(dot), CharGap(), Signal(dot), Signal(dash), CharGap(), Signal(dash), Signal(dash), Signal(dot), Signal(dash), Signal(dash), CharGap(), Signal(dash), Signal(dash), Signal(dash)]`

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in the Spanish alphabet's `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

### Requirement: Spanish word list ordering
The Spanish `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 uppercase Spanish words chosen for the daily needs of deaf-blind users, grouped by length, shortest first: five each of 2, 3, 4 and 5 letters. Every word SHALL be spelled only with letters of the Spanish letters level, so words that need an accented vowel are not used. The list needs a native-speaker review.

#### Scenario: Complete Spanish word list
- **WHEN** `wordList` is inspected
- **THEN** it SHALL be, in this order:
  - 2 letters: NO YA YO VE AY
  - 3 letters: VEN SED MAL PAN VOY
  - 4 letters: HOLA AGUA BAÑO BIEN ALTO
  - 5 letters: AYUDA DOLOR CALOR SUEÑO FELIZ

#### Scenario: Spanish word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Spanish words are grouped by length
- **WHEN** the entries of `wordList` are inspected in groups of five
- **THEN** the groups SHALL have 2, 3, 4 and 5 letters, in that order

#### Scenario: Words use only letters of the letters level
- **WHEN** every letter of every word in `wordList` is looked up
- **THEN** it SHALL be one of the 27 letters of the Spanish letters level

#### Scenario: Every Spanish word has a pattern entry
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word

### Requirement: Spanish Morse utilities support
The `encodeLetter` function SHALL return the correct Morse signal pattern for Spanish letters, in upper or lower case, when called with `MorseLanguage.spanish`. The `decodePattern` function SHALL return the correct Spanish letter for Spanish Morse patterns when called with `MorseLanguage.spanish`.

#### Scenario: Encode Ñ
- **WHEN** `encodeLetter('Ñ', MorseLanguage.spanish)` or `encodeLetter('ñ', MorseLanguage.spanish)` is called
- **THEN** the result SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dash]`

#### Scenario: Decode Ñ with language context
- **WHEN** `decodePattern([MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dash], MorseLanguage.spanish)` is called
- **THEN** the result SHALL be 'Ñ'

#### Scenario: Ñ is not an English letter
- **WHEN** `encodeLetter('Ñ', MorseLanguage.english)` is called, or the pattern of Ñ is decoded with `MorseLanguage.english`
- **THEN** the result SHALL be `null`

#### Scenario: Encode and decode round trip
- **WHEN** each letter of the Spanish `characterOrder` is encoded and its pattern decoded with `MorseLanguage.spanish`
- **THEN** the decoded letter SHALL be the original letter
