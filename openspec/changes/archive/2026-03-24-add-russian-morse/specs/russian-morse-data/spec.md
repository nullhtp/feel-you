## ADDED Requirements

### Requirement: Complete Russian Morse alphabet
The system SHALL define Russian Morse code patterns within a Russian `MorseAlphabet` instance (where `language` is `MorseLanguage.russian`). The `characters` map SHALL be of type `Map<String, List<MorseSignal>>` containing 32 Russian letters (А-Я, excluding Ё) mapped to their standard Russian telegraphic Morse code patterns. Ё is excluded because it shares the same Morse pattern as Е and would create an ambiguous reverse lookup.

The standard Russian Morse code patterns SHALL be:
- А (A): dot-dash
- Б (B): dash-dot-dot-dot
- В (V): dot-dash-dash
- Г (G): dash-dash-dot
- Д (D): dash-dot-dot
- Е (Ye): dot
- Ж (Zh): dot-dot-dot-dash
- З (Z): dash-dash-dot-dot
- И (I): dot-dot
- Й (Y): dot-dash-dash-dash
- К (K): dash-dot-dash
- Л (L): dot-dash-dot-dot
- М (M): dash-dash
- Н (N): dash-dot
- О (O): dash-dash-dash
- П (P): dot-dash-dash-dot
- Р (R): dot-dash-dot
- С (S): dot-dot-dot
- Т (T): dash
- У (U): dot-dot-dash
- Ф (F): dot-dot-dash-dot
- Х (Kh): dot-dot-dot-dot
- Ц (Ts): dash-dot-dash-dot
- Ч (Ch): dash-dash-dash-dot
- Ш (Sh): dash-dash-dash-dash
- Щ (Shch): dash-dash-dot-dash
- Ъ (Hard sign): dash-dash-dot-dash-dash
- Ы (Y): dash-dot-dash-dash
- Ь (Soft sign): dash-dot-dot-dash
- Э (E): dot-dot-dash-dot-dot
- Ю (Yu): dot-dot-dash-dash
- Я (Ya): dot-dash-dot-dash

#### Scenario: All 32 Russian letters are mapped (Ё excluded)
- **WHEN** a developer queries the Russian alphabet's `characters` map
- **THEN** it SHALL contain exactly 32 entries, one for each Russian letter excluding Ё

#### Scenario: Patterns match standard Russian Morse code
- **WHEN** a developer looks up the pattern for 'А'
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Complex letter pattern is correct
- **WHEN** a developer looks up the pattern for 'Щ'
- **THEN** the result SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash]`

#### Scenario: Five-signal letter pattern is correct
- **WHEN** a developer looks up the pattern for 'Ъ'
- **THEN** the result SHALL be `[MorseSignal.dash, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash, MorseSignal.dash]`

#### Scenario: Map is compile-time constant
- **WHEN** the Russian alphabet's characters map is defined
- **THEN** it SHALL be declared as `const` and require no runtime initialization

### Requirement: Ordered Russian letter list
The Russian `MorseAlphabet` instance's `characterOrder` field SHALL contain 32 Russian letters in standard Russian alphabetical order (А, Б, В, Г, Д, Е, Ж, З, И, Й, К, Л, М, Н, О, П, Р, С, Т, У, Ф, Х, Ц, Ч, Ш, Щ, Ъ, Ы, Ь, Э, Ю, Я), excluding Ё. This list defines the learning sequence for the Russian letters level.

#### Scenario: Russian letters are in standard alphabetical order
- **WHEN** a developer accesses the Russian alphabet's `characterOrder`
- **THEN** the list SHALL start with 'А' and end with 'Я' with 32 letters in standard Russian alphabetical order (excluding Ё)

#### Scenario: Russian letter list length
- **WHEN** `characterOrder.length` is checked
- **THEN** it SHALL be 32

#### Scenario: Letter at index matches position
- **WHEN** accessing index 0
- **THEN** the letter SHALL be 'А'

#### Scenario: Last letter is correct
- **WHEN** accessing index 31
- **THEN** the letter SHALL be 'Я'

### Requirement: Ё alias for word composition
The Russian alphabet SHALL define an extended character map that includes 'Ё' as an alias for 'Е' (both sharing the same Morse pattern: dot). This alias map SHALL be used for word pattern composition but SHALL NOT be included in the main `characters` map to avoid polluting reverse lookups.

#### Scenario: Ё resolves to same pattern as Е
- **WHEN** the extended alias map is used to look up 'Ё'
- **THEN** the result SHALL be `[MorseSignal.dot]`

#### Scenario: Ё is not in the main characters map
- **WHEN** a developer queries the Russian alphabet's `characters` map for 'Ё'
- **THEN** the result SHALL be null

### Requirement: Russian word Morse patterns data
The Russian `MorseAlphabet` instance SHALL define `wordPatterns` of type `Map<String, List<MorseToken>>` mapping Russian word strings to their token patterns. Each word's pattern SHALL concatenate `Signal` tokens for each letter's Morse signals, separated by `CharGap()` tokens between each letter. Word pattern composition SHALL use the extended character map (including the Ё alias).

#### Scenario: Two-letter Russian word pattern
- **WHEN** the Russian alphabet's `wordPatterns["ДА"]` is accessed
- **THEN** it SHALL return the concatenated token pattern for Д and А separated by CharGap

#### Scenario: Three-letter Russian word pattern
- **WHEN** the Russian alphabet's `wordPatterns["НЕТ"]` is accessed
- **THEN** it SHALL return the concatenated token pattern for Н, Е, and Т separated by CharGap tokens

#### Scenario: All patterns use CharGap between letters
- **WHEN** any word pattern in the Russian alphabet's `wordPatterns` is inspected
- **THEN** `CharGap` tokens SHALL appear between each letter's signal tokens and SHALL NOT appear at the start or end of the pattern

### Requirement: Russian word list ordering
The Russian `MorseAlphabet` instance's `wordList` SHALL contain exactly 20 common Russian words sorted primarily by length (shortest first) and secondarily by usage frequency. Words SHALL be chosen for practical daily communication needs of deaf-blind users, using uppercase Cyrillic letters.

#### Scenario: Russian word list contains exactly 20 words
- **WHEN** `wordList!.length` is checked
- **THEN** it SHALL be 20

#### Scenario: Russian word list starts with shortest words
- **WHEN** the first entries of `wordList` are inspected
- **THEN** they SHALL be the shortest words (2-letter), ordered by frequency

#### Scenario: Every Russian word has a pattern entry
- **WHEN** iterating through `wordList`
- **THEN** `wordPatterns![word]` SHALL be non-null for every word

#### Scenario: Words are in uppercase Cyrillic
- **WHEN** any word in `wordList` is inspected
- **THEN** it SHALL consist entirely of uppercase Cyrillic letters

### Requirement: Russian Morse utilities support
The `encodeLetter` function SHALL return the correct Morse signal pattern for Russian letter characters when called with `MorseLanguage.russian`. The `decodePattern` function SHALL return the correct Russian character for Russian Morse patterns when called with `MorseLanguage.russian`.

#### Scenario: Encode a Russian letter
- **WHEN** `encodeLetter('С', MorseLanguage.russian)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Decode a Russian Morse pattern with language context
- **WHEN** `decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.russian)` is called
- **THEN** the result SHALL be 'А'

#### Scenario: Decode the same pattern in English language context
- **WHEN** `decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.english)` is called
- **THEN** the result SHALL be 'A'

#### Scenario: Encode with uppercase input
- **WHEN** `encodeLetter('а', MorseLanguage.russian)` is called (lowercase)
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dash]` (same as uppercase 'А')
