# language-selection Specification

## Purpose

The supported languages, the language picker and the identifier vibrations that let the user choose a language without sight.

## Requirements

### Requirement: Language picker vibration identifiers
Each language option SHALL have a unique vibration identifier pattern that plays when that option is highlighted. The identifier patterns SHALL be looked up from the `MorseAlphabetRegistry` using `encodeLetter` rather than hardcoded as raw signal lists.

#### Scenario: English language identifier
- **WHEN** English is the highlighted option
- **THEN** the system SHALL vibrate the Morse pattern for the letter "E" obtained via `encodeLetter('E', MorseLanguage.english)` (which is `[MorseSignal.dot]`)

#### Scenario: Arabic language identifier
- **WHEN** Arabic is the highlighted option
- **THEN** the system SHALL vibrate the Morse pattern for the letter "ع" (Ain) obtained via `encodeLetter('ع', MorseLanguage.arabic)` (which is `[MorseSignal.dot, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash]`)

#### Scenario: Russian language identifier
- **WHEN** Russian is the highlighted option
- **THEN** the system SHALL vibrate the Morse pattern for the letter "Р" obtained via `encodeLetter('Р', MorseLanguage.russian)` (which is `[MorseSignal.dot, MorseSignal.dash, MorseSignal.dot]`)

#### Scenario: Identifier plays on highlight change
- **WHEN** the highlighted language changes (via tap or swipe)
- **THEN** the new language's identifier pattern SHALL vibrate immediately

#### Scenario: No hardcoded patterns in language picker
- **WHEN** a developer inspects the language picker code
- **THEN** identifier patterns SHALL be obtained from the registry, not defined as inline constant lists

#### Scenario: Russian language label
- **WHEN** the language picker displays the Russian option
- **THEN** the button label SHALL be "Русский"

#### Scenario: Three language buttons displayed
- **WHEN** the language picker is shown
- **THEN** it SHALL display three buttons: English, Arabic, and Russian

### Requirement: MorseLanguage enum
The system SHALL define a `MorseLanguage` enum with the values `english`, `arabic` and `russian`, in that order. It identifies which Morse alphabet the user is learning, and its order is the order of the languages in the picker.

#### Scenario: Enum has exactly three values
- **WHEN** a developer inspects `MorseLanguage.values`
- **THEN** it SHALL be `[english, arabic, russian]`

#### Scenario: Each value has a distinct identity
- **WHEN** comparing any two `MorseLanguage` values
- **THEN** they SHALL be distinct

### Requirement: Language picker screen
The system SHALL show a full-screen language picker on launch when no language is saved, and after a double shake during a lesson. It SHALL show one column per language, left to right English, العربية, Русский, with one highlighted, starting on the saved language or English when none is saved. Every gesture SHALL be answered with the identifier vibration of the language it leaves highlighted, so the picker works without sight.

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

### Requirement: The chosen language is saved
Starting a language in the picker SHALL save it on the device (`SharedPreferences`, key `selected_language`) for the next launch. A launch that finds a saved language SHALL skip the picker and start the session in that language. Apart from the learned items (see `learned-items`), the language SHALL be the only setting saved. Saving is best effort: when the storage cannot be loaded or written, the app SHALL still run, and the picker SHALL appear again on the next launch.

#### Scenario: Next launch skips the picker
- **WHEN** the user started Arabic in the picker and the app is restarted
- **THEN** the lesson surface SHALL open in Arabic, at the digits level on 0, without the picker

#### Scenario: Picker starts on the saved language
- **WHEN** the picker is reopened with a double shake after Russian was started
- **THEN** Russian SHALL be highlighted when the picker appears

#### Scenario: Unknown stored value
- **WHEN** the stored value is not the name of a `MorseLanguage`
- **THEN** it SHALL be treated as no saved language, and the picker SHALL appear

#### Scenario: Storage unavailable
- **WHEN** the platform storage cannot be loaded at launch
- **THEN** the choice SHALL be kept in memory for the current run only, and the picker SHALL appear on every launch
