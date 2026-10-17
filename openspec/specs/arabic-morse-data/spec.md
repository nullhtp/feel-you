# arabic-morse-data Specification

## Purpose

The Arabic Morse alphabet, its learning order and the data of the Arabic words level.

## Requirements

### Requirement: Complete Arabic Morse alphabet
The Arabic `MorseAlphabet` instance (whose `language` is `MorseLanguage.arabic`) SHALL map each of the 28 Arabic letters to its standard Arabic Morse pattern in a `const` `characters` map of type `Map<String, List<MorseSignal>>`. Each letter uses the pattern of the International Morse letter it corresponds to.

#### Scenario: All 28 Arabic letters are mapped
- **WHEN** a developer queries the Arabic alphabet's `characters` map
- **THEN** it SHALL contain exactly 28 entries, one for each Arabic letter

#### Scenario: Every letter has its standard pattern
- **WHEN** the pattern of each letter is looked up
- **THEN** it SHALL be the following, with the corresponding International Morse letter in brackets:
  - ا (Alif): dot-dash (A)
  - ب (Ba): dash-dot-dot-dot (B)
  - ت (Ta): dash (T)
  - ث (Tha): dash-dot-dash-dot (C)
  - ج (Jim): dot-dash-dash-dash (J)
  - ح (Ha): dot-dot-dot-dot (H)
  - خ (Kha): dash-dash-dash (O)
  - د (Dal): dash-dot-dot (D)
  - ذ (Dhal): dash-dash-dot-dot (Z)
  - ر (Ra): dot-dash-dot (R)
  - ز (Zay): dash-dash-dash-dot (Ö)
  - س (Sin): dot-dot-dot (S)
  - ش (Shin): dash-dash-dash-dash (CH)
  - ص (Sad): dash-dot-dot-dash (X)
  - ض (Dad): dot-dot-dot-dash (V)
  - ط (Taa): dot-dot-dash (U)
  - ظ (Dhaa): dash-dot-dash-dash (Y)
  - ع (Ain): dot-dash-dot-dash (Ä)
  - غ (Ghain): dash-dash-dot (G)
  - ف (Fa): dot-dot-dash-dot (F)
  - ق (Qaf): dash-dash-dot-dash (Q)
  - ك (Kaf): dash-dot-dash (K)
  - ل (Lam): dot-dash-dot-dot (L)
  - م (Mim): dash-dash (M)
  - ن (Nun): dash-dot (N)
  - ه (Ha): dot-dot-dash-dot-dot (É)
  - و (Waw): dot-dash-dash (W)
  - ي (Ya): dot-dot (I)

#### Scenario: Patterns match standard Arabic Morse code
- **WHEN** a developer looks up the pattern for 'ا' (Alif)
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Complex letter pattern is correct
- **WHEN** a developer looks up the pattern for 'ق' (Qaf)
- **THEN** the result SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Map is compile-time constant
- **WHEN** the Arabic alphabet's characters map is defined
- **THEN** it SHALL be declared as `const` and require no runtime initialization

### Requirement: Ordered Arabic letter list
The Arabic `MorseAlphabet` instance's `characterOrder` field SHALL contain all 28 Arabic letters in standard Arabic alphabetical order. This list defines the learning sequence for the Arabic letters level.

#### Scenario: Arabic letters are in standard alphabetical order
- **WHEN** a developer accesses the Arabic alphabet's `characterOrder`
- **THEN** the list SHALL start with 'ا' (Alif) and end with 'ي' (Ya) with all 28 letters in standard Arabic alphabetical order

#### Scenario: Arabic letter list length
- **WHEN** `characterOrder.length` is checked
- **THEN** it SHALL be 28

#### Scenario: Letter at index matches position
- **WHEN** accessing index 0
- **THEN** the letter SHALL be 'ا' (Alif)

### Requirement: Arabic word Morse patterns data
The Arabic `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping each Arabic word to its token pattern: the `Signal` tokens of each letter's Morse signals, with a `CharGap()` token between letters. The patterns SHALL be built with `buildWordPatterns` from the letter patterns plus two aliases with Alif's pattern, أ (hamza on alif) and ى (alif maqsura). The aliases SHALL NOT be in the `characters` map, so decoding stays unambiguous.

#### Scenario: Two-letter Arabic word pattern
- **WHEN** the Arabic alphabet's `wordPatterns!["لا"]` is accessed
- **THEN** it SHALL return the tokens of ل and ا separated by one CharGap: `[Signal(dot), Signal(dash), Signal(dot), Signal(dot), CharGap(), Signal(dot), Signal(dash)]`

#### Scenario: Three-letter Arabic word pattern
- **WHEN** the Arabic alphabet's `wordPatterns!["نعم"]` is accessed
- **THEN** it SHALL return the tokens of ن, ع and م separated by CharGap tokens: `[Signal(dash), Signal(dot), CharGap(), Signal(dot), Signal(dash), Signal(dot), Signal(dash), CharGap(), Signal(dash), Signal(dash)]`

#### Scenario: Hamza on alif uses Alif's pattern
- **WHEN** the Arabic alphabet's `wordPatterns!["ألم"]` is accessed
- **THEN** its first letter's tokens SHALL be Alif's: `[Signal(dot), Signal(dash), CharGap(), ...]`

#### Scenario: Aliases are not letters of the alphabet
- **WHEN** a developer queries the Arabic alphabet's `characters` map for 'أ' or 'ى'
- **THEN** the result SHALL be null

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in the Arabic alphabet's `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

### Requirement: Arabic word list ordering
The Arabic `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 Arabic words chosen for the daily needs of deaf-blind users, grouped by length, shortest first: five each of 2, 3, 4 and 5 letters. In order:
- 2 letters: كل لا نم هل حر
- 3 letters: نعم ألم برد شكر قلب
- 4 letters: سعيد شراب وقوف مريض جالس
- 5 letters: مساعد عطشان جوعان تعبان سلامك

#### Scenario: Arabic word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Arabic word list starts with shortest words
- **WHEN** the first 5 entries of `wordList` are inspected
- **THEN** they SHALL all be 2-letter words

#### Scenario: Arabic word list ends with 5-letter words
- **WHEN** the last 5 entries of `wordList` are inspected
- **THEN** they SHALL all be 5-letter words

#### Scenario: Every Arabic word has a pattern entry
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word

### Requirement: Arabic Morse utilities support
The `encodeLetter` function SHALL return the correct Morse signal pattern for Arabic letter characters when called with `MorseLanguage.arabic`. The `decodePattern` function SHALL return the correct Arabic character for Arabic Morse patterns when called with `MorseLanguage.arabic`.

#### Scenario: Encode an Arabic letter
- **WHEN** `encodeLetter('س', MorseLanguage.arabic)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Decode an Arabic Morse pattern with language context
- **WHEN** `decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.arabic)` is called
- **THEN** the result SHALL be 'ا' (Alif)

#### Scenario: Decode the same pattern in English language context
- **WHEN** `decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.english)` is called
- **THEN** the result SHALL be 'A'
