## MODIFIED Requirements

### Requirement: Complete Russian Morse alphabet
The system SHALL define Russian Morse code patterns within a Russian `MorseAlphabet` instance (where `language` is `MorseLanguage.russian`). The `characters` map SHALL be of type `Map<String, List<MorseSignal>>` containing 32 Russian letters (А-Я, excluding Ё) mapped to their standard Russian telegraphic Morse code patterns. Ё is excluded because it shares the same Morse pattern as Е and would create an ambiguous reverse lookup.

#### Scenario: All 32 Russian letters are mapped (Ё excluded)
- **WHEN** a developer queries the Russian alphabet's `characters` map
- **THEN** it SHALL contain exactly 32 entries, one for each Russian letter excluding Ё

#### Scenario: Every letter has its standard pattern
- **WHEN** the pattern of each letter is looked up
- **THEN** it SHALL be:
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
