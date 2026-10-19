# language-selection Specification

## Purpose

The supported languages, the language picker and the identifier vibrations that let the user choose a language without sight.

## Requirements

### Requirement: Language picker screen
The system SHALL show a full-screen language picker on launch when no language is saved, and when Settings is entered from the home menu. It SHALL show one column per language, left to right English, العربية, Русский, Español, Français, Deutsch, with one highlighted, starting on the saved language or English when none is saved. Every touch gesture SHALL be answered with the identifier vibration of the language it leaves highlighted, so the picker works without sight.

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
- **AND** once it has finished and the post-feedback pause (0.5 s) has passed, the session SHALL be set to that language, at the digits level on 0, and the home menu SHALL replace the picker
- **AND** the menu SHALL highlight Learn after the first-launch picker, and Settings when the picker was opened from Settings

#### Scenario: Gestures are ignored while a language starts
- **WHEN** a language has been started and the home menu has not replaced the picker yet
- **THEN** further gestures, including a double shake, SHALL neither vibrate nor start another language

#### Scenario: Screen readers start a language directly
- **WHEN** a screen reader activates one of the per-language buttons
- **THEN** that language SHALL start as if it had been highlighted and held

#### Scenario: Shaking does nothing in the picker
- **WHEN** the user shakes the phone once while the picker is shown, or double-shakes in the picker shown on the first launch
- **THEN** nothing SHALL happen

#### Scenario: Double shake returns from Settings
- **WHEN** the user double-shakes in the picker opened from Settings
- **THEN** the home menu SHALL replace the picker with Settings highlighted, and the language SHALL neither change nor be saved

#### Scenario: Visual cue for a sighted helper
- **WHEN** the picker is shown
- **THEN** the highlighted column SHALL be drawn inverted and a line at the bottom SHALL read "Tap a language, then hold anywhere for 1 second to choose it"
- **AND** when the picker was opened from Settings, the line SHALL go on with "Double shake: back to the menu"

### Requirement: The chosen language is saved
Starting a language in the picker SHALL save it on the device (`SharedPreferences`, key `selected_language`) for the next launch. A launch that finds a saved language SHALL skip the picker, open the home menu and set the session to that language. Apart from the learned items (see `learned-items`), the language SHALL be the only setting saved. Saving is best effort: when the storage cannot be loaded or written, the app SHALL still run, and the picker SHALL appear again on the next launch.

#### Scenario: Next launch skips the picker
- **WHEN** the user started Arabic in the picker and the app is restarted
- **THEN** the home menu SHALL open with Learn highlighted, without the picker
- **AND** entering Learn SHALL open the lesson surface in Arabic, at the digits level on 0

#### Scenario: Picker starts on the saved language
- **WHEN** the picker is reopened from Settings after Russian was started
- **THEN** Russian SHALL be highlighted when the picker appears

#### Scenario: Unknown stored value
- **WHEN** the stored value is not the name of a `MorseLanguage`
- **THEN** it SHALL be treated as no saved language, and the picker SHALL appear

#### Scenario: Storage unavailable
- **WHEN** the platform storage cannot be loaded at launch
- **THEN** the choice SHALL be kept in memory for the current run only, and the picker SHALL appear on every launch

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
- **AND** its hint SHALL stay English and say that it chooses that language for the lessons, e.g. "Chooses Spanish for the lessons"

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
