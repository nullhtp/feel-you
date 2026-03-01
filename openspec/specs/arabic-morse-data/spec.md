## ADDED Requirements

### Requirement: Complete Arabic Morse alphabet
The system SHALL provide a compile-time constant mapping `morseArabicAlphabet` of type `Map<String, List<MorseSymbol>>` from every Arabic letter to its standard Arabic Morse code pattern. The mapping SHALL cover all 28 Arabic letters with no omissions.

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
- **WHEN** a developer queries the `morseArabicAlphabet` map
- **THEN** it SHALL contain exactly 28 entries, one for each Arabic letter

#### Scenario: Patterns match standard Arabic Morse code
- **WHEN** a developer looks up the pattern for 'ا' (Alif)
- **THEN** the result SHALL be `[dot, dash]`

#### Scenario: Complex letter pattern is correct
- **WHEN** a developer looks up the pattern for 'ق' (Qaf)
- **THEN** the result SHALL be `[dash, dash, dot, dash]`

#### Scenario: Map is compile-time constant
- **WHEN** the `morseArabicAlphabet` map is defined
- **THEN** it SHALL be declared as `const` and require no runtime initialization

### Requirement: Ordered Arabic letter list
The system SHALL provide a compile-time constant list `morseArabicLetters` of type `List<String>` containing all 28 Arabic letters in standard Arabic alphabetical order. This list defines the learning sequence for the Arabic letters level.

#### Scenario: Arabic letters are in standard alphabetical order
- **WHEN** a developer accesses `morseArabicLetters`
- **THEN** the list SHALL start with 'ا' (Alif) and end with 'ي' (Ya) with all 28 letters in standard Arabic alphabetical order

#### Scenario: Arabic letter list length
- **WHEN** `morseArabicLetters.length` is checked
- **THEN** it SHALL be 28

#### Scenario: Letter at index matches position
- **WHEN** accessing index 0
- **THEN** the letter SHALL be 'ا' (Alif)

### Requirement: Arabic word Morse patterns data file
The system SHALL define a `morseArabicWords` constant map of type `Map<String, List<MorseSymbol>>` mapping Arabic word strings to their flat Morse patterns. Each word's pattern SHALL concatenate the Morse patterns of its component letters, separated by `MorseSymbol.charGap` values between each letter.

#### Scenario: Two-letter Arabic word pattern
- **WHEN** `morseArabicWords["في"]` is accessed
- **THEN** it SHALL return the concatenated Morse patterns for ف and ي separated by charGap: `[dot, dot, dash, dot, charGap, dot, dot, dash, dash]`

#### Scenario: Three-letter Arabic word pattern
- **WHEN** `morseArabicWords["من"]` is accessed
- **THEN** it SHALL return the concatenated Morse patterns for م and ن separated by charGap: `[dash, dash, charGap, dash, dot]`

#### Scenario: All patterns use charGap between letters
- **WHEN** any word pattern in `morseArabicWords` is inspected
- **THEN** `charGap` symbols SHALL appear between each letter's Morse symbols and SHALL NOT appear at the start or end of the pattern

### Requirement: Arabic word list ordering
The system SHALL define a `morseArabicWordsList` constant of type `List<String>` containing exactly 20 common Arabic words. Words SHALL be sorted primarily by length (shortest first) and secondarily by usage frequency (most common first within each length group).

#### Scenario: Arabic word list contains exactly 20 words
- **WHEN** `morseArabicWordsList.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Arabic word list starts with shortest words
- **WHEN** the first entries of `morseArabicWordsList` are inspected
- **THEN** they SHALL be the shortest words, ordered by frequency

#### Scenario: Every Arabic word has a pattern entry
- **WHEN** iterating through `morseArabicWordsList`
- **THEN** `morseArabicWords[word]` SHALL be non-null for every word

### Requirement: Arabic Morse utilities support
The `encodeLetter` function or a language-aware variant SHALL return the correct Morse pattern for Arabic letter characters. A language-aware decode function SHALL return the correct Arabic character for Arabic Morse patterns.

#### Scenario: Encode an Arabic letter
- **WHEN** encoding the Arabic letter 'س' (Sin)
- **THEN** the result SHALL be `[dot, dot, dot]`

#### Scenario: Decode an Arabic Morse pattern with language context
- **WHEN** decoding `[dot, dash]` in Arabic language context
- **THEN** the result SHALL be 'ا' (Alif)

#### Scenario: Decode the same pattern in English language context
- **WHEN** decoding `[dot, dash]` in English language context
- **THEN** the result SHALL be 'A'
