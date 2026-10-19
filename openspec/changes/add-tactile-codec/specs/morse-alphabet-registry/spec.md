## ADDED Requirements

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
- **WHEN** the digits or English alphabet's `aliases` are inspected
- **THEN** they SHALL be empty

#### Scenario: Aliases do not decode
- **WHEN** `registry.decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.arabic)` is called
- **THEN** it SHALL return 'ا' (Alif), never an alias
