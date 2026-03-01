## MODIFIED Requirements

### Requirement: Language picker vibration identifiers
Each language option SHALL have a unique vibration identifier pattern that plays when that option is highlighted. The identifier patterns SHALL be looked up from the `MorseAlphabetRegistry` using `encodeLetter` rather than hardcoded as raw signal lists.

#### Scenario: English language identifier
- **WHEN** English is the highlighted option
- **THEN** the system SHALL vibrate the Morse pattern for the letter "E" obtained via `encodeLetter('E', MorseLanguage.english)` (which is `[MorseSignal.dot]`)

#### Scenario: Arabic language identifier
- **WHEN** Arabic is the highlighted option
- **THEN** the system SHALL vibrate the Morse pattern for the letter "ع" (Ain) obtained via `encodeLetter('ع', MorseLanguage.arabic)` (which is `[MorseSignal.dot, MorseSignal.dash, MorseSignal.dash]`)

#### Scenario: Identifier plays on highlight change
- **WHEN** the highlighted language changes (via tap)
- **THEN** the new language's identifier pattern SHALL vibrate immediately

#### Scenario: No hardcoded patterns in language picker
- **WHEN** a developer inspects the language picker code
- **THEN** identifier patterns SHALL be obtained from the registry, not defined as inline constant lists
