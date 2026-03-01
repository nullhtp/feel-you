## ADDED Requirements

### Requirement: MorseLanguage enum
The system SHALL define a `MorseLanguage` enum with values `english` and `arabic`. This enum identifies which Morse code language/alphabet the user is learning.

#### Scenario: Enum has exactly two values
- **WHEN** a developer inspects the `MorseLanguage` enum
- **THEN** it SHALL contain exactly `english` and `arabic` as values

#### Scenario: Each value has a distinct identity
- **WHEN** comparing `MorseLanguage.english` to `MorseLanguage.arabic`
- **THEN** they SHALL be distinct values

### Requirement: Language picker screen
The system SHALL present a language picker screen on app start before the main learning surface. The picker SHALL allow the user to select a language using only touch gestures and vibration feedback.

#### Scenario: Picker shown on app launch
- **WHEN** the app is launched
- **THEN** the language picker screen SHALL be displayed before the learning surface

#### Scenario: Language options are presented via vibration
- **WHEN** the language picker is active
- **THEN** the system SHALL vibrate a distinct Morse identifier pattern for the currently highlighted language (e.g., the Morse pattern for "E" when English is highlighted, the Morse pattern for "ع" when Arabic is highlighted)

#### Scenario: User cycles between languages
- **WHEN** the user taps on the language picker screen
- **THEN** the highlighted language SHALL cycle to the next option and its identifier pattern SHALL vibrate

#### Scenario: User confirms language selection
- **WHEN** the user performs a swipe-right gesture on the language picker
- **THEN** the selected language SHALL be confirmed and the app SHALL navigate to the main learning surface with that language active

### Requirement: Language picker is non-persistent
The language selection SHALL NOT be persisted to disk or any external storage. The picker SHALL always appear on app start.

#### Scenario: Picker appears on every app start
- **WHEN** the app is restarted after a previous session
- **THEN** the language picker SHALL appear again regardless of previous selection

### Requirement: Language picker vibration identifiers
Each language option SHALL have a unique vibration identifier pattern that plays when that option is highlighted.

#### Scenario: English language identifier
- **WHEN** English is the highlighted option
- **THEN** the system SHALL vibrate the Morse pattern for the letter "E" (dot)

#### Scenario: Arabic language identifier
- **WHEN** Arabic is the highlighted option
- **THEN** the system SHALL vibrate the Morse pattern for the letter "ع" (Ain) (dot-dash-dash)

#### Scenario: Identifier plays on highlight change
- **WHEN** the highlighted language changes (via tap)
- **THEN** the new language's identifier pattern SHALL vibrate immediately
