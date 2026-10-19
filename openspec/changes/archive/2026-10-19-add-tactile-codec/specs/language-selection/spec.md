## MODIFIED Requirements

### Requirement: Language picker vibration identifiers
Each language option SHALL have a unique vibration identifier pattern that plays when that option is highlighted. The identifier SHALL be a letter of the language, encoded with that language's codec rather than hardcoded as a raw signal list.

#### Scenario: English language identifier
- **WHEN** English is the highlighted option
- **THEN** the system SHALL vibrate the letter "E" encoded with the English codec (a short pulse, Morse `·`)

#### Scenario: Arabic language identifier
- **WHEN** Arabic is the highlighted option
- **THEN** the system SHALL vibrate the letter "ع" (Ain) encoded with the Arabic codec (short, long, short, long pulses, Morse `·−·−`)

#### Scenario: Russian language identifier
- **WHEN** Russian is the highlighted option
- **THEN** the system SHALL vibrate the letter "Р" encoded with the Russian codec (short, long, short pulses, Morse `·−·`)

#### Scenario: Identifier plays on highlight change
- **WHEN** the highlighted language changes (via tap or swipe)
- **THEN** the new language's identifier pattern SHALL vibrate immediately

#### Scenario: No hardcoded patterns in language picker
- **WHEN** a developer inspects the language picker code
- **THEN** identifier patterns SHALL be obtained by encoding the identifier letters with the codec, not defined as inline constant lists

#### Scenario: Russian language label
- **WHEN** the language picker displays the Russian option
- **THEN** the button label SHALL be "Русский"

#### Scenario: Three language buttons displayed
- **WHEN** the language picker is shown
- **THEN** it SHALL display three buttons: English, Arabic, and Russian
