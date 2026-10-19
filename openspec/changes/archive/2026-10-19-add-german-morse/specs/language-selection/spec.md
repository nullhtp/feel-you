## MODIFIED Requirements

### Requirement: Language identifiers, labels and locales
Each language SHALL have, in the picker: an identifier vibration, one of its letters encoded with that language's codec rather than hardcoded as a raw signal list; a label in its own language; and the locale a screen reader speaks that label in. The identifier SHALL vibrate when its language is highlighted. No two languages SHALL share an identifier pattern.

#### Scenario: Identifier, label and locale of every language
- **WHEN** the picker shows each language
- **THEN** its identifier letter (encoded with the language's codec), label and locale SHALL be:
  - English: E, a short pulse (Morse `·`), "English", `en`
  - Arabic: ع (Ain), short, long, short, long pulses (Morse `·−·−`), "العربية", `ar`
  - Russian: Р, short, long, short pulses (Morse `·−·`), "Русский", `ru`
  - Spanish: Ñ, long, long, short, long, long pulses (Morse `−−·−−`), "Español", `es`
  - French: É, short, short, long, short, short pulses (Morse `··−··`), "Français", `fr`
  - German: Ü, short, short, long, long pulses (Morse `··−−`), "Deutsch", `de`

#### Scenario: Identifier plays on highlight change
- **WHEN** the highlighted language changes (via tap or swipe)
- **THEN** the new language's identifier pattern SHALL vibrate immediately

#### Scenario: No hardcoded patterns in language picker
- **WHEN** a developer inspects the language picker code
- **THEN** identifier patterns SHALL be obtained by encoding the identifier letters with the codec, not defined as inline constant lists

#### Scenario: Identifiers are distinct
- **WHEN** the identifier patterns of all languages are compared
- **THEN** no two SHALL be equal

#### Scenario: One button per language
- **WHEN** the language picker is shown
- **THEN** it SHALL display one button per `MorseLanguage` value, showing its label, in the enum's order

#### Scenario: Labels are spoken in their language
- **WHEN** a screen reader reads a language button
- **THEN** its label SHALL be tagged with that language's locale
- **AND** its hint SHALL stay English, e.g. "Starts Morse lessons in Spanish"

### Requirement: Supported languages
The system SHALL define a `MorseLanguage` enum with one value per taught language: `english`, `arabic`, `russian`, `spanish`, `french` and `german`, in that order. Its order is the order of the languages in the picker. A new language SHALL be added at the end and no value SHALL be renamed, because the saved language and the learned items are stored under the value's name.

#### Scenario: Languages in picker order
- **WHEN** a developer inspects `MorseLanguage.values`
- **THEN** it SHALL be `[english, arabic, russian, spanish, french, german]`

#### Scenario: Each value has a distinct identity
- **WHEN** comparing any two `MorseLanguage` values
- **THEN** they SHALL be distinct

#### Scenario: Saved data survives a new language
- **WHEN** Russian was saved, with learned items, by a version without Spanish, and the app is updated
- **THEN** the stored `selected_language` value `russian` SHALL still read as Russian
- **AND** the learned items stored under `learned_items.russian.<level name>` SHALL still be read

### Requirement: Language picker screen
The system SHALL show a full-screen language picker on launch when no language is saved, and after a double shake during a lesson. It SHALL show one column per language, left to right English, العربية, Русский, Español, Français, Deutsch, with one highlighted, starting on the saved language or English when none is saved. Every gesture SHALL be answered with the identifier vibration of the language it leaves highlighted, so the picker works without sight.

#### Scenario: Picker announces where the user is
- **WHEN** the picker appears on a device that can vibrate
- **THEN** the highlighted language's identifier SHALL vibrate once

#### Scenario: Tap highlights a language
- **WHEN** the user taps a column
- **THEN** that language SHALL be highlighted and its identifier SHALL vibrate

#### Scenario: Swipe moves the highlight
- **WHEN** the user swipes right (or left) at least 50 logical pixels anywhere on the picker
- **THEN** the next (or previous) language SHALL be highlighted, wrapping around, and its identifier SHALL vibrate

#### Scenario: Short drag replays the identifier
- **WHEN** a horizontal drag covers less than 50 logical pixels
- **THEN** the highlight SHALL stay and its identifier SHALL vibrate again

#### Scenario: Hold starts the highlighted language
- **WHEN** the user holds anywhere on the picker for 1 second
- **THEN** the highlighted language's identifier SHALL vibrate
- **AND** once it has finished and the post-feedback pause (0.5 s) has passed, the session SHALL be set to that language and the lesson surface SHALL replace the picker, at the digits level on 0

#### Scenario: Gestures are ignored while a language starts
- **WHEN** a language has been started and the lesson surface has not replaced the picker yet
- **THEN** further gestures SHALL neither vibrate nor start another language

#### Scenario: Screen readers start a language directly
- **WHEN** a screen reader activates one of the per-language buttons
- **THEN** that language SHALL start as if it had been highlighted and held

#### Scenario: Shaking does nothing in the picker
- **WHEN** the user shakes the phone while the picker is shown
- **THEN** nothing SHALL happen

#### Scenario: Visual cue for a sighted helper
- **WHEN** the picker is shown
- **THEN** the highlighted column SHALL be drawn inverted and a line at the bottom SHALL read "Tap a language, then hold anywhere for 1 second to start"
