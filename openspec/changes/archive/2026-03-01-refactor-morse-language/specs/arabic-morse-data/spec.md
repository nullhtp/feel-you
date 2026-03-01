## MODIFIED Requirements

### Requirement: Complete Arabic Morse alphabet
The system SHALL define Arabic Morse code patterns within an Arabic `MorseAlphabet` instance (where `language` is `MorseLanguage.arabic`). The `characters` map SHALL be of type `Map<String, List<MorseSignal>>` containing all 28 Arabic letters mapped to their standard Arabic Morse code patterns.

The standard Arabic Morse code patterns SHALL be:
- ا (Alif): dot-dash
- ب (Ba): dash-dot-dot-dot
- ت (Ta): dash
- ث (Tha): dash-dot-dash-dot
- ج (Jim): dot-dash-dash-dash
- ح (Ha): dot-dot-dot-dot
- خ (Kha): dash-dash-dash
- د (Dal): dash-dot-dot
- ذ (Dhal): dash-dash-dot-dot
- ر (Ra): dot-dash-dot
- ز (Zay): dash-dash-dash-dot
- س (Sin): dot-dot-dot
- ش (Shin): dash-dash-dash-dash
- ص (Sad): dot-dot-dot-dash
- ض (Dad): dot-dot-dash-dot
- ط (Taa): dot-dot-dash
- ظ (Dhaa): dot-dash-dot-dot
- ع (Ain): dot-dash-dash
- غ (Ghain): dash-dash-dot
- ف (Fa): dot-dot-dash-dot
- ق (Qaf): dash-dash-dot-dash
- ك (Kaf): dash-dot-dash
- ل (Lam): dot-dash-dot-dot
- م (Mim): dash-dash
- ن (Nun): dash-dot
- ه (Ha): dot-dot
- و (Waw): dot-dash-dash
- ي (Ya): dot-dot-dash-dash

#### Scenario: All 28 Arabic letters are mapped
- **WHEN** a developer queries the Arabic alphabet's `characters` map
- **THEN** it SHALL contain exactly 28 entries, one for each Arabic letter

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
The Arabic `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping Arabic word strings to their token patterns. Each word's pattern SHALL concatenate `Signal` tokens for each letter's Morse signals, separated by `CharGap()` tokens between each letter.

#### Scenario: Two-letter Arabic word pattern
- **WHEN** the Arabic alphabet's `wordPatterns["في"]` is accessed
- **THEN** it SHALL return the concatenated token pattern for ف and ي separated by CharGap

#### Scenario: Three-letter Arabic word pattern
- **WHEN** the Arabic alphabet's `wordPatterns["من"]` is accessed
- **THEN** it SHALL return the concatenated token pattern for م and ن separated by CharGap

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in the Arabic alphabet's `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

### Requirement: Arabic word list ordering
The Arabic `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 common Arabic words sorted primarily by length (shortest first) and secondarily by usage frequency.

#### Scenario: Arabic word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Arabic word list starts with shortest words
- **WHEN** the first entries of `wordList` are inspected
- **THEN** they SHALL be the shortest words, ordered by frequency

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
