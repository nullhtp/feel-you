## ADDED Requirements

### Requirement: Language-aware letter encoding
The system SHALL provide an `encodeLetter(String letter, MorseLanguage language)` function that encodes a single character into its Morse signal pattern using the appropriate alphabet for the given language. The function SHALL check both the universal alphabet (digits) and the language-specific alphabet. It SHALL return `null` if the character is not found.

#### Scenario: Encode uppercase English letter
- **WHEN** `encodeLetter('S', MorseLanguage.english)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Encode lowercase English letter
- **WHEN** `encodeLetter('s', MorseLanguage.english)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Encode digit with any language
- **WHEN** `encodeLetter('5', MorseLanguage.arabic)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Encode Arabic letter
- **WHEN** `encodeLetter('س', MorseLanguage.arabic)` is called
- **THEN** the result SHALL be `[MorseSignal.dot, MorseSignal.dot, MorseSignal.dot]`

#### Scenario: Encode Arabic letter with English language returns null
- **WHEN** `encodeLetter('س', MorseLanguage.english)` is called
- **THEN** the result SHALL be `null`

#### Scenario: Encode empty string
- **WHEN** `encodeLetter('', MorseLanguage.english)` is called
- **THEN** the result SHALL be `null`

### Requirement: Language-aware pattern decoding
The system SHALL provide a `decodePattern(List<MorseSignal> pattern, MorseLanguage language)` function that decodes a signal pattern back to the corresponding character using the appropriate alphabet. It SHALL return `null` if the pattern does not match any character.

#### Scenario: Decode English pattern
- **WHEN** `decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.english)` is called
- **THEN** the result SHALL be 'A'

#### Scenario: Decode Arabic pattern
- **WHEN** `decodePattern([MorseSignal.dot, MorseSignal.dash], MorseLanguage.arabic)` is called
- **THEN** the result SHALL be 'ا'

#### Scenario: Decode digit pattern
- **WHEN** `decodePattern([MorseSignal.dash, MorseSignal.dash, MorseSignal.dash, MorseSignal.dash, MorseSignal.dash], MorseLanguage.english)` is called
- **THEN** the result SHALL be '0'

#### Scenario: Decode invalid pattern returns null
- **WHEN** `decodePattern([MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot, MorseSignal.dot], MorseLanguage.english)` is called (maps to digit '5', not 5 dots for a letter — actually this is digit 5)
- **THEN** the result SHALL be '5'

#### Scenario: Decode empty list
- **WHEN** `decodePattern([], MorseLanguage.english)` is called
- **THEN** the result SHALL be `null`

### Requirement: No language-unaware encode/decode
The system SHALL NOT provide `encodeLetter` or `decodePattern` functions without a `MorseLanguage` parameter. The former language-unaware `encodeLetter()` and `decodePattern()`/`decodePatternForLanguage()` functions SHALL be removed.

#### Scenario: No single-argument encodeLetter exists
- **WHEN** a developer attempts to call `encodeLetter` with only a character argument (no language)
- **THEN** the Dart type system SHALL reject the code at compile time

#### Scenario: No decodePatternForLanguage exists
- **WHEN** a developer searches the codebase for `decodePatternForLanguage`
- **THEN** no such function SHALL exist
