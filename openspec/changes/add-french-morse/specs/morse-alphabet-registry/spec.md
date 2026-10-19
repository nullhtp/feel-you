## MODIFIED Requirements

### Requirement: MorseAlphabetRegistry
The system SHALL define a `MorseAlphabetRegistry` that holds all registered `MorseAlphabet` instances and provides lookup methods. The registry SHALL be populated at module initialization time.

#### Scenario: Registry contains all registered alphabets
- **WHEN** `registry.all` is accessed
- **THEN** it SHALL return a list containing the digits, English, Arabic, Russian, Spanish and French alphabets, in that order

#### Scenario: Lookup by language
- **WHEN** `registry.forLanguage(MorseLanguage.english)` is called
- **THEN** it SHALL return the English `MorseAlphabet`

#### Scenario: Lookup universal alphabet
- **WHEN** `registry.universal` is accessed
- **THEN** it SHALL return the digits `MorseAlphabet` (where `language` is `null`)

#### Scenario: Registry returns null for unregistered language
- **WHEN** `registry.forLanguage` is called with a language that has no registered alphabet
- **THEN** it SHALL return `null`

#### Scenario: Every language has a registered alphabet
- **WHEN** `registry.forLanguage` is called with each `MorseLanguage` value on the global registry
- **THEN** it SHALL return that language's alphabet, never `null`

### Requirement: Alphabet aliases
A `MorseAlphabet` SHALL hold `aliases`: letters written in words that share another letter's pattern (Arabic أ and ى share Alif's, Russian Ё shares Е's). The Morse codec SHALL encode them, and word patterns SHALL be built with them, but they SHALL NOT be in `characters`, so decoding stays unambiguous. An alphabet without aliases SHALL have an empty map.

#### Scenario: Arabic aliases
- **WHEN** the Arabic alphabet's `aliases` are inspected
- **THEN** they SHALL map 'أ' and 'ى' to Alif's pattern `[MorseSignal.dot, MorseSignal.dash]`
- **AND** neither SHALL be a key of its `characters`

#### Scenario: Russian alias
- **WHEN** the Russian alphabet's `aliases` are inspected
- **THEN** they SHALL map 'Ё' to `[MorseSignal.dot]`
- **AND** 'Ё' SHALL NOT be a key of its `characters`

#### Scenario: Alphabets without aliases
- **WHEN** the digits, English, Spanish or French alphabet's `aliases` are inspected
- **THEN** they SHALL be empty

#### Scenario: Aliases do not decode
- **WHEN** `registry.decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.arabic)` is called
- **THEN** it SHALL return 'ا' (Alif), never an alias
